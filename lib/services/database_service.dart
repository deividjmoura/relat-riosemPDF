import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'relatorios_lear.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabela de relatórios RDP
        await db.execute('''
          CREATE TABLE rdp_reports (
            id TEXT PRIMARY KEY,
            data TEXT,
            maquina TEXT,
            operador TEXT,
            reg TEXT,
            turno TEXT,
            json_data TEXT,
            created_at TEXT
          )
        ''');

        // Tabela de scrap
        await db.execute('''
          CREATE TABLE scrap_reports (
            id TEXT PRIMARY KEY,
            data TEXT,
            maquina TEXT,
            operador TEXT,
            json_data TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveRdpReport(String id, String data, String maquina, String operador, String json) async {
    await _db?.insert(
      'rdp_reports',
      {
        'id': id,
        'data': data,
        'maquina': maquina,
        'operador': operador,
        'json_data': json,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<void> saveScrapReport(String id, String data, String maquina, String operador, String json) async {
    await _db?.insert(
      'scrap_reports',
      {
        'id': id,
        'data': data,
        'maquina': maquina,
        'operador': operador,
        'json_data': json,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getRdpReports() async {
    return await _db?.query('rdp_reports', orderBy: 'created_at DESC') ?? [];
  }

  Future<List<Map<String, dynamic>>> getScrapReports() async {
    return await _db?.query('scrap_reports', orderBy: 'created_at DESC') ?? [];
  }
}
