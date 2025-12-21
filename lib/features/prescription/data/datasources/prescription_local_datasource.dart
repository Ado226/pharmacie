// Fichier: lib/features/prescription/data/datasources/prescription_local_datasource.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/error/exceptions.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../../domain/entities/prescription.dart';

/// Interface du DataSource local (SQLite)
abstract class PrescriptionLocalDataSource {
  Future<List<PrescriptionModel>> getCachedPrescriptions();
  Future<PrescriptionModel> getCachedPrescriptionById(String id);
  Future<void> cachePrescriptions(List<PrescriptionModel> prescriptions);
  Future<void> cachePrescription(PrescriptionModel prescription);
  Future<void> deleteCachedPrescription(String id);
  Future<void> clearCache();
}

/// Implémentation avec SQLite
class PrescriptionLocalDataSourceImpl implements PrescriptionLocalDataSource {
  final Database database;

  static const String prescriptionsTable = 'prescriptions';
  static const String medicationsTable = 'medications';
  static const String prescriptionMedicationsTable = 'prescription_medications';

  PrescriptionLocalDataSourceImpl({required this.database});

  @override
  Future<List<PrescriptionModel>> getCachedPrescriptions() async {
    try {
      final List<Map<String, dynamic>> prescriptionsData =
          await database.query(prescriptionsTable, orderBy: 'created_at DESC');

      final List<PrescriptionModel> prescriptions = [];

      for (var prescriptionData in prescriptionsData) {
        // Récupérer les médicaments associés
        final medications = await _getMedicationsForPrescription(prescriptionData['id']);

        prescriptions.add(PrescriptionModel(
          id: prescriptionData['id'],
          patientName: prescriptionData['patient_name'],
          createdAt: DateTime.parse(prescriptionData['created_at']),
          medications: medications,
        ));
      }

      return prescriptions;
    } catch (e) {
      throw CacheException('Erreur lors de la récupération des prescriptions en cache: $e');
    }
  }

  @override
  Future<PrescriptionModel> getCachedPrescriptionById(String id) async {
    try {
      final List<Map<String, dynamic>> prescriptionsData = await database.query(
        prescriptionsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (prescriptionsData.isEmpty) {
        throw CacheException('Prescription non trouvée dans le cache');
      }

      final prescriptionData = prescriptionsData.first;
      final medications = await _getMedicationsForPrescription(id);

      return PrescriptionModel(
        id: prescriptionData['id'],
        patientName: prescriptionData['patient_name'],
        createdAt: DateTime.parse(prescriptionData['created_at']),
        medications: medications,
      );
    } catch (e) {
      throw CacheException('Erreur lors de la récupération de la prescription en cache: $e');
    }
  }

  @override
  Future<void> cachePrescriptions(List<PrescriptionModel> prescriptions) async {
    try {
      // Supprimer l'ancien cache
      await clearCache();

      // Insérer les nouvelles prescriptions
      for (var prescription in prescriptions) {
        await cachePrescription(prescription);
      }
    } catch (e) {
      throw CacheException('Erreur lors de la mise en cache des prescriptions: $e');
    }
  }

  @override
  Future<void> cachePrescription(PrescriptionModel prescription) async {
    try {
      // Insérer la prescription
      await database.insert(
        prescriptionsTable,
        {
          'id': prescription.id,
          'patient_name': prescription.patientName,
          'created_at': prescription.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Supprimer les anciennes associations
      await database.delete(
        prescriptionMedicationsTable,
        where: 'prescription_id = ?',
        whereArgs: [prescription.id],
      );

      // Insérer les médicaments et leurs associations
      for (var medicationItem in prescription.medications) {
        final medication = MedicationModel.fromEntity(medicationItem.medication);

        // Insérer le médicament
        await database.insert(
          medicationsTable,
          medication.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insérer l'association
        await database.insert(
          prescriptionMedicationsTable,
          {
            'prescription_id': prescription.id,
            'medication_id': medication.id,
            'patient_type': medicationItem.patientType.toString().split('.').last,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      throw CacheException('Erreur lors de la mise en cache de la prescription: $e');
    }
  }

  @override
  Future<void> deleteCachedPrescription(String id) async {
    try {
      // Supprimer les associations
      await database.delete(
        prescriptionMedicationsTable,
        where: 'prescription_id = ?',
        whereArgs: [id],
      );

      // Supprimer la prescription
      await database.delete(
        prescriptionsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Erreur lors de la suppression de la prescription en cache: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await database.delete(prescriptionMedicationsTable);
      await database.delete(prescriptionsTable);
    } catch (e) {
      throw CacheException('Erreur lors de la suppression du cache: $e');
    }
  }

  // Méthode privée pour récupérer les médicaments d'une prescription
  Future<List<PrescriptionMedicationItem>> _getMedicationsForPrescription(String prescriptionId) async {
    final List<Map<String, dynamic>> data = await database.rawQuery('''
      SELECT m.*, pm.patient_type
      FROM $medicationsTable m
      INNER JOIN $prescriptionMedicationsTable pm ON m.id = pm.medication_id
      WHERE pm.prescription_id = ?
    ''', [prescriptionId]);

    return data.map((item) {
      final medication = MedicationModel.fromJson(item);
      final patientTypeString = item['patient_type'];
      final patientType = PatientType.values.firstWhere(
        (type) => type.toString().split('.').last == patientTypeString,
        orElse: () => PatientType.adulte,
      );

      return PrescriptionMedicationItem(
        medication: medication,
        patientType: patientType,
      );
    }).toList();
  }
}
