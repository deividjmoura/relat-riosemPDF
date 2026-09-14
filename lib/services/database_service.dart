import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rdp_report.dart';
import '../models/scrap_report.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();
  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'relatorios_lear.db');
    _db = await openDatabase(path, version: 4, onCreate: (db, version) async {
      await db.execute('CREATE TABLE rdp_reports (id TEXT PRIMARY KEY, data TEXT, maquina TEXT, operador TEXT, reg TEXT, turno TEXT, json_data TEXT, created_at TEXT)');
      await db.execute('CREATE TABLE scrap_reports (id TEXT PRIMARY KEY, data TEXT, maquina TEXT, operador TEXT, json_data TEXT, created_at TEXT)');
      await _createDraftTable(db);
      await _createScrapDraftTable(db);
      await _createGeneratedDocsTable(db);
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) await _createDraftTable(db);
      if (oldVersion < 3) await _createScrapDraftTable(db);
      if (oldVersion < 4) await _createGeneratedDocsTable(db);
    });
  }

  Future<void> _createDraftTable(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS rdp_drafts (id TEXT PRIMARY KEY, json_data TEXT NOT NULL, updated_at TEXT NOT NULL)');
  }

  Future<void> _createScrapDraftTable(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS scrap_drafts (id TEXT PRIMARY KEY, json_data TEXT NOT NULL, updated_at TEXT NOT NULL)');
  }

  Future<void> saveRdpReport(String id, String data, String maquina, String operador, String json) async {
    await _db?.insert('rdp_reports', {'id': id, 'data': data, 'maquina': maquina, 'operador': operador, 'json_data': json, 'created_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  Future<void> saveScrapReport(String id, String data, String maquina, String operador, String json) async {
    await _db?.insert('scrap_reports', {'id': id, 'data': data, 'maquina': maquina, 'operador': operador, 'json_data': json, 'created_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getRdpReports() async => await _db?.query('rdp_reports', orderBy: 'created_at DESC') ?? [];
  Future<List<Map<String, dynamic>>> getScrapReports() async => await _db?.query('scrap_reports', orderBy: 'created_at DESC') ?? [];

  Future<void> saveRdpDraft(RdpReport report) async {
    final db = _db;
    if (db == null) return;
    await db.insert('rdp_drafts', {'id': report.id, 'json_data': jsonEncode(report.toMap()), 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<RdpReport?> getRdpDraft() async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query('rdp_drafts', orderBy: 'updated_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    try {
      final decoded = jsonDecode(rows.first['json_data'] as String);
      if (decoded is Map) return RdpReport.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {}
    return null;
  }

  Future<void> deleteRdpDraft(String id) async {
    await _db?.delete('rdp_drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveScrapDraft(ScrapReport report) async {
    final db = _db;
    if (db == null) return;
    await db.insert('scrap_drafts', {'id': report.id, 'json_data': jsonEncode(report.toMap()), 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ScrapReport?> getScrapDraft() async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query('scrap_drafts', orderBy: 'updated_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    try {
      final decoded = jsonDecode(rows.first['json_data'] as String);
      if (decoded is Map) return ScrapReport.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {}
    return null;
  }

  Future<void> deleteScrapDraft(String id) async {
    await _db?.delete('scrap_drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _createGeneratedDocsTable(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS generated_docs (id TEXT PRIMARY KEY, tipo TEXT NOT NULL, titulo TEXT NOT NULL, filename TEXT NOT NULL, path TEXT NOT NULL, created_at TEXT NOT NULL)');
  }

  /// Registra um PDF gerado no histórico de documentos.
  Future<void> saveGeneratedDoc({required String tipo, required String titulo, required String filename, required String path}) async {
    await _db?.insert('generated_docs', {'id': '${DateTime.now().microsecondsSinceEpoch}', 'tipo': tipo, 'titulo': titulo, 'filename': filename, 'path': path, 'created_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getGeneratedDocs() async => await _db?.query('generated_docs', orderBy: 'created_at DESC') ?? [];

  Future<void> deleteGeneratedDoc(String id) async {
    await _db?.delete('generated_docs', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }
}
