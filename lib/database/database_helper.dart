import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'database_tables.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'academia_grazy.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: (db, version) async => await _onCreate(db),
      onUpgrade: (db, oldVersion, newVersion) {
        // Migrações futuras aqui
      },
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Ativa verificação de chaves estrangeiras
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db) async {
    // Executa os 10 CREATE TABLE em ordem
    for (String createTableSql in DatabaseTables.todas) {
      await db.execute(createTableSql);
    }

    // Popula com dados iniciais
    await _popularDadosIniciais(db);
  }

  Future<void> _popularDadosIniciais(Database db) async {
    // IMPORTANTE: Senhas aqui são em TEXTO POR ENQUANTO.
    // Quando UsuarioService.gerarHash() estiver pronto,
    // substitua cada uma pelo hash SHA256.
    // Exemplo: 'admin123' → '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f1979c67f'

    // 1. INSERIR USUÁRIOS (5)
    await db.insert('usuario', {
      'id': 1,
      'nome': 'Admin do Sistema',
      'email': 'admin@fitapp.com',
      'senha_hash':
          'TODO_HASH_admin123', // UsuarioService.gerarHash('admin123')
      'tipo': 'ADMIN',
    });

    await db.insert('usuario', {
      'id': 2,
      'nome': 'Carlos Eduardo',
      'email': 'carlos.prof@fitapp.com',
      'senha_hash': 'TODO_HASH_prof123', // UsuarioService.gerarHash('prof123')
      'tipo': 'PROFESSOR',
    });

    await db.insert('usuario', {
      'id': 3,
      'nome': 'Ana Paula',
      'email': 'ana.prof@fitapp.com',
      'senha_hash': 'TODO_HASH_prof123', // UsuarioService.gerarHash('prof123')
      'tipo': 'PROFESSOR',
    });

    await db.insert('usuario', {
      'id': 4,
      'nome': 'Guilherme Silva',
      'email': 'guilherme.aluno@fitapp.com',
      'senha_hash':
          'TODO_HASH_aluno123', // UsuarioService.gerarHash('aluno123')
      'tipo': 'ALUNO',
    });

    await db.insert('usuario', {
      'id': 5,
      'nome': 'Maria Oliveira',
      'email': 'maria.aluno@fitapp.com',
      'senha_hash':
          'TODO_HASH_aluno123', // UsuarioService.gerarHash('aluno123')
      'tipo': 'ALUNO',
    });

    await db.insert('usuario', {
      'id': 6,
      'nome': 'João Santos',
      'email': 'joao.aluno@fitapp.com',
      'senha_hash':
          'TODO_HASH_aluno123', // UsuarioService.gerarHash('aluno123')
      'tipo': 'ALUNO',
    });

    // 2. INSERIR EXERCÍCIOS (12)
    await db.insert('exercicio', {
      'id': 1,
      'nome': 'Supino Reto',
      'grupo_muscular': 'Peito',
      'descricao': 'Deitado no banco horizontal, empurre a barra verticalmente até a extensão dos braços.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 2,
      'nome': 'Crucifixo no Banco',
      'grupo_muscular': 'Peito',
      'descricao': 'Deitado no banco, abra os braços mantendo cotovelos levemente flexionados e aduza no topo.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 3,
      'nome': 'Supino Inclinado',
      'grupo_muscular': 'Peito',
      'descricao': 'Exercício executado em banco inclinado (30° a 45°) focando a porção superior do peitoral.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 4,
      'nome': 'Puxada Frontal',
      'grupo_muscular': 'Costas',
      'descricao': 'Sentado no pulley, puxe a barra em direção ao peitoral superior com pegada aberta.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 5,
      'nome': 'Remada Curvada',
      'grupo_muscular': 'Costas',
      'descricao': 'Tronco inclinado à frente, puxe a barra em direção ao abdômen mantendo a coluna neutra.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 6,
      'nome': 'Remada Unilateral',
      'grupo_muscular': 'Costas',
      'descricao': 'Com apoio no banco (serrote), puxe o halter lateralmente em direção ao quadril.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 7,
      'nome': 'Agachamento Livre',
      'grupo_muscular': 'Pernas',
      'descricao': 'Mantenha pés na largura dos ombros e flexione joelhos e quadril descendo até 90°.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 8,
      'nome': 'Leg Press 45°',
      'grupo_muscular': 'Pernas',
      'descricao': 'Posicione os pés na plataforma e empurre a carga estendendo os joelhos sem travá-los.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 9,
      'nome': 'Afundo',
      'grupo_muscular': 'Pernas',
      'descricao': 'Dê um passo à frente e flexione ambos os joelhos até formar um ângulo de 90°.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 10,
      'nome': 'Desenvolvimento',
      'grupo_muscular': 'Ombros',
      'descricao': 'Empurre os halteres ou barra acima da cabeça até a extensão dos braços.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 11,
      'nome': 'Elevação Lateral',
      'grupo_muscular': 'Ombros',
      'descricao': 'Eleve os halteres lateralmente até a altura dos ombros mantendo cotovelos semiflexionados.',
      'imagem_url': null,
    });

    await db.insert('exercicio', {
      'id': 12,
      'nome': 'Rosca Direta',
      'grupo_muscular': 'Bíceps',
      'descricao': 'Em pé, flexione os cotovelos trazendo a barra em direção aos ombros.',
      'imagem_url': null,
    });

    // 3. INSERIR HORÁRIOS DE AULA (7)
    // Datas: 05/10/2026 a 08/10/2026 (próximos dias)
    await db.insert('horario_aula', {
      'id': 1,
      'modalidade': 'Musculação (Orientada)',
      'data': '2026-10-05',
      'horario': '07:00',
      'professor_id': 2, // Carlos Eduardo
      'vagas_totais': 15,
    });

    await db.insert('horario_aula', {
      'id': 2,
      'modalidade': 'Treino Funcional',
      'data': '2026-10-05',
      'horario': '18:30',
      'professor_id': 3, // Ana Paula
      'vagas_totais': 10,
    });

    await db.insert('horario_aula', {
      'id': 3,
      'modalidade': 'Cross Training',
      'data': '2026-10-06',
      'horario': '08:00',
      'professor_id': 2, // Carlos Eduardo
      'vagas_totais': 12,
    });

    await db.insert('horario_aula', {
      'id': 4,
      'modalidade': 'Musculação (Orientada)',
      'data': '2026-10-06',
      'horario': '19:00',
      'professor_id': 3, // Ana Paula
      'vagas_totais': 15,
    });

    await db.insert('horario_aula', {
      'id': 5,
      'modalidade': 'Treino Funcional',
      'data': '2026-10-07',
      'horario': '07:30',
      'professor_id': 3, // Ana Paula
      'vagas_totais': 10,
    });

    await db.insert('horario_aula', {
      'id': 6,
      'modalidade': 'Cross Training',
      'data': '2026-10-07',
      'horario': '18:00',
      'professor_id': 2, // Carlos Eduardo
      'vagas_totais': 12,
    });

    await db.insert('horario_aula', {
      'id': 7,
      'modalidade': 'Musculação (Orientada)',
      'data': '2026-10-08',
      'horario': '09:00',
      'professor_id': 2, // Carlos Eduardo
      'vagas_totais': 15,
    });
  }
}
