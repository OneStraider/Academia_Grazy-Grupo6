import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/anamnese.dart';
import '../models/avaliacao_fisica.dart';

class AvaliacaoService {
  final DatabaseHelper databaseHelper;
  AvaliacaoService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;
  Future<int> salvar(AvaliacaoFisica avaliacao, Anamnese? anamnese) async {
    final db = await databaseHelper.database;
    return db.transaction((tx) async {
      final dados = avaliacao.toMap()..remove('id');
      final id = await tx.insert('avaliacao_fisica', dados);
      if (anamnese != null) {
        await tx.insert(
          'anamnese',
          anamnese.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return id;
    });
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
