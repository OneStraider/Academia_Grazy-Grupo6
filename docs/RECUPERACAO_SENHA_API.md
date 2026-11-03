# Serviço de cadastro e recuperação de senha

O serviço inicial está em `backend/password_api.py` e usa apenas a biblioteca
padrão do Python. Ele armazena contas e códigos em um SQLite separado, aplica
limites simples de chamadas e envia os códigos via SMTP com TLS. O app mantém
uma cópia local das contas para continuar funcionando no modo de demonstração.
O envio seguro exige uma conta de e-mail SMTP; suas credenciais devem ficar nas
variáveis de ambiente do servidor, nunca no APK nem no Git.

Configure o servidor em PowerShell (os valores abaixo são exemplos; use os
dados do seu provedor de e-mail):

```powershell
$env:SMTP_HOST = "smtp.exemplo.com"
$env:SMTP_PORT = "587"
$env:SMTP_USERNAME = "conta de envio"
$env:SMTP_PASSWORD = "senha de aplicativo do provedor"
$env:SMTP_FROM = "Academia Grazy <nao-responda@exemplo.com>"
$env:GRAZY_RESET_PEPPER = "gere-um-segredo-aleatorio-com-ao-menos-32-caracteres"
python backend/password_api.py
```

O servidor escuta em `127.0.0.1:8080` por padrão. Para usar pelo celular, publique-o
atrás de HTTPS e configure o app com o endereço acessível ao aparelho. Não exponha
o servidor diretamente em HTTP na internet.

Configure a URL raiz da API ao executar ou gerar o app:

```powershell
flutter run -d ZF523TJGMV --dart-define=API_BASE_URL=https://api.exemplo.com
```

Com a URL configurada, o cadastro público é registrado primeiro na API e depois
no SQLite local. Sem `API_BASE_URL`, o cadastro continua local para testes e a
recuperação por e-mail informa que o serviço não está configurado.

## Criar conta

`POST /auth/register`

```json
{"name":"Nome do aluno","email":"aluno@exemplo.com","password":"senha-segura"}
```

Retorne `201 Created` ou `409 Conflict` se o e-mail já estiver cadastrado.
O serviço público só cria contas de aluno. Perfis de professor/administração
devem ser concedidos pela equipe, nunca enviados pelo cliente.

## Solicitar código

`POST /auth/password-reset/request`

```json
{"email":"aluno@exemplo.com"}
```

O servidor retorna `202 Accepted` tanto para e-mails cadastrados quanto não
cadastrados, com uma resposta genérica. Para contas existentes, gera código
aleatório de uso único, armazena apenas o hash, limita tentativas e validade e
envia o código ao endereço cadastrado.

## Confirmar código e atualizar senha

`POST /auth/password-reset/confirm`

```json
{
  "email":"aluno@exemplo.com",
  "code":"123456",
  "newPassword":"uma-senha-segura"
}
```

O servidor retorna `200 OK` ao concluir e `400` para código inválido/expirado.
Ele invalida o código após o uso e guarda a nova senha com PBKDF2. O app, após
confirmação bem-sucedida, atualiza também o hash da conta correspondente no
SQLite local.

O servidor já está implementado, mas ainda precisa ser iniciado e configurado
com SMTP, `GRAZY_RESET_PEPPER` e uma URL HTTPS acessível ao celular. Sem isso,
nenhum e-mail será enviado e a recuperação informa que o serviço está
indisponível.
