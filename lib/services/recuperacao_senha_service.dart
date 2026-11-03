import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente para a API responsável por enviar e validar códigos de recuperação.
/// Credenciais do provedor de e-mail devem ficar no servidor, nunca no APK.
class RecuperacaoSenhaService {
  static const _urlConfigurada = String.fromEnvironment('API_BASE_URL');
  final String _baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  RecuperacaoSenhaService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? _urlConfigurada;

  bool get configurado => _baseUrl.trim().isNotEmpty;

  Future<void> cadastrarAluno({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final resposta = await _post('/auth/register', {
      'name': nome.trim(),
      'email': email.trim().toLowerCase(),
      'password': senha,
    });
    if (resposta.statusCode == 409) {
      throw const RecuperacaoSenhaException(
        'Este e-mail já possui uma conta no serviço. Tente entrar ou recuperar a senha.',
      );
    }
    if (resposta.statusCode != 201) {
      throw const RecuperacaoSenhaException(
        'Não foi possível criar a conta no serviço da academia.',
      );
    }
  }

  Future<void> solicitarCodigo(String email) async {
    final resposta = await _post('/auth/password-reset/request', {
      'email': email.trim().toLowerCase(),
    });
    if (resposta.statusCode != 200 && resposta.statusCode != 202) {
      throw RecuperacaoSenhaException(
        'Não foi possível solicitar o código. Tente novamente mais tarde.',
      );
    }
  }

  Future<void> confirmarCodigoENovaSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final resposta = await _post('/auth/password-reset/confirm', {
      'email': email.trim().toLowerCase(),
      'code': codigo.trim(),
      'newPassword': novaSenha,
    });
    if (resposta.statusCode == 400 || resposta.statusCode == 422) {
      throw RecuperacaoSenhaException(
        'Código inválido ou expirado. Solicite outro código.',
      );
    }
    if (resposta.statusCode != 200 && resposta.statusCode != 204) {
      throw RecuperacaoSenhaException(
        'Não foi possível alterar a senha. Tente novamente mais tarde.',
      );
    }
  }

  Future<http.Response> _post(String caminho, Map<String, Object> corpo) async {
    if (_baseUrl.trim().isEmpty) {
      throw const RecuperacaoSenhaException(
        'A recuperação por e-mail ainda não está configurada. Peça ajuda à academia.',
      );
    }
    final base = Uri.tryParse(_baseUrl.trim());
    if (base == null || !base.hasAuthority || !base.hasScheme) {
      throw const RecuperacaoSenhaException(
        'O endereço do serviço de recuperação está inválido.',
      );
    }
    if (base.scheme != 'https' &&
        base.host != 'localhost' &&
        base.host != '127.0.0.1') {
      throw const RecuperacaoSenhaException(
        'O serviço de recuperação precisa usar uma conexão HTTPS segura.',
      );
    }
    try {
      return await _client
          .post(
            base.resolve(caminho),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(seconds: 20));
    } on RecuperacaoSenhaException {
      rethrow;
    } catch (_) {
      throw const RecuperacaoSenhaException(
        'Não foi possível conectar ao serviço de recuperação.',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class RecuperacaoSenhaException implements Exception {
  final String mensagem;
  const RecuperacaoSenhaException(this.mensagem);

  @override
  String toString() => mensagem;
}
