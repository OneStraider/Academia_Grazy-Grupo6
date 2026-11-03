import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'database_events.dart';
import 'usuario_service.dart';

class AgendamentoService {
  final DatabaseHelper databaseHelper;
  AgendamentoService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<int> criarHorario({
    required int professorId,
    required String nomeAula,
    required DateTime inicio,
    int capacidade = 8,
    int minParticipantes = 1,
  }) async {
    if (nomeAula.trim().isEmpty) throw Exception('Informe o nome da aula.');
    if (capacidade < 1)
      throw Exception('A aula precisa ter pelo menos uma vaga.');
    if (minParticipantes < 1 || minParticipantes > capacidade) {
      throw Exception('O mÃ­nimo deve ser entre 1 e a quantidade de vagas.');
    }
    if (inicio.difference(DateTime.now()) < const Duration(hours: 1)) {
      throw Exception(
        'O horÃ¡rio precisa comeÃ§ar pelo menos 1 hora no futuro.',
      );
    }
    final db = await databaseHelper.database;
    final id = await db.insert('horario_aula', {
      'professor_id': professorId,
      'nome_aula': nomeAula.trim(),
      'inicio': inicio.toIso8601String(),
      'capacidade': capacidade,
      'min_participantes': minParticipantes,
    });
    DatabaseEvents.changed();
    return id;
  }

