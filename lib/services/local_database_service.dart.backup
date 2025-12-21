// Fichier: lib/services/local_database_service.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';

class LocalDatabaseService {
  // Singleton pattern
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;

  // Méthode pour obtenir une instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Méthode pour initialiser la base de données
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'pharmacie.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  // Méthode pour créer les tables de la base de données
  Future<void> _createDatabase(Database db, int version) async {
    // Table des médicaments
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        form TEXT NOT NULL,
        dosage TEXT NOT NULL,
        usage TEXT NOT NULL,
        contraindications TEXT,
        imageUrl TEXT,
        price REAL,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // Table des ordonnances
    await db.execute('''
      CREATE TABLE prescriptions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // Table de relation entre ordonnances et médicaments
    await db.execute('''
      CREATE TABLE prescription_medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id TEXT NOT NULL,
        medication_id TEXT NOT NULL,
        patient_type TEXT NOT NULL,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id) ON DELETE CASCADE,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // Table des pharmacies
    await db.execute('''
      CREATE TABLE pharmacies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        latitude REAL,
        longitude REAL,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    // Table des réponses des pharmacies
    await db.execute('''
      CREATE TABLE pharmacy_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id TEXT NOT NULL,
        pharmacy_id TEXT NOT NULL,
        response_date TEXT NOT NULL,
        total_price REAL NOT NULL,
        availability_status TEXT NOT NULL,
        delivery_option BOOLEAN NOT NULL,
        estimated_delivery_time TEXT,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id) ON DELETE CASCADE,
        FOREIGN KEY (pharmacy_id) REFERENCES pharmacies (id) ON DELETE CASCADE
      )
    ''');

    // Table des détails de réponse des pharmacies (prix par médicament)
    await db.execute('''
      CREATE TABLE pharmacy_response_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        response_id INTEGER NOT NULL,
        medication_id TEXT NOT NULL,
        price REAL NOT NULL,
        available BOOLEAN NOT NULL,
        alternative_id TEXT,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (response_id) REFERENCES pharmacy_responses (id) ON DELETE CASCADE,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE,
        FOREIGN KEY (alternative_id) REFERENCES medications (id)
      )
    ''');
  }

  // Méthodes pour les médicaments
  Future<List<MedicationModel>> getMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medications');
    
    return List.generate(maps.length, (i) {
      return MedicationModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        form: maps[i]['form'],
        dosage: maps[i]['dosage'],
        usage: maps[i]['usage'],
        contraindications: maps[i]['contraindications'] ?? '',
        imageUrl: maps[i]['imageUrl'],
      );
    });
  }

  Future<MedicationModel?> getMedication(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    return MedicationModel(
      id: maps[0]['id'],
      name: maps[0]['name'],
      description: maps[0]['description'],
      form: maps[0]['form'],
      dosage: maps[0]['dosage'],
      usage: maps[0]['usage'],
      contraindications: maps[0]['contraindications'] ?? '',
      imageUrl: maps[0]['imageUrl'],
    );
  }

  Future<void> insertMedication(MedicationModel medication) async {
    final db = await database;
    await db.insert(
      'medications',
      {
        'id': medication.id,
        'name': medication.name,
        'description': medication.description,
        'form': medication.form,
        'dosage': medication.dosage,
        'usage': medication.usage,
        'contraindications': medication.contraindications,
        'imageUrl': medication.imageUrl,
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMedication(MedicationModel medication) async {
    final db = await database;
    await db.update(
      'medications',
      {
        'name': medication.name,
        'description': medication.description,
        'form': medication.form,
        'dosage': medication.dosage,
        'usage': medication.usage,
        'contraindications': medication.contraindications,
        'imageUrl': medication.imageUrl,
        'sync_status': 1,
      },
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<void> deleteMedication(String id) async {
    final db = await database;
    await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes pour les ordonnances
  Future<List<PrescriptionModel>> getPrescriptions() async {
    final db = await database;
    final List<Map<String, dynamic>> prescriptionMaps = await db.query('prescriptions');
    
    List<PrescriptionModel> prescriptions = [];
    
    for (var prescriptionMap in prescriptionMaps) {
      final String prescriptionId = prescriptionMap['id'];
      
      // Récupérer les médicaments associés à cette ordonnance
      final List<Map<String, dynamic>> medicationMaps = await db.rawQuery('''
        SELECT m.*, pm.patient_type
        FROM medications m
        JOIN prescription_medications pm ON m.id = pm.medication_id
        WHERE pm.prescription_id = ?
      ''', [prescriptionId]);
      
      List<PrescriptionMedicationItem> medications = [];
      
      for (var medicationMap in medicationMaps) {
        final medication = MedicationModel(
          id: medicationMap['id'],
          name: medicationMap['name'],
          description: medicationMap['description'],
          form: medicationMap['form'],
          dosage: medicationMap['dosage'],
          usage: medicationMap['usage'],
          contraindications: medicationMap['contraindications'] ?? '',
          imageUrl: medicationMap['imageUrl'],
        );
        
        final patientType = medicationMap['patient_type'] == 'enfant'
            ? PatientType.enfant
            : PatientType.adulte;
        
        medications.add(PrescriptionMedicationItem(
          medication: medication,
          patientType: patientType,
        ));
      }
      
      prescriptions.add(PrescriptionModel(
        id: prescriptionId,
        name: prescriptionMap['name'],
        createdAt: DateTime.parse(prescriptionMap['created_at']),
        medications: medications,
      ));
    }
    
    return prescriptions;
  }

  Future<PrescriptionModel?> getPrescription(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> prescriptionMaps = await db.query(
      'prescriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (prescriptionMaps.isEmpty) return null;
    
    // Récupérer les médicaments associés à cette ordonnance
    final List<Map<String, dynamic>> medicationMaps = await db.rawQuery('''
      SELECT m.*, pm.patient_type
      FROM medications m
      JOIN prescription_medications pm ON m.id = pm.medication_id
      WHERE pm.prescription_id = ?
    ''', [id]);
    
    List<PrescriptionMedicationItem> medications = [];
    
    for (var medicationMap in medicationMaps) {
      final medication = MedicationModel(
        id: medicationMap['id'],
        name: medicationMap['name'],
        description: medicationMap['description'],
        form: medicationMap['form'],
        dosage: medicationMap['dosage'],
        usage: medicationMap['usage'],
        contraindications: medicationMap['contraindications'] ?? '',
        imageUrl: medicationMap['imageUrl'],
      );
      
      final patientType = medicationMap['patient_type'] == 'enfant'
          ? PatientType.enfant
          : PatientType.adulte;
      
      medications.add(PrescriptionMedicationItem(
        medication: medication,
        patientType: patientType,
      ));
    }
    
    return PrescriptionModel(
      id: id,
      name: prescriptionMaps[0]['name'],
      createdAt: DateTime.parse(prescriptionMaps[0]['created_at']),
      medications: medications,
    );
  }

  Future<void> insertPrescription(PrescriptionModel prescription) async {
    final db = await database;
    
    // Insérer l'ordonnance
    await db.insert(
      'prescriptions',
      {
        'id': prescription.id,
        'name': prescription.name,
        'created_at': prescription.createdAt.toIso8601String(),
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Insérer les médicaments associés
    for (var medicationItem in prescription.medications) {
      // S'assurer que le médicament existe dans la table des médicaments
      await insertMedication(medicationItem.medication);
      
      // Insérer la relation entre l'ordonnance et le médicament
      await db.insert(
        'prescription_medications',
        {
          'prescription_id': prescription.id,
          'medication_id': medicationItem.medication.id,
          'patient_type': medicationItem.patientType == PatientType.enfant ? 'enfant' : 'adulte',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updatePrescription(PrescriptionModel prescription) async {
    final db = await database;
    
    // Mettre à jour l'ordonnance
    await db.update(
      'prescriptions',
      {
        'name': prescription.name,
        'created_at': prescription.createdAt.toIso8601String(),
        'sync_status': 1,
      },
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
    
    // Supprimer les anciennes relations
    await db.delete(
      'prescription_medications',
      where: 'prescription_id = ?',
      whereArgs: [prescription.id],
    );
    
    // Insérer les nouvelles relations
    for (var medicationItem in prescription.medications) {
      // S'assurer que le médicament existe dans la table des médicaments
      await insertMedication(medicationItem.medication);
      
      // Insérer la relation entre l'ordonnance et le médicament
      await db.insert(
        'prescription_medications',
        {
          'prescription_id': prescription.id,
          'medication_id': medicationItem.medication.id,
          'patient_type': medicationItem.patientType == PatientType.enfant ? 'enfant' : 'adulte',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deletePrescription(String id) async {
    final db = await database;
    
    // Supprimer les relations
    await db.delete(
      'prescription_medications',
      where: 'prescription_id = ?',
      whereArgs: [id],
    );
    
    // Supprimer l'ordonnance
    await db.delete(
      'prescriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthode pour synchroniser les données locales avec le serveur
  Future<List<Map<String, dynamic>>> getUnsyncedData(String table) async {
    final db = await database;
    return await db.query(
      table,
      where: 'sync_status = ?',
      whereArgs: [1], // 1 = modifié localement, à synchroniser
    );
  }

  Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'sync_status': 0}, // 0 = synchronisé
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
