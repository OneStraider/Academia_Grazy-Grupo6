import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/horario_aula.dart';
import '../models/agendamento.dart';

class AgendamentoService {
  static final AgendamentoService _instance = AgendamentoService._internal();

  static AgendamentoService get instance => _instance;

  late Database _database;

  AgendamentoService._internal();

  Future<void> initialize() async {
    _database = await DatabaseHelper.instance.database;
  }

  // TODO: Constantes de prazos (a confirmar com o grupo até 26/10)
  static const int antecedenciaMinima = 360; // 6 horas em minutos
  static const int prazoCancelamento = 120; // 2 horas em minutos
  static const int janelaCheckin = 30; // 30 minutos

  /// Lista todos os horários de aula de um dia específico
  /// Calcula vagas disponíveis na consulta
  Future<List<HorarioAula>> listarHorarios(DateTime dia) async {
    // TODO: Implementar
    throw UnimplementedError('listarHorarios não implementado ainda');
  }

  /// Cria um novo horário de aula
  /// Retorna o ID do horário criado
  Future<int> criarHorario(HorarioAula horario) async {
    // TODO: Implementar
    throw UnimplementedError('criarHorario não implementado ainda');
  }

  /// Agenda um aluno em um horário de aula
  /// Validações:
  /// - Há vaga disponível?
  /// - Aluno não tem agendamento ativo no mesmo horário?
  /// - Respeita antecedência mínima?
  /// Roda em transaction
  Future<int> agendar(int alunoId, int horarioId) async {
    // TODO: Implementar
    throw UnimplementedError('agendar não implementado ainda');
  }

  /// Cancela um agendamento
  /// Validação: cancelamento até X horas antes da aula
  Future<void> cancelar(int agendamentoId) async {
    // TODO: Implementar
    throw UnimplementedError('cancelar não implementado ainda');
  }

  /// Registra check-in do aluno
  /// Validações:
  /// - Dentro da janela de check-in (30 min antes da aula)?
  /// - Status muda para PRESENTE
  /// - Registra checkin_em com timestamp
  Future<void> fazerCheckin(int agendamentoId) async {
    // TODO: Implementar
    throw UnimplementedError('fazerCheckin não implementado ainda');
  }

  /// Retorna o próximo agendamento do aluno (mais próximo cronologicamente)
  /// Usado na Home: "Próximo agendamento"
  Future<Agendamento?> proximoAgendamentoDoAluno(int alunoId) async {
    // TODO: Implementar
    throw UnimplementedError(
      'proximoAgendamentoDoAluno não implementado ainda',
    );
  }

  /// Lista todos os agendamentos do aluno
  /// Ordenados por data/hora
  Future<List<Agendamento>> listarAgendamentosDoAluno(int alunoId) async {
    // TODO: Implementar
    throw UnimplementedError(
      'listarAgendamentosDoAluno não implementado ainda',
    );
  }
}
