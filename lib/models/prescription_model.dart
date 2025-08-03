// Fichier: lib/models/prescription_model.dart
import 'medication_model.dart';

enum PatientType { enfant, adulte }

class PrescriptionMedicationItem {
  final MedicationModel medication;
  final PatientType patientType;
  
  PrescriptionMedicationItem({
    required this.medication,
    required this.patientType,
  });
}

class PrescriptionModel {
  String id;
  String name;
  DateTime createdAt;
  List<PrescriptionMedicationItem> medications;

  PrescriptionModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.medications,
  });

  // Méthode pour créer une copie avec des valeurs modifiées
  PrescriptionModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<PrescriptionMedicationItem>? medications,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      medications: medications ?? this.medications,
    );
  }

  // Méthode pour ajouter un médicament à l'ordonnance
  void addMedication(MedicationModel medication, PatientType patientType) {
    medications.add(
      PrescriptionMedicationItem(
        medication: medication,
        patientType: patientType,
      ),
    );
  }

  // Méthode pour supprimer un médicament de l'ordonnance
  void removeMedication(String medicationId) {
    medications.removeWhere((item) => item.medication.id == medicationId);
  }
}
