// Fichier: lib/features/prescription/domain/entities/prescription.dart
import 'package:equatable/equatable.dart';
import 'medication.dart';

/// Enum pour le type de patient
enum PatientType { enfant, adulte }

/// Entity Prescription Item (association prescription-medication)
class PrescriptionMedicationItem extends Equatable {
  final Medication medication;
  final PatientType patientType;

  const PrescriptionMedicationItem({
    required this.medication,
    required this.patientType,
  });

  @override
  List<Object?> get props => [medication, patientType];
}

/// Entity Prescription (pure business object)
class Prescription extends Equatable {
  final String id;
  final String patientName;
  final DateTime createdAt;
  final List<PrescriptionMedicationItem> medications;
  final String? photoUrl; // URL de l'image de l'ordonnance (null si saisie manuelle)

  const Prescription({
    required this.id,
    required this.patientName,
    required this.createdAt,
    required this.medications,
    this.photoUrl,
  });

  /// Copier avec modifications
  Prescription copyWith({
    String? id,
    String? patientName,
    DateTime? createdAt,
    List<PrescriptionMedicationItem>? medications,
    String? photoUrl,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      createdAt: createdAt ?? this.createdAt,
      medications: medications ?? this.medications,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [id, patientName, createdAt, medications, photoUrl];
}
