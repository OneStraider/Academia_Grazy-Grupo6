import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:academia_grazy_grupo6/database/database_tables.dart';
import 'package:academia_grazy_grupo6/database/demo_training_seeder.dart';
import 'package:academia_grazy_grupo6/services/admin_service.dart';
import 'package:academia_grazy_grupo6/services/usuario_service.dart';
import 'package:academia_grazy_grupo6/models/usuario.dart';

void main() {
  late Database db;
  final referencia = DateTime(2026, 11, 15, 12);

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(DatabaseTables.usuario);
    await db.execute(DatabaseTables.exercicio);
    await db.execute(DatabaseTables.treino);
    await db.execute(DatabaseTables.treinoExercicio);
    await db.execute('''CREATE TABLE preferencia_app (
      chave TEXT PRIMARY KEY, valor TEXT NOT NULL DEFAULT ''
    )''');
    await db.insert('usuario', {
      'nome': 'Admin',
      'email': 'admin@teste.com',
      'senha_hash': 'hash',
      'tipo': 'ADMIN',
    });
    for (final email in DemoTrainingSeeder.professores) {
      await db.insert('usuario', {
        'nome': 'Professor ${email.split('@').first}',
        'email': email,
        'senha_hash': 'hash',
        'tipo': 'PROFESSOR',
      });
    }
    for (final email in DemoTrainingSeeder.alunos) {
      await db.insert('usuario', {
        'nome': 'Aluno ${email.split('@').first}',
        'email': email,
        'senha_hash': 'hash',
        'tipo': 'ALUNO',
      });
    }
    for (var i = 0; i < 12; i++) {
      await db.insert('exercicio', {
        'nome': 'Exercício $i',
        'grupo_muscular': 'Geral',
        'descricao': 'Exercício de teste',
      });
    }
  });

  tearDown(() async {
    UsuarioService.usuarioLogado = null;
    await db.close();
  });

  test(
    'seed é identificado, coerente e não duplica ao iniciar de novo',
    () async {
      final seeder = DemoTrainingSeeder();
      await seeder.seed(db, referencia: referencia);
      final quantidadeInicial = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM treino'),
      );
      await seeder.seed(db, referencia: referencia);

      expect(quantidadeInicial, 481);
      expect(
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM treino')),
        quantidadeInicial,
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM treino WHERE observacoes = ?',
            [DemoTrainingSeeder.observacao],
          ),
        ),
        quantidadeInicial,
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM preferencia_app WHERE chave = ?',
            [DemoTrainingSeeder.marker],
          ),
        ),
        1,
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM treino WHERE concluido_em IS NOT NULL',
          ),
        ),
        0,
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM treino_exercicio'),
        ),
        quantidadeInicial! * 4,
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM treino WHERE status != 'INATIVO'",
          ),
        ),
        0,
      );
    },
  );

  test('séries semana, mês, ano e filtro de professor refletem as linhas salvas', () async {
    await DemoTrainingSeeder().seed(db, referencia: referencia);
    UsuarioService.usuarioLogado = Usuario(
      id: 1,
      nome: 'Admin',
      email: 'admin@teste.com',
      senhaHash: 'hash',
      tipo: 'ADMIN',
    );
    final admin = AdminService(databaseProvider: () async => db);
    final professorRows = await db.query(
      'usuario',
      columns: ['id', 'nome'],
      where: 'tipo = ?',
      whereArgs: ['PROFESSOR'],
    );
    final weekly = await admin.carregarSerie(
      periodo: AdminGranularidade.semana,
      referencia: referencia,
      metrica: 'treinos',
    );
    final monthly = await admin.carregarSerie(
      periodo: AdminGranularidade.mes,
      referencia: referencia,
      metrica: 'treinos',
    );
    final yearly = await admin.carregarSerie(
      periodo: AdminGranularidade.ano,
      referencia: referencia,
      metrica: 'treinos',
    );

    expect(weekly, hasLength(7));
    expect(monthly, hasLength(5));
    expect(yearly, hasLength(12));
    expect(weekly.first.valores.keys.toSet(), hasLength(10));
    expect(yearly.first.valores.keys.toSet(), hasLength(10));
    expect(
      weekly
          .map((ponto) => ponto.valores.values.fold<int>(0, (a, b) => a + b))
          .toList(),
      [1, 3, 2, 4, 1, 3, 2],
    );

    final weekPeriod = AdminPeriodo.calcular(
      AdminGranularidade.semana,
      referencia,
    );
    final monthPeriod = AdminPeriodo.calcular(
      AdminGranularidade.mes,
      referencia,
    );
    final yearPeriod = AdminPeriodo.calcular(
      AdminGranularidade.ano,
      referencia,
    );
    for (final (serie, periodo) in [
      (weekly, weekPeriod),
      (monthly, monthPeriod),
      (yearly, yearPeriod),
    ]) {
      final total = serie.fold<int>(
        0,
        (soma, ponto) =>
            soma + ponto.valores.values.fold<int>(0, (a, b) => a + b),
      );
      final banco = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM treino WHERE criado_em >= ? AND criado_em < ?',
          [periodo.inicio.toIso8601String(), periodo.fim.toIso8601String()],
        ),
      );
      expect(total, banco);
    }

    final professor = professorRows.first;
    final professorId = (professor['id'] as num).toInt();
    final somenteProfessor = await admin.carregarSerie(
      periodo: AdminGranularidade.ano,
      referencia: referencia,
      metrica: 'treinos',
      professorId: professorId,
    );
    expect(somenteProfessor.first.valores.keys, [professor['nome']]);
    final totalProfessor = somenteProfessor.fold<int>(
      0,
      (soma, ponto) => soma + ponto.valores.values.single,
    );
    final bancoProfessor = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM treino WHERE professor_id = ? AND criado_em >= ? AND criado_em < ?',
        [
          professorId,
          yearPeriod.inicio.toIso8601String(),
          yearPeriod.fim.toIso8601String(),
        ],
      ),
    );
    expect(totalProfessor, bancoProfessor);
    expect(
      yearly
          .map((ponto) => ponto.valores.values.fold<int>(0, (a, b) => a + b))
          .toSet()
          .length,
      greaterThan(3),
    );
  });
}
