import '../database/database_helper.dart';

class ExecucaoService {
  final DatabaseHelper databaseHelper;

  ExecucaoService({
    DatabaseHelper? databaseHelper,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // REQ-06: grava a execução de um exercício. Retorna o id da execução.
  Future<int> registrarExecucao({
    required int treinoExercicioId,
    required int series,
    required double carga,
    required int repeticoes,
  }) async {
    final db = await databaseHelper.database;

    return await db.insert('execucao_exercicio', {
      'treino_exercicio_id': treinoExercicioId,
      'data_execucao': DateTime.now().toIso8601String(),
      'series_realizadas': series,
      'carga': carga,
      'repeticoes': repeticoes,
    });
  }

  // REQ-07: grava o feedback de uma execução.
  // nivel: MUITO_FACIL | BOM | MUITO_DIFICIL
  Future<int> registrarFeedback({
    required int execucaoId,
    required String nivel,
    String? comentario,
  }) async {
    final db = await databaseHelper.database;

    return await db.insert('feedback', {
      'execucao_id': execucaoId,
      'nivel': nivel,
      'comentario': comentario,
    });
  }

  // Ids dos treino_exercicio que já foram feitos HOJE neste treino.
  // É isso que deixa o exercício verde na tela de detalhes.
  Future<Set<int>> concluidosHoje(int treinoId) async {
    final db = await databaseHelper.database;

    final agora = DateTime.now();
    final dia = '${agora.year}-'
        '${agora.month.toString().padLeft(2, '0')}-'
        '${agora.day.toString().padLeft(2, '0')}';

    final resultado = await db.rawQuery('''
      SELECT DISTINCT ex.treino_exercicio_id AS id
      FROM execucao_exercicio ex
      INNER JOIN treino_exercicio te ON te.id = ex.treino_exercicio_id
      WHERE te.treino_id = ? AND ex.data_execucao LIKE ?
    ''', [treinoId, '$dia%']);

    return resultado.map((linha) => linha['id'] as int).toSet();
  }
}