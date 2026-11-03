import '../database/database_helper.dart';
import '../models/exercicios.dart';
import 'database_events.dart';

class ExercicioService {
  final DatabaseHelper databaseHelper;

  ExercicioService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<int> cadastrar(Exercicio exercicio) async {
    final db = await databaseHelper.database;
    final id = await db.insert('exercicio', exercicio.toMap());
    DatabaseEvents.changed();
    return id;
  }

  Future<List<Exercicio>> listar() async {
    final db = await databaseHelper.database;

    final resultado = await db.query('exercicio', orderBy: 'nome ASC');

    return resultado.map((map) => Exercicio.fromMap(map)).toList();
  }

  Future<List<Exercicio>> pesquisar(String termo, {String? grupo}) async {
    final db = await databaseHelper.database;
    final rows = await db.query(
      'exercicio',
      orderBy: 'grupo_muscular, nome',
    );
    return filtrar(rows.map(Exercicio.fromMap).toList(), termo, grupo: grupo);
  }

  List<Exercicio> filtrar(
    List<Exercicio> exercicios,
    String termo, {
    String? grupo,
  }) {
    final consulta = _normalizar(termo);
    final palavras = consulta.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final grupoSelecionado = grupo == null ? null : _normalizar(grupo);
    return exercicios.where((exercicio) {
      if (grupoSelecionado != null &&
          _normalizar(exercicio.grupoMuscular) != grupoSelecionado) {
        return false;
      }
      if (consulta.isEmpty) return true;
      final campos = _normalizar(
        '${exercicio.nome} ${exercicio.grupoMuscular} ${exercicio.descricao}',
      );
      return palavras.every(campos.contains);
    }).toList();
  }

  String _normalizar(String valor) {
    const caracteres = {
      0x00e1: 'a', 0x00e0: 'a', 0x00e2: 'a', 0x00e3: 'a', 0x00e4: 'a',
      0x00e9: 'e', 0x00e8: 'e', 0x00ea: 'e', 0x00eb: 'e',
      0x00ed: 'i', 0x00ec: 'i', 0x00ee: 'i', 0x00ef: 'i',
      0x00f3: 'o', 0x00f2: 'o', 0x00f4: 'o', 0x00f5: 'o', 0x00f6: 'o',
      0x00fa: 'u', 0x00f9: 'u', 0x00fb: 'u', 0x00fc: 'u',
      0x00e7: 'c',
    };
    return String.fromCharCodes(
      valor.trim().toLowerCase().runes.map((caractere) {
        if (caractere >= 0x0300 && caractere <= 0x036f) return -1;
        final substituto = caracteres[caractere];
        if (substituto != null) return substituto.codeUnitAt(0);
        return caractere;
      }).where((caractere) => caractere >= 0),
    );
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

    final alteradas = await db.update(
      'exercicio',
      exercicio.toMap(),
      where: 'id = ?',
      whereArgs: [exercicio.id],
    );
    if (alteradas > 0) DatabaseEvents.changed();
    return alteradas;
  }

  Future<int> excluir(int id) async {
    final db = await databaseHelper.database;

    final excluidos = await db.delete(
      'exercicio',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (excluidos > 0) DatabaseEvents.changed();
    return excluidos;
  }
}
