import '../database/database_helper.dart';
import '../models/exercicios.dart';
import '../models/treino.dart';
import '../models/treino_exercicios.dart';

class TreinoService {
  final DatabaseHelper databaseHelper;

  TreinoService({
    DatabaseHelper? databaseHelper,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // Cadastra o treino e os exercÃ­cios dele de uma vez.
  // Se algum insert falhar, nada Ã© salvo (transaction).
  Future<int> cadastrar(
    Treino treino,
    List<TreinoExercicio> itens,
  ) async {
    final db = await databaseHelper.database;

    return await db.transaction((txn) async {
      final treinoId = await txn.insert('treino', treino.toMap());

      for (final item in itens) {
        final mapa = item.toMap();
        mapa.remove('id');
        mapa['treino_id'] = treinoId;
        await txn.insert('treino_exercicio', mapa);
      }

      return treinoId;
    });
  }

  Future<List<Treino>> listar() async {
    final db = await databaseHelper.database;

    final resultado = await db.query(
      'treino',
      orderBy: 'validade ASC',
    );

    return resultado.map((map) => Treino.fromMap(map)).toList();
  }

  Future<List<Treino>> listarPorAluno(int alunoId) async {
    final db = await databaseHelper.database;

    final resultado = await db.query(
      'treino',
      where: 'aluno_id = ?',
      whereArgs: [alunoId],
      orderBy: 'validade ASC',
    );

    return resultado.map((map) => Treino.fromMap(map)).toList();
  }

  // Quantidade de exercÃ­cios de cada treino: {treinoId: quantidade}.
  // Uma Ãºnica consulta para a lista toda.
  Future<Map<int, int>> contagemPorTreino() async {
    final db = await databaseHelper.database;

    final resultado = await db.rawQuery('''
      SELECT treino_id, COUNT(*) AS total
      FROM treino_exercicio
      GROUP BY treino_id
    ''');

    return {
      for (final linha in resultado)
        linha['treino_id'] as int: linha['total'] as int,
    };
  }

  // ExercÃ­cios de um treino, jÃ¡ com os dados do exercÃ­cio (JOIN).
  Future<List<TreinoExercicio>> listarExercicios(int treinoId) async {
    final db = await databaseHelper.database;

    final resultado = await db.rawQuery('''
      SELECT
        te.*,
        e.nome AS e_nome,
        e.grupo_muscular AS e_grupo_muscular,
        e.descricao AS e_descricao,
        e.imagem_url AS e_imagem_url
      FROM treino_exercicio te
      INNER JOIN exercicio e ON e.id = te.exercicio_id
      WHERE te.treino_id = ?
      ORDER BY te.ordem ASC
    ''', [treinoId]);

    return resultado.map((map) {
      final base = TreinoExercicio.fromMap(map);

      return TreinoExercicio(
        id: base.id,
        treinoId: base.treinoId,
        exercicioId: base.exercicioId,
        ordem: base.ordem,
        series: base.series,
        repeticoes: base.repeticoes,
        carga: base.carga,
        descansoSegundos: base.descansoSegundos,
        observacoes: base.observacoes,
        exercicio: Exercicio(
          id: base.exercicioId,
          nome: map['e_nome'] as String,
          grupoMuscular: map['e_grupo_muscular'] as String,
          descricao: map['e_descricao'] as String,
          imagemUrl: map['e_imagem_url'] as String?,
        ),
      );
    }).toList();
  }

  // Atualiza o treino e a lista de exercÃ­cios.
  // Itens com id sÃ£o atualizados, itens sem id sÃ£o inseridos e os que
  // saÃ­ram da lista sÃ£o removidos. Assim o histÃ³rico de execuÃ§Ãµes dos
  // exercÃ­cios que continuam no treino Ã© preservado.
  Future<void> editar(
    Treino treino,
    List<TreinoExercicio> itens,
  ) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'treino',
        treino.toMap(),
        where: 'id = ?',
        whereArgs: [treino.id],
      );

      final idsMantidos =
          itens.where((i) => i.id != null).map((i) => i.id!).toList();

      if (idsMantidos.isEmpty) {
        await txn.delete(
          'treino_exercicio',
          where: 'treino_id = ?',
          whereArgs: [treino.id],
        );
      } else {
        final marcadores = List.filled(idsMantidos.length, '?').join(',');

        await txn.delete(
          'treino_exercicio',
          where: 'treino_id = ? AND id NOT IN ($marcadores)',
          whereArgs: [treino.id, ...idsMantidos],
        );
      }

      for (final item in itens) {
        final mapa = item.toMap();
        mapa['treino_id'] = treino.id;

        if (item.id == null) {
          mapa.remove('id');
          await txn.insert('treino_exercicio', mapa);
        } else {
          await txn.update(
            'treino_exercicio',
            mapa,
            where: 'id = ?',
            whereArgs: [item.id],
          );
        }
      }
    });
  }

  // Os exercÃ­cios, execuÃ§Ãµes e feedbacks do treino sÃ£o apagados junto
  // (ON DELETE CASCADE).
  Future<int> excluir(int id) async {
    final db = await databaseHelper.database;

    return await db.delete(
      'treino',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
