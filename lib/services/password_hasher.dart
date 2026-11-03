import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static const int _iteracoes = 120000;
  static const String _prefixo = 'pbkdf2_sha256';

  static Future<String> hash(String senha) async {
    final salt = Uint8List(16);
    final random = Random.secure();
    for (var i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }
    final resultado = await Isolate.run(() => _pbkdf2(senha, salt, _iteracoes));
    return '${_prefixo}\$$_iteracoes\$${base64UrlEncode(salt)}\$${base64UrlEncode(resultado)}';
  }

  static Future<bool> verificar(String senha, String armazenado) async {
    final partes = armazenado.split(r'$');
    if (partes.length != 4 || partes.first != _prefixo) return false;

    final iteracoes = int.tryParse(partes[1]);
    if (iteracoes == null || iteracoes < 10000 || iteracoes > 1000000) {
      return false;
    }

    try {
      final salt = base64Url.decode(base64Url.normalize(partes[2]));
      final esperado = base64Url.decode(base64Url.normalize(partes[3]));
      final atual = await Isolate.run(() => _pbkdf2(senha, salt, iteracoes));
      if (atual.length != esperado.length) return false;
      var diferenca = 0;
      for (var i = 0; i < atual.length; i++) {
        diferenca |= atual[i] ^ esperado[i];
      }
      return diferenca == 0;
    } on FormatException {
      return false;
    }
  }

  static Uint8List _pbkdf2(String senha, List<int> salt, int iteracoes) {
    final hmac = Hmac(sha256, utf8.encode(senha));
    final entrada = Uint8List(salt.length + 4)..setRange(0, salt.length, salt);
    entrada[salt.length + 3] = 1;

    var u = hmac.convert(entrada).bytes;
    final resultado = Uint8List.fromList(u);
    for (var i = 1; i < iteracoes; i++) {
      u = hmac.convert(u).bytes;
      for (var byte = 0; byte < resultado.length; byte++) {
        resultado[byte] ^= u[byte];
      }
    }
    return resultado;
  }
}
