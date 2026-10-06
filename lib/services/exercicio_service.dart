import '../database/database_helper.dart';
import '../models/exercicio.dart';

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
