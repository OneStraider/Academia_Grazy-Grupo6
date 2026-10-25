import '../database/database_helper.dart';
import '../models/exercicios.dart';

class ExercicioService {
  final DatabaseHelper databaseHelper;

  ExercicioService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<int> cadastrar(Exercicio exercicio) async {
    final db = await databaseHelper.database;

    return await db.insert('exercicio', exercicio.toMap());
  }

  Future<List<Exercicio>> listar() async {
    final db = await databaseHelper.database;

    final resultado = await db.query('exercicio', orderBy: 'nome ASC');

    return resultado.map((map) => Exercicio.fromMap(map)).toList();
  }

  Future<List<Exercicio>> pesquisar(String termo, {String? grupo}) async {
    final db = await databaseHelper.database;
    final filtros = <String>[];
    final args = <Object?>[];
    if (termo.trim().isNotEmpty) {
      filtros.add('nome LIKE ?');
      args.add('%${termo.trim()}%');
    }
    if (grupo != null && grupo.isNotEmpty) {
      filtros.add('grupo_muscular = ?');
      args.add(grupo);
    }
    final rows = await db.query(
      'exercicio',
      where: filtros.isEmpty ? null : filtros.join(' AND '),
      whereArgs: filtros.isEmpty ? null : args,
      orderBy: 'grupo_muscular, nome',
    );
    return rows.map(Exercicio.fromMap).toList();
  }

  Future<List<String>> grupos() async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT grupo_muscular FROM exercicio ORDER BY grupo_muscular',
    );
    return rows.map((r) => r['grupo_muscular'] as String).toList();
  }

  Future<int> editar(Exercicio exercicio) async {
    final db = await databaseHelper.database;

    return await db.update(
      'exercicio',
      exercicio.toMap(),
      where: 'id = ?',
      whereArgs: [exercicio.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await databaseHelper.database;

    return await db.delete('exercicio', where: 'id = ?', whereArgs: [id]);
  }
}
