// Fichier: lib/services/local_database_service.dart
// Version simplifiée - Les fonctionnalités ont été migrées vers Clean Architecture
// Utiliser les datasources locales dans chaque feature au lieu de ce service

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pharmacie_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Créer les tables de base
    await db.execute('''
      CREATE TABLE prescriptions(
        id TEXT PRIMARY KEY,
        name TEXT,
        created_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE medications(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        form TEXT,
        dosage TEXT,
        usage TEXT,
        contraindications TEXT,
        image_url TEXT
      )
    ''');
  }

  // Les méthodes spécifiques ont été déplacées vers les datasources locales
  // dans chaque feature (auth, prescription, etc.)

  // Méthodes basiques pour compatibilité avec le code legacy
  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    final db = await database;
    return await db.query('prescriptions');
  }

  Future<void> insertPrescription(Map<String, dynamic> prescription) async {
    final db = await database;
    await db.insert('prescriptions', prescription);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deletePrescription(String id) async {
    final db = await database;
    await db.delete('prescriptions', where: 'id = ?', whereArgs: [id]);
  }
}
