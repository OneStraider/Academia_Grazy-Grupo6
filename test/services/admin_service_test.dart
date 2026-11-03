import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:academia_grazy_grupo6/database/database_helper.dart';
import 'package:academia_grazy_grupo6/models/usuario.dart';
import 'package:academia_grazy_grupo6/services/admin_service.dart';
import 'package:academia_grazy_grupo6/services/usuario_service.dart';

void main() {
  late Database db;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''CREATE TABLE usuario (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      senha_hash TEXT NOT NULL,
      tipo TEXT NOT NULL,
      ativo INTEGER NOT NULL DEFAULT 1,
      criado_em TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE treino (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      aluno_id INTEGER NOT NULL,
      professor_id INTEGER NOT NULL,
      criado_em TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE avaliacao_fisica (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      aluno_id INTEGER NOT NULL,
      data TEXT NOT NULL
    )''');
  });

  tearDown(() async {
    UsuarioService.usuarioLogado = null;
    await db.close();
  });

  AdminService service() => AdminService(databaseProvider: () async => db);

  Usuario admin() => Usuario(
    id: 99,
    nome: 'Admin',
    email: 'admin@teste.com',
    senhaHash: 'hash',
    tipo: 'ADMIN',
  );

  test(
    'periodos ano, mês, semana e dia geram intervalo e anterior corretos',
    () {
      final ano = AdminPeriodo.calcular(
        AdminGranularidade.ano,
        DateTime(2026, 6, 9),
      );
      expect(ano.inicio, DateTime(2026));
      expect(ano.fim, DateTime(2027));
      expect(ano.inicioAnterior, DateTime(2025));

      final mes = AdminPeriodo.calcular(
        AdminGranularidade.mes,
        DateTime(2026, 3, 9),
      );
      expect(mes.inicio, DateTime(2026, 3));
      expect(mes.fim, DateTime(2026, 4));
      expect(mes.inicioAnterior, DateTime(2026, 2));

      final semana = AdminPeriodo.calcular(
        AdminGranularidade.semana,
        DateTime(2026, 3, 4),
      );
      expect(semana.inicio, DateTime(2026, 3, 2));
      expect(semana.fim, DateTime(2026, 3, 9));
      expect(semana.inicioAnterior, DateTime(2026, 2, 23));

      final dia = AdminPeriodo.calcular(
        AdminGranularidade.dia,
        DateTime(2026, 3, 4, 19),
      );
      expect(dia.inicio, DateTime(2026, 3, 4));
      expect(dia.fim, DateTime(2026, 3, 5));
      expect(dia.inicioAnterior, DateTime(2026, 3, 3));
    },
  );

  test('painel filtra registros reais e compara com o mês anterior', () async {
    UsuarioService.usuarioLogado = admin();
    await db.insert('usuario', {
      'nome': 'Aluna atual',
      'email': 'atual@teste.com',
      'senha_hash': 'hash',
      'tipo': 'ALUNO',
      'criado_em': '2026-03-12T10:00:00.000',
    });
    await db.insert('usuario', {
      'nome': 'Aluna anterior',
      'email': 'anterior@teste.com',
      'senha_hash': 'hash',
      'tipo': 'ALUNO',
      'criado_em': '2026-02-12T10:00:00.000',
    });
    await db.insert('treino', {
      'aluno_id': 1,
      'professor_id': 2,
      'criado_em': '2026-03-13T10:00:00.000',
    });
    await db.insert('treino', {
      'aluno_id': 1,
      'professor_id': 2,
      'criado_em': '2026-02-13T10:00:00.000',
    });
    await db.insert('avaliacao_fisica', {
      'aluno_id': 1,
      'data': '2026-03-14T10:00:00.000',
    });
    await db.insert('avaliacao_fisica', {
      'aluno_id': 1,
      'data': '2026-02-14T10:00:00.000',
    });

    final resultado = await service().carregarMetricas(
      AdminPeriodo.calcular(AdminGranularidade.mes, DateTime(2026, 3, 20)),
    );
    expect(resultado.treinos, 1);
    expect(resultado.alunos, 1);
    expect(resultado.avaliacoes, 1);
    expect(resultado.treinosAnteriores, 1);
    expect(resultado.alunosAnteriores, 1);
    expect(resultado.avaliacoesAnteriores, 1);
  });

  test(
    'admin cria, busca e desativa pessoas sem remover o histórico',
    () async {
      UsuarioService.usuarioLogado = admin();
      final id = await service().salvarPessoa(
        nome: 'Maria Silva',
        email: 'maria@teste.com',
        tipo: 'ALUNO',
        senha: 'senha123',
      );
      expect(
        (await service().listarPessoas(
          tipo: 'ALUNO',
          busca: 'maria',
        )).single.id,
        id,
      );
      await service().definirAtivo(id, false);
      final inativo = (await service().listarPessoas(tipo: 'ALUNO')).single;
      expect(inativo.ativo, isFalse);
      expect((await db.query('usuario')).length, 1);
      await service().definirAtivo(id, true);
      expect((await service().detalhes(id)).usuario.ativo, isTrue);
    },
  );

  test(
    'usuário sem perfil ADMIN é bloqueado antes de consultar o banco',
    () async {
      UsuarioService.usuarioLogado = Usuario(
        id: 1,
        nome: 'Aluno',
        email: 'aluno@teste.com',
        senhaHash: 'hash',
        tipo: 'ALUNO',
      );
      var bancoConsultado = false;
      final protegido = AdminService(
        databaseProvider: () async {
          bancoConsultado = true;
          return db;
        },
      );

      await expectLater(
        protegido.listarPessoas(tipo: 'ALUNO'),
        throwsA(isA<AcessoAdminNegado>()),
      );
      expect(bancoConsultado, isFalse);
    },
  );

  test(
    'migração da versão 8 preserva registros e adiciona campos administrativos',
    () async {
      await db.execute('DROP TABLE usuario');
      await db.execute('DROP TABLE treino');
      await db.execute('''CREATE TABLE usuario (
      id INTEGER PRIMARY KEY, nome TEXT NOT NULL, email TEXT NOT NULL,
      senha_hash TEXT NOT NULL, tipo TEXT NOT NULL
    )''');
      await db.execute('''CREATE TABLE treino (
      id INTEGER PRIMARY KEY, aluno_id INTEGER, professor_id INTEGER,
      nome TEXT, validade TEXT, status TEXT, observacoes TEXT, concluido_em TEXT
    )''');
      await db.insert('usuario', {
        'id': 7,
        'nome': 'Legado',
        'email': 'legado@teste.com',
        'senha_hash': 'hash',
        'tipo': 'ALUNO',
      });
      await db.insert('treino', {
        'id': 8,
        'aluno_id': 7,
        'professor_id': 9,
        'nome': 'Treino legado',
        'validade': '2026-12-01',
        'status': 'ATIVO',
      });

      await DatabaseHelper.migrarEsquemaAdministrativo(db, 8, 9);

      final pessoa = (await db.query('usuario')).single;
      final treino = (await db.query('treino')).single;
      expect(pessoa['ativo'], 1);
      expect(pessoa['criado_em'], isNotNull);
      expect(treino['id'], 8);
      expect(treino['criado_em'], isNotNull);
    },
  );
}
