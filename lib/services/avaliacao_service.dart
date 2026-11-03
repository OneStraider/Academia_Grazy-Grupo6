import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/anamnese.dart';
import '../models/avaliacao_fisica.dart';
import 'database_events.dart';
import 'notificacao_service.dart';

class AvaliacaoService {
  final DatabaseHelper databaseHelper;
  AvaliacaoService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;
  Future<int> salvar(AvaliacaoFisica avaliacao, Anamnese? anamnese) async {
    final db = await databaseHelper.database;
    final id = await db.transaction((tx) async {
      final dados = avaliacao.toMap()..remove('id');
      final id = await tx.insert('avaliacao_fisica', dados);
      if (anamnese != null) {
        await tx.insert(
          'anamnese',
          anamnese.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      final professorRows = await tx.query(
        'usuario',
        columns: ['nome'],
        where: 'id = ?',
        whereArgs: [avaliacao.professorId],
        limit: 1,
      );
      final professor = professorRows.isEmpty
          ? 'Seu professor'
          : professorRows.first['nome'] as String;
      await NotificacaoService.inserir(
        tx,
        destinatarioId: avaliacao.alunoId!,
        tipo: 'AVALIACAO_REALIZADA',
        titulo: 'Avaliação física realizada',
        mensagem:
            '$professor registrou sua avaliação física. Acesse Evolução para conferir seus resultados.',
        avaliacaoId: id,
      );
      return id;
    });
    DatabaseEvents.changed();
    return id;
  }

  Future<List<AvaliacaoFisica>> listar(int alunoId) async {
    final db = await databaseHelper.database;
    final rows = await db.query(
      'avaliacao_fisica',
      where: 'aluno_id = ?',
      whereArgs: [alunoId],
      orderBy: 'data DESC',
    );
    return rows.map(AvaliacaoFisica.fromMap).toList();
  }

  Future<Anamnese?> buscarAnamnese(int alunoId) async {
    final db = await databaseHelper.database;
    final rows = await db.query(
      'anamnese',
      where: 'aluno_id = ?',
      whereArgs: [alunoId],
      limit: 1,
    );
    return rows.isEmpty ? null : Anamnese.fromMap(rows.first);
  }
}
