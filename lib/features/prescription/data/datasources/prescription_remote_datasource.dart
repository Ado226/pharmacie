// Fichier: lib/features/prescription/data/datasources/prescription_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import 'dart:math';

/// Interface du DataSource distant (Supabase/API)
abstract class PrescriptionRemoteDataSource {
  Future<List<PrescriptionModel>> getAllPrescriptions();
  Future<PrescriptionModel> getPrescriptionById(String id);
  Future<String> createPrescription(PrescriptionModel prescription);
  Future<bool> updatePrescription(PrescriptionModel prescription);
  Future<bool> deletePrescription(String id);
}

/// Implémentation avec Supabase
class PrescriptionRemoteDataSourceImpl implements PrescriptionRemoteDataSource {
  final SupabaseClient supabaseClient;

  // Noms des tables
  static const String prescriptionsTable = 'prescriptions';
  static const String prescriptionMedicationsTable = 'prescription_medications';
  static const String medicationsTable = 'medications';

  PrescriptionRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<PrescriptionModel>> getAllPrescriptions() async {
    try {
      final response = await supabaseClient
          .from(prescriptionsTable)
          .select('*, $prescriptionMedicationsTable(*, $medicationsTable(*))')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => PrescriptionModel.fromJson(item)).toList();
    } catch (e) {
      throw ServerException('Erreur lors de la récupération des prescriptions: $e');
    }
  }

  @override
  Future<PrescriptionModel> getPrescriptionById(String id) async {
    try {
      final response = await supabaseClient
          .from(prescriptionsTable)
          .select('*, $prescriptionMedicationsTable(*, $medicationsTable(*))')
          .eq('id', id)
          .single();

      return PrescriptionModel.fromJson(response);
    } catch (e) {
      throw ServerException('Erreur lors de la récupération de la prescription: $e');
    }
  }

  @override
  Future<String> createPrescription(PrescriptionModel prescription) async {
    try {
      // Vérifier et insérer les médicaments s'ils n'existent pas
      for (var medicationItem in prescription.medications) {
        final medication = MedicationModel.fromEntity(medicationItem.medication);
        final exists = await _medicationExists(medication.id);

        if (!exists) {
          await _insertMedication(medication);
        }
      }

      // Générer UUID
      final uuid = _generateUuid();

      // Insérer la prescription
      final prescriptionResponse = await supabaseClient
          .from(prescriptionsTable)
          .insert(prescription.toJson()..['id'] = uuid)
          .select('id')
          .single();

      final String prescriptionId = prescriptionResponse['id'] ?? uuid;

      // Insérer les médicaments de la prescription
      for (var medication in prescription.medications) {
        await supabaseClient.from(prescriptionMedicationsTable).insert({
          'prescription_id': prescriptionId,
          'medication_id': medication.medication.id,
          'patient_type': medication.patientType.toString().split('.').last,
        });
      }

      return prescriptionId;
    } catch (e) {
      throw ServerException('Erreur lors de la création de la prescription: $e');
    }
  }

  @override
  Future<bool> updatePrescription(PrescriptionModel prescription) async {
    try {
      // Mettre à jour la prescription
      await supabaseClient
          .from(prescriptionsTable)
          .update(prescription.toJson())
          .eq('id', prescription.id);

      // Supprimer les anciens médicaments
      await supabaseClient
          .from(prescriptionMedicationsTable)
          .delete()
          .eq('prescription_id', prescription.id);

      // Insérer les nouveaux médicaments
      for (var medication in prescription.medications) {
        await supabaseClient.from(prescriptionMedicationsTable).insert({
          'prescription_id': prescription.id,
          'medication_id': medication.medication.id,
          'patient_type': medication.patientType.toString().split('.').last,
        });
      }

      return true;
    } catch (e) {
      throw ServerException('Erreur lors de la mise à jour de la prescription: $e');
    }
  }

  @override
  Future<bool> deletePrescription(String id) async {
    try {
      // Supprimer les médicaments associés
      await supabaseClient
          .from(prescriptionMedicationsTable)
          .delete()
          .eq('prescription_id', id);

      // Supprimer la prescription
      await supabaseClient.from(prescriptionsTable).delete().eq('id', id);

      return true;
    } catch (e) {
      throw ServerException('Erreur lors de la suppression de la prescription: $e');
    }
  }

  // Méthodes privées utilitaires
  Future<bool> _medicationExists(String id) async {
    try {
      final response = await supabaseClient
          .from(medicationsTable)
          .select('id')
          .eq('id', id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _insertMedication(MedicationModel medication) async {
    try {
      await supabaseClient.from(medicationsTable).insert(medication.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  String _generateUuid() {
    final random = Random();
    final hexDigits = '0123456789abcdef';

    String generateHex(int length) {
      return List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
    }

    return '${generateHex(8)}-${generateHex(4)}-4${generateHex(3)}-'
        '${hexDigits[random.nextInt(4) + 8]}${generateHex(3)}-${generateHex(12)}';
  }
}
