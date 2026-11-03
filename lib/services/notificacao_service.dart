import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/notificacao.dart';
import 'database_events.dart';

class NotificacaoService {
  final DatabaseHelper databaseHelper;

  NotificacaoService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static Future<int> inserir(
    DatabaseExecutor executor, {
    required int destinatarioId,
    required String tipo,
    required String titulo,
    required String mensagem,
    int? treinoId,
    int? avaliacaoId,
  }) => executor.insert('notificacao', {
    'destinatario_id': destinatarioId,
    'tipo': tipo,
    'titulo': titulo,
    'mensagem': mensagem,
    'treino_id': treinoId,
    'avaliacao_id': avaliacaoId,
    'criado_em': DateTime.now().toIso8601String(),
  });

  Future<List<Notificacao>> listar(int destinatarioId) async {
    final db = await databaseHelper.database;
    final rows = await db.query(
      'notificacao',
      where: 'destinatario_id = ?',
      whereArgs: [destinatarioId],
      orderBy: 'criado_em DESC, id DESC',
    );
    return rows.map(Notificacao.fromMap).toList();
  }

  Future<int> contarNaoLidas(int destinatarioId) async {
    final db = await databaseHelper.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM notificacao '
            'WHERE destinatario_id = ? AND lida_em IS NULL',
            [destinatarioId],
          ),
        ) ??
        0;
  }

  Future<void> marcarComoLida(int id, int destinatarioId) async {
    final db = await databaseHelper.database;
    final agora = DateTime.now().toIso8601String();
    final alteradas = await db.update(
      'notificacao',
      {'lida_em': agora},
      where: 'id = ? AND destinatario_id = ? AND lida_em IS NULL',
      whereArgs: [id, destinatarioId],
    );
    if (alteradas > 0) DatabaseEvents.changed();
  }
}
