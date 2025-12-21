// Fichier: lib/features/prescription/data/models/medication_model.dart
import '../../domain/entities/medication.dart';

/// Model Medication (DTO)
class MedicationModel extends Medication {
  const MedicationModel({
    required super.id,
    required super.name,
    required super.description,
    required super.form,
    required super.dosage,
    required super.usage,
    required super.contraindications,
    required super.imageUrl,
  });

  /// Créer depuis JSON
  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      form: json['form'],
      dosage: json['dosage'],
      usage: json['usage'],
      contraindications: json['contraindications'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'form': form,
      'dosage': dosage,
      'usage': usage,
      'contraindications': contraindications,
      'image_url': imageUrl,
    };
  }

  /// Créer depuis Entity
  factory MedicationModel.fromEntity(Medication medication) {
    return MedicationModel(
      id: medication.id,
      name: medication.name,
      description: medication.description,
      form: medication.form,
      dosage: medication.dosage,
      usage: medication.usage,
      contraindications: medication.contraindications,
      imageUrl: medication.imageUrl,
    );
  }

  /// Convertir en Entity
  Medication toEntity() {
    return Medication(
      id: id,
      name: name,
      description: description,
      form: form,
      dosage: dosage,
      usage: usage,
      contraindications: contraindications,
      imageUrl: imageUrl,
    );
  }

  /// Créer depuis JSON backend Node.js (format Produit)
  factory MedicationModel.fromBackendJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'].toString(),
      name: json['nom'] ?? '',
      description: json['description'] ?? '',
      form: json['unite'] ?? '', // unite = boite, flacon, etc.
      dosage: json['posologie'] ?? '',
      usage: json['posologie'] ?? '',
      contraindications: json['contre_indications'] ?? '',
      imageUrl: '', // Le backend n'a pas d'images pour les produits
    );
  }

  /// Convertir en JSON backend Node.js (format Produit)
  Map<String, dynamic> toBackendJson() {
    return {
      'nom': name,
      'description': description,
      'posologie': dosage,
      'contre_indications': contraindications,
      'unite': form,
      'age': 'adulte', // Par défaut
    };
  }

  /// Créer une liste de médicaments fictifs pour les tests
  static List<MedicationModel> getMockMedications() {
    return [
      const MedicationModel(
        id: '1',
        name: 'Paracétamol 500mg',
        description: 'Antalgique et antipyrétique',
        form: 'Comprimé',
        dosage: '500mg',
        usage: '1 comprimé 3 fois par jour',
        contraindications: 'Allergie au paracétamol',
        imageUrl: '',
      ),
      const MedicationModel(
        id: '2',
        name: 'Ibuprofène 400mg',
        description: 'Anti-inflammatoire non stéroïdien',
        form: 'Comprimé',
        dosage: '400mg',
        usage: '1 comprimé 2 fois par jour',
        contraindications: 'Ulcère gastrique',
        imageUrl: '',
      ),
      const MedicationModel(
        id: '3',
        name: 'Amoxicilline 1g',
        description: 'Antibiotique',
        form: 'Gélule',
        dosage: '1g',
        usage: '1 gélule 2 fois par jour',
        contraindications: 'Allergie aux pénicillines',
        imageUrl: '',
      ),
      const MedicationModel(
        id: '4',
        name: 'Doliprane 1000mg',
        description: 'Antalgique et antipyrétique',
        form: 'Comprimé',
        dosage: '1000mg',
        usage: '1 comprimé 3 fois par jour',
        contraindications: 'Insuffisance hépatique',
        imageUrl: '',
      ),
      const MedicationModel(
        id: '5',
        name: 'Aspirine 500mg',
        description: 'Antalgique et antipyrétique',
        form: 'Comprimé',
        dosage: '500mg',
        usage: '1 comprimé 3 fois par jour',
        contraindications: 'Troubles de coagulation',
        imageUrl: '',
      ),
    ];
  }
}
