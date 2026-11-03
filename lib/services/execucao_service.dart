import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/execucao_treino.dart';
import 'database_events.dart';
import 'notificacao_service.dart';

class ExecucaoService {
  final DatabaseHelper databaseHelper;

  ExecucaoService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Saves one exercise, its feedback, and the workout completion atomically.
  Future<bool> registrarExercicioComFeedback({
    required int treinoId,
    required int treinoExercicioId,
    required int alunoId,
    required int series,
    required double carga,
    required int repeticoes,
    required String nivel,
    required String? comentario,
  }) async {
    final db = await databaseHelper.database;
    final concluiuTreino = await db.transaction((txn) async {
      final treinos = await txn.query(
        'treino',
        columns: ['aluno_id', 'professor_id', 'nome', 'concluido_em'],
        where: 'id = ?',
        whereArgs: [treinoId],
        limit: 1,
      );
      if (treinos.isEmpty || treinos.first['aluno_id'] != alunoId) {
        throw StateError('Este treino não pertence ao aluno conectado.');
      }
      final treino = treinos.first;
      if (treino['concluido_em'] != null) {
        throw StateError('Este treino já foi concluído.');
      }

      final exercicios = await txn.query(
        'treino_exercicio',
        columns: ['id'],
        where: 'id = ? AND treino_id = ?',
        whereArgs: [treinoExercicioId, treinoId],
        limit: 1,
      );
      if (exercicios.isEmpty) {
        throw StateError('O exercício não pertence a este treino.');
      }

      final execucaoId = await txn.insert('execucao_exercicio', {
        'treino_exercicio_id': treinoExercicioId,
        'data_execucao': DateTime.now().toIso8601String(),
        'series_realizadas': series,
        'carga': carga,
        'repeticoes': repeticoes,
      });
      await txn.insert('feedback', {
        'execucao_id': execucaoId,
        'nivel': nivel,
        'comentario': comentario,
      });

      final totalExercicios =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM treino_exercicio WHERE treino_id = ?',
              [treinoId],
            ),
          ) ??
          0;
      final exerciciosComFeedback =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              '''
          SELECT COUNT(DISTINCT te.id)
          FROM treino_exercicio te
          JOIN execucao_exercicio ex ON ex.treino_exercicio_id = te.id
          JOIN feedback f ON f.execucao_id = ex.id
          WHERE te.treino_id = ?
          ''',
              [treinoId],
            ),
          ) ??
          0;

      if (totalExercicios == 0 || exerciciosComFeedback < totalExercicios) {
        return false;
      }

      final concluidoEm = DateTime.now().toIso8601String();
      final atualizados = await txn.update(
        'treino',
        {'concluido_em': concluidoEm},
        where: 'id = ? AND concluido_em IS NULL',
        whereArgs: [treinoId],
      );
      if (atualizados == 0) return false;

      final alunos = await txn.query(
        'usuario',
        columns: ['nome'],
        where: 'id = ?',
        whereArgs: [alunoId],
        limit: 1,
      );
      final nomeAluno = alunos.isEmpty
          ? 'O aluno'
          : alunos.first['nome'] as String;
      final nomeTreino = treino['nome'] as String;
      await NotificacaoService.inserir(
        txn,
        destinatarioId: treino['professor_id'] as int,
        tipo: 'TREINO_CONCLUIDO',
        titulo: 'Treino concluído',
        mensagem: '$nomeAluno concluiu o treino “$nomeTreino”.',
        treinoId: treinoId,
      );
      return true;
    });

    DatabaseEvents.changed();
    return concluiuTreino;
  }

  /// Exercises with submitted feedback count as complete and can be resumed.
  Future<Set<int>> exerciciosConcluidos(int treinoId) async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT te.id
      FROM treino_exercicio te
      JOIN execucao_exercicio ex ON ex.treino_exercicio_id = te.id
      JOIN feedback f ON f.execucao_id = ex.id
      WHERE te.treino_id = ?
      ''',
      [treinoId],
    );
    return rows.map((row) => row['id'] as int).toSet();
  }

  Future<List<ExecucaoTreino>> historico(int treinoId) async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT ex.*, e.nome AS exercicio_nome
      FROM execucao_exercicio ex
      JOIN treino_exercicio te ON te.id = ex.treino_exercicio_id
      JOIN exercicio e ON e.id = te.exercicio_id
      WHERE te.treino_id = ?
      ORDER BY ex.data_execucao DESC
      LIMIT 50
      ''',
      [treinoId],
    );
    return rows.map(ExecucaoTreino.fromMap).toList();
  }

  Future<Map<String, Object?>?> relatorio(int treinoId) async {
    final db = await databaseHelper.database;
    final treinos = await db.rawQuery(
      '''
      SELECT t.id, t.nome, t.professor_id, t.concluido_em,
             a.nome AS aluno_nome,
             p.nome AS professor_nome
      FROM treino t
      JOIN usuario a ON a.id = t.aluno_id
      JOIN usuario p ON p.id = t.professor_id
      WHERE t.id = ?
      ''',
      [treinoId],
    );
    if (treinos.isEmpty) return null;

    final exercicios = await db.rawQuery(
      '''
      SELECT te.id AS treino_exercicio_id, te.ordem, e.nome AS exercicio_nome,
             ex.data_execucao, ex.series_realizadas, ex.repeticoes, ex.carga,
             f.nivel, f.comentario
      FROM treino_exercicio te
      JOIN exercicio e ON e.id = te.exercicio_id
      LEFT JOIN execucao_exercicio ex ON ex.id = (
        SELECT ex2.id FROM execucao_exercicio ex2
        JOIN feedback f2 ON f2.execucao_id = ex2.id
        WHERE ex2.treino_exercicio_id = te.id
        ORDER BY ex2.data_execucao DESC, ex2.id DESC LIMIT 1
      )
      LEFT JOIN feedback f ON f.execucao_id = ex.id
      WHERE te.treino_id = ?
      ORDER BY te.ordem ASC
      ''',
      [treinoId],
    );
    return {'treino': treinos.first, 'exercicios': exercicios};
  }
}
