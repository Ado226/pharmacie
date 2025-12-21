// Fichier: lib/features/prescription/data/models/prescription_model.dart
import '../../domain/entities/prescription.dart';
import 'medication_model.dart';
import '../../../../core/config/api_config.dart';

/// Model Prescription (DTO - Data Transfer Object)
/// Hérite de l'entity et ajoute les méthodes de sérialisation
class PrescriptionModel extends Prescription {
  const PrescriptionModel({
    required super.id,
    required super.patientName,
    required super.createdAt,
    required super.medications,
    super.photoUrl,
  });

  /// Créer depuis JSON (pour API)
  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final List<PrescriptionMedicationItem> medications = [];

    if (json['prescription_medications'] != null) {
      final medicationsList = json['prescription_medications'] as List<dynamic>;

      for (var med in medicationsList) {
        final medicationData = med['medications'];

        if (medicationData != null) {
          final medication = MedicationModel.fromJson(medicationData);
          final patientTypeString = med['patient_type'];
          final patientType = PatientType.values.firstWhere(
            (type) => type.toString().split('.').last == patientTypeString,
            orElse: () => PatientType.adulte,
          );

          medications.add(PrescriptionMedicationItem(
            medication: medication,
            patientType: patientType,
          ));
        }
      }
    }

    return PrescriptionModel(
      id: json['id'],
      patientName: json['patient_name'],
      createdAt: DateTime.parse(json['created_at']),
      medications: medications,
    );
  }

  /// Convertir en JSON (pour API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'created_at': createdAt.toIso8601String(),
      'status': 'en_attente',
    };
  }

  /// Créer depuis Entity
  factory PrescriptionModel.fromEntity(Prescription prescription) {
    return PrescriptionModel(
      id: prescription.id,
      patientName: prescription.patientName,
      createdAt: prescription.createdAt,
      medications: prescription.medications,
    );
  }

  /// Convertir en Entity
  Prescription toEntity() {
    return Prescription(
      id: id,
      patientName: patientName,
      createdAt: createdAt,
      medications: medications,
    );
  }

  /// Créer depuis JSON backend Node.js (format différent)
  factory PrescriptionModel.fromBackendJson(Map<String, dynamic> json) {
    final List<PrescriptionMedicationItem> medications = [];

    // Le backend retourne "CommandeProduits" avec les produits
    if (json['CommandeProduits'] != null) {
      final produitsList = json['CommandeProduits'] as List<dynamic>;

      for (var produit in produitsList) {
        final produitData = produit['Produit'];

        if (produitData != null) {
          final medication = MedicationModel.fromBackendJson(produitData);

          // Mapper l'âge du produit au type de patient
          final ageString = produitData['age'] ?? 'adulte';
          final patientType = ageString == 'enfant'
              ? PatientType.enfant
              : PatientType.adulte;

          medications.add(PrescriptionMedicationItem(
            medication: medication,
            patientType: patientType,
          ));
        }
      }
    }

    // Extraire l'URL de la photo et corriger localhost -> adresse IP
    String? photoUrl;
    if (json['ordonnance_photo_url'] != null) {
      photoUrl = json['ordonnance_photo_url'] as String;
      // Remplacer localhost par l'adresse IP configurée
      photoUrl = photoUrl.replaceAll('localhost', ApiConfig.baseHost);
    }

    // Récupérer le nom du patient avec fallback
    final String? nomPatient = json['nom_patient'];
    final String displayPatientName = (nomPatient != null && nomPatient.isNotEmpty)
        ? nomPatient
        : 'Patient non renseigné';

    return PrescriptionModel(
      id: json['id'].toString(),
      patientName: displayPatientName,
      createdAt: DateTime.parse(json['created_at']),
      medications: medications,
      photoUrl: photoUrl,
    );
  }

  /// Convertir en JSON backend Node.js
  Map<String, dynamic> toBackendJson() {
    return {
      'type_commande': 'saisie_manuelle',
      'localisation_client_latitude': 0.0,
      'localisation_client_longitude': 0.0,
      'localisation_timestamp': createdAt.toIso8601String(),
      'produits': medications.map((med) {
        return {
          'produit_id': int.tryParse(med.medication.id) ?? 0,
          'quantite': 1,
        };
      }).toList(),
    };
  }
}
