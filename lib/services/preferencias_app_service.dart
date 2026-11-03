import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class PreferenciasAppService {
  PreferenciasAppService._();

  static final ValueNotifier<bool> modoEscuro = ValueNotifier(false);

  static Future<void> carregar() async {
    final db = await DatabaseHelper.instance.database;
    final linhas = await db.query(
      'preferencia_app',
      columns: ['valor'],
      where: 'chave = ?',
      whereArgs: ['modo_escuro'],
      limit: 1,
    );
    modoEscuro.value = linhas.isNotEmpty && linhas.first['valor'] == '1';
  }

  static Future<void> definirModoEscuro(bool ativado) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('preferencia_app', {
      'chave': 'modo_escuro',
      'valor': ativado ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    modoEscuro.value = ativado;
  }
}
