"""Small standard-library API for account registration and password reset.

Run behind HTTPS in production. Mail credentials and the token pepper come from
environment variables; never commit a real .env file or deploy this server over
plain HTTP on a public network.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import re
import secrets
import smtplib
import sqlite3
import time
import threading
from contextlib import contextmanager
from email.message import EmailMessage
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent
DATABASE = Path(os.environ.get("GRAZY_AUTH_DB", ROOT / "accounts.sqlite3"))
HOST = os.environ.get("GRAZY_AUTH_HOST", "127.0.0.1")
PORT = int(os.environ.get("GRAZY_AUTH_PORT", "8080"))
CODE_TTL_SECONDS = 10 * 60
RESEND_WAIT_SECONDS = 60
MAX_CODE_ATTEMPTS = 5
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
RATE_WINDOWS: dict[str, list[float]] = {}
RATE_LOCK = threading.Lock()


def connect() -> sqlite3.Connection:
    db = sqlite3.connect(DATABASE, timeout=10)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode = WAL")
    return db


@contextmanager
def database():
    db = connect()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def initialize() -> None:
    DATABASE.parent.mkdir(parents=True, exist_ok=True)
    with database() as db:
        db.executescript(
            """
            CREATE TABLE IF NOT EXISTS account (
                email TEXT PRIMARY KEY COLLATE NOCASE,
                name TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                created_at INTEGER NOT NULL
            );
            CREATE TABLE IF NOT EXISTS password_reset (
                email TEXT PRIMARY KEY COLLATE NOCASE,
                code_hash TEXT NOT NULL,
                expires_at INTEGER NOT NULL,
                attempts INTEGER NOT NULL DEFAULT 0,
                requested_at INTEGER NOT NULL
            );
            """
        )


def password_hash(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 600_000)
    return f"pbkdf2_sha256$600000${salt.hex()}${digest.hex()}"


def code_hash(email: str, code: str) -> str:
    pepper = os.environ.get("GRAZY_RESET_PEPPER", "")
    if len(pepper) < 32:
        raise RuntimeError("GRAZY_RESET_PEPPER must contain at least 32 characters")
    return hmac.new(
        pepper.encode(), f"{email.lower()}:{code}".encode(), hashlib.sha256
    ).hexdigest()


def send_code(email: str, code: str) -> None:
    host = os.environ.get("SMTP_HOST", "")
    username = os.environ.get("SMTP_USERNAME", "")
    password = os.environ.get("SMTP_PASSWORD", "")
    sender = os.environ.get("SMTP_FROM", username)
    if not all((host, username, password, sender)):
        raise RuntimeError("SMTP_HOST/USERNAME/PASSWORD/FROM are not configured")

    message = EmailMessage()
    message["Subject"] = "Código para recuperar sua senha | Academia Grazy"
    message["From"] = sender
    message["To"] = email
    message.set_content(
        f"Seu código de recuperação da Academia Grazy é: {code}\n\n"
        "Ele expira em 10 minutos e só pode ser usado uma vez. "
        "Se você não solicitou a troca, ignore este e-mail."
    )
    port = int(os.environ.get("SMTP_PORT", "587"))
    with smtplib.SMTP(host, port, timeout=15) as smtp:
        smtp.starttls()
        smtp.login(username, password)
        smtp.send_message(message)


class Handler(BaseHTTPRequestHandler):
    server_version = "GrazyAuth/1.0"

    def log_message(self, fmt: str, *args: object) -> None:
        # Avoid logging request bodies, passwords, codes, or full email addresses.
        print(f"{self.client_address[0]} - {fmt % args}")

    def _json(self, status: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        origin = os.environ.get("GRAZY_CORS_ORIGIN", "")
        if origin:
            self.send_header("Access-Control-Allow-Origin", origin)
        self.end_headers()
        self.wfile.write(body)

    def _body(self) -> dict[str, object]:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0 or length > 16_384:
            raise ValueError("invalid body size")
        raw = self.rfile.read(length)
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError("expected JSON object")
        return value

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        origin = os.environ.get("GRAZY_CORS_ORIGIN", "")
        if origin:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        limits = {
            "/auth/register": (10, 60 * 60),
            "/auth/password-reset/request": (5, 60),
            "/auth/password-reset/confirm": (20, 60),
        }
        limit = limits.get(path)
        if limit and not self._within_rate_limit(path, *limit):
            self._json(429, {"error": "rate_limited"})
            return
        try:
            payload = self._body()
            if path == "/auth/register":
                self._register(payload)
            elif path == "/auth/password-reset/request":
                self._request_code(payload)
            elif path == "/auth/password-reset/confirm":
                self._confirm_code(payload)
            else:
                self._json(404, {"error": "not_found"})
        except (ValueError, json.JSONDecodeError):
            self._json(400, {"error": "invalid_request"})
        except RuntimeError:
            self._json(503, {"error": "service_not_configured"})

    def _within_rate_limit(self, path: str, max_requests: int, seconds: int) -> bool:
        now = time.monotonic()
        key = f"{self.client_address[0]}:{path}"
        with RATE_LOCK:
            recent = [
                sent
                for sent in RATE_WINDOWS.get(key, [])
                if now - sent < seconds
            ]
            if len(recent) >= max_requests:
                RATE_WINDOWS[key] = recent
                return False
            recent.append(now)
            RATE_WINDOWS[key] = recent
            if len(RATE_WINDOWS) > 10_000:
                for old_key in list(RATE_WINDOWS):
                    if not RATE_WINDOWS[old_key] or now - RATE_WINDOWS[old_key][-1] >= 3600:
                        RATE_WINDOWS.pop(old_key, None)
            return True

    def _register(self, payload: dict[str, object]) -> None:
        name = str(payload.get("name", "")).strip()
        email = str(payload.get("email", "")).strip().lower()
        password = str(payload.get("password", ""))
        if (
            not 3 <= len(name) <= 100
            or len(email) > 254
            or not EMAIL_RE.fullmatch(email)
            or not 8 <= len(password) <= 128
        ):
            self._json(422, {"error": "invalid_fields"})
            return
        try:
            with database() as db:
                db.execute(
                    "INSERT INTO account(email,name,password_hash,created_at) VALUES(?,?,?,?)",
                    (email, name, password_hash(password), int(time.time())),
                )
        except sqlite3.IntegrityError:
            self._json(409, {"error": "email_already_registered"})
            return
        self._json(201, {"status": "created"})

    def _request_code(self, payload: dict[str, object]) -> None:
        email = str(payload.get("email", "")).strip().lower()
        if not EMAIL_RE.fullmatch(email):
            self._json(202, {"status": "accepted"})
            return
        now = int(time.time())
        generic = {"status": "accepted"}
        with database() as db:
            account = db.execute(
                "SELECT email FROM account WHERE email = ? COLLATE NOCASE", (email,)
            ).fetchone()
            previous = db.execute(
                "SELECT requested_at FROM password_reset WHERE email = ? COLLATE NOCASE",
                (email,),
            ).fetchone()
            if not account:
                self._json(202, generic)
                return
            if previous and now - previous["requested_at"] < RESEND_WAIT_SECONDS:
                self._json(202, generic)
                return
            code = f"{secrets.randbelow(1_000_000):06d}"
            db.execute(
                """INSERT INTO password_reset(email,code_hash,expires_at,attempts,requested_at)
                   VALUES(?,?,?,?,?) ON CONFLICT(email) DO UPDATE SET
                   code_hash=excluded.code_hash, expires_at=excluded.expires_at,
                   attempts=0, requested_at=excluded.requested_at""",
                (email, code_hash(email, code), now + CODE_TTL_SECONDS, 0, now),
            )
        try:
            send_code(email, code)
        except Exception as exc:
            print(f"Email delivery failed ({type(exc).__name__}); details withheld")
            with database() as db:
                db.execute("DELETE FROM password_reset WHERE email = ?", (email,))
        self._json(202, generic)

    def _confirm_code(self, payload: dict[str, object]) -> None:
        email = str(payload.get("email", "")).strip().lower()
        code = str(payload.get("code", "")).strip()
        password = str(payload.get("newPassword", ""))
        if (
            not EMAIL_RE.fullmatch(email)
            or len(code) != 6
            or not 8 <= len(password) <= 128
        ):
            self._json(422, {"error": "invalid_fields"})
            return
        now = int(time.time())
        with database() as db:
            row = db.execute(
                "SELECT * FROM password_reset WHERE email = ? COLLATE NOCASE", (email,)
            ).fetchone()
            if not row or row["expires_at"] < now or row["attempts"] >= MAX_CODE_ATTEMPTS:
                db.execute("DELETE FROM password_reset WHERE email = ?", (email,))
                self._json(400, {"error": "invalid_or_expired_code"})
                return
            candidate = code_hash(email, code)
            if not hmac.compare_digest(candidate, row["code_hash"]):
                db.execute(
                    "UPDATE password_reset SET attempts=attempts+1 WHERE email=?", (email,)
                )
                self._json(400, {"error": "invalid_or_expired_code"})
                return
            db.execute(
                "UPDATE account SET password_hash=? WHERE email=? COLLATE NOCASE",
                (password_hash(password), email),
            )
            db.execute("DELETE FROM password_reset WHERE email=?", (email,))
        self._json(200, {"status": "password_updated"})


if __name__ == "__main__":
    initialize()
    print(f"Academia Grazy account API listening on {HOST}:{PORT}")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