  Future<void> editarHorario({
    required int horarioId,
    required String nomeAula,
    required DateTime inicio,
    required int capacidade,
    required int minParticipantes,
  }) async {
    if (nomeAula.trim().isEmpty) throw Exception('Informe o nome da aula.');
    if (capacidade < 1)
      throw Exception('A aula precisa ter pelo menos uma vaga.');
    if (minParticipantes < 1 || minParticipantes > capacidade) {
      throw Exception('O mÃ­nimo deve ser entre 1 e a quantidade de vagas.');
    }
    if (inicio.difference(DateTime.now()) < const Duration(hours: 1)) {
      throw Exception(
        'O horÃ¡rio precisa comeÃ§ar pelo menos 1 hora no futuro.',
      );
    }
    final db = await databaseHelper.database;
    final ocupadas =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM agendamento WHERE horario_id=? AND status IN ('AGENDADO','CHECK_IN')",
            [horarioId],
          ),
        ) ??
        0;
    if (capacidade < ocupadas) {
      throw Exception(
        'A capacidade nÃ£o pode ser menor que as $ocupadas reservas existentes.',
      );
    }
    final alteradas = await db.update(
      'horario_aula',
      {
        'nome_aula': nomeAula.trim(),
        'inicio': inicio.toIso8601String(),
        'capacidade': capacidade,
        'min_participantes': minParticipantes,
      },
      where: 'id=? AND ativo=1',
      whereArgs: [horarioId],
    );
    if (alteradas == 0) throw Exception('HorÃ¡rio nÃ£o encontrado.');
    DatabaseEvents.changed();
  }

  Future<void> excluirHorario(int horarioId) async {
    final db = await databaseHelper.database;
    await db.transaction((tx) async {
      final alteradas = await tx.update(
        'horario_aula',
        {'ativo': 0},
        where: 'id=? AND ativo=1',
        whereArgs: [horarioId],
      );
      if (alteradas == 0) throw Exception('Horário não encontrado.');
      await tx.update(
        'agendamento',
        {'status': 'CANCELADO'},
        where: "horario_id=? AND status IN ('AGENDADO','CHECK_IN')",
        whereArgs: [horarioId],
      );
    });
    DatabaseEvents.changed();
  }

  Future<List<Map<String, Object?>>> listarParticipantes(int horarioId) async {
    final db = await databaseHelper.database;
    return db.rawQuery(
      '''
      SELECT a.id AS agendamento_id, a.status, a.criado_em,
             u.id AS aluno_id, u.nome AS aluno_nome, u.email AS aluno_email
      FROM agendamento a
      JOIN usuario u ON u.id = a.aluno_id
      WHERE a.horario_id = ? AND a.status IN ('AGENDADO','CHECK_IN')
      ORDER BY u.nome COLLATE NOCASE
    ''',
      [horarioId],
    );
  }

  Future<List<Map<String, Object?>>> listarHorarios({int? alunoId}) async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      '''SELECT h.*, u.nome professor_nome,
      (SELECT COUNT(*) FROM agendamento a WHERE a.horario_id=h.id AND a.status IN ('AGENDADO','CHECK_IN')) ocupadas,
      (SELECT a.id FROM agendamento a WHERE a.horario_id=h.id AND a.aluno_id=? AND a.status IN ('AGENDADO','CHECK_IN') LIMIT 1) agendamento_id,
      (SELECT a.status FROM agendamento a WHERE a.horario_id=h.id AND a.aluno_id=? AND a.status IN ('AGENDADO','CHECK_IN') LIMIT 1) agendamento_status
      FROM horario_aula h JOIN usuario u ON u.id=h.professor_id
      WHERE h.ativo=1 AND u.ativo=1 AND h.inicio>=? ORDER BY h.inicio''',
      [alunoId ?? -1, alunoId ?? -1, DateTime.now().toIso8601String()],
    );
    return rows;
  }

  Future<Map<String, Object?>?> buscarAgendamento(int id) async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT a.*, h.nome_aula, h.inicio, h.capacidade, p.nome AS professor_nome, u.nome AS aluno_nome
      FROM agendamento a
      JOIN horario_aula h ON h.id = a.horario_id
      JOIN usuario p ON p.id = h.professor_id
      JOIN usuario u ON u.id = a.aluno_id
      WHERE a.id = ?
    ''',
      [id],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> agendar({required int horarioId, required int alunoId}) async {
    final db = await databaseHelper.database;
    await db.transaction((tx) async {
      final horarios = await tx.query(
        'horario_aula',
        where: 'id=? AND ativo=1',
        whereArgs: [horarioId],
        limit: 1,
      );
      if (horarios.isEmpty) throw Exception('HorÃ¡rio indisponÃ­vel.');
      final alunos = await tx.query(
        'usuario',
        columns: ['ativo', 'tipo'],
        where: 'id = ?',
        whereArgs: [alunoId],
        limit: 1,
      );
      if (alunos.isEmpty || alunos.first['tipo'] != 'ALUNO') {
        throw Exception('Conta de aluno não encontrada.');
      }
      if (alunos.first['ativo'] != 1) {
        throw Exception(UsuarioService.alunoInativoMensagem);
      }
      final inicio = DateTime.parse(horarios.first['inicio'] as String);
      if (inicio.difference(DateTime.now()) < const Duration(hours: 1))
        throw Exception('Agende com pelo menos 1 hora de antecedÃªncia.');
      final duplicado =
          Sqflite.firstIntValue(
            await tx.rawQuery(
              "SELECT COUNT(*) FROM agendamento WHERE horario_id=? AND aluno_id=? AND status IN ('AGENDADO','CHECK_IN')",
              [horarioId, alunoId],
            ),
          ) ??
          0;
      if (duplicado > 0)
        throw Exception('VocÃª jÃ¡ estÃ¡ inscrito neste horÃ¡rio.');
      final existentes =
          Sqflite.firstIntValue(
            await tx.rawQuery(
              "SELECT COUNT(*) FROM agendamento WHERE horario_id=? AND status IN ('AGENDADO','CHECK_IN')",
              [horarioId],
            ),
          ) ??
          0;
      if (existentes >= (horarios.first['capacidade'] as int))
        throw Exception('NÃ£o hÃ¡ vagas disponÃ­veis.');
      await tx.insert('agendamento', {
        'horario_id': horarioId,
        'aluno_id': alunoId,
        'status': 'AGENDADO',
        'criado_em': DateTime.now().toIso8601String(),
      });
    });
    DatabaseEvents.changed();
  }

  Future<void> cancelar(int agendamentoId, {required int alunoId}) async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT a.id, h.inicio FROM agendamento a
      JOIN horario_aula h ON h.id = a.horario_id
      WHERE a.id = ? AND a.aluno_id = ? AND a.status IN ('AGENDADO','CHECK_IN')
      ''',
      [agendamentoId, alunoId],
    );
    if (rows.isEmpty) throw Exception('Agendamento nÃ£o encontrado.');
    final inicio = DateTime.parse(rows.first['inicio'] as String);
    if (inicio.difference(DateTime.now()) < const Duration(hours: 2))
      throw Exception('Cancelamento disponÃ­vel atÃ© 2 horas antes da aula.');
    final alteradas = await db.update(
      'agendamento',
      {'status': 'CANCELADO'},
      where: 'id = ? AND aluno_id = ? AND status IN (?, ?)',
      whereArgs: [agendamentoId, alunoId, 'AGENDADO', 'CHECK_IN'],
    );
    if (alteradas == 0) throw Exception('Agendamento não encontrado.');
    DatabaseEvents.changed();
  }

  Future<void> checkin(int agendamentoId, {required int alunoId}) async {
    final db = await databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT h.inicio FROM agendamento a
      JOIN horario_aula h ON h.id = a.horario_id
      WHERE a.id = ? AND a.aluno_id = ? AND a.status = 'AGENDADO'
      ''',
      [agendamentoId, alunoId],
    );
    if (rows.isEmpty) throw Exception('Agendamento nÃ£o encontrado.');
    final delta = DateTime.parse(rows.first['inicio'] as String)
        .difference(DateTime.now());
    if (delta > const Duration(minutes: 30) || delta.isNegative)
      throw Exception('Check-in liberado nos 30 minutos anteriores Ã  aula.');
    final alteradas = await db.update(
      'agendamento',
      {'status': 'CHECK_IN'},
      where: 'id = ? AND aluno_id = ? AND status = ?',
      whereArgs: [agendamentoId, alunoId, 'AGENDADO'],
    );
    if (alteradas == 0) throw Exception('Agendamento não encontrado.');
    DatabaseEvents.changed();
  }
}
