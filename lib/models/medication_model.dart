// Fichier: lib/models/medication_model.dart

class MedicationModel {
  final String id;
  final String name;
  final String description;
  final String form; // comprimé, sirop, etc.
  final String dosage;
  final String usage;
  final String contraindications; // Ajout du champ contraindications
  final String imageUrl;

  MedicationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.form,
    required this.dosage,
    required this.usage,
    this.contraindications = '', // Valeur par défaut pour contraindications
    this.imageUrl = '',
  });

  // Méthode pour créer une liste de médicaments fictifs pour les tests
  static List<MedicationModel> getMockMedications() {
    return [
      MedicationModel(
        id: '550e8400-e29b-41d4-a716-446655440001',
        name: 'Paracétamol',
        description: 'Médicament antalgique et antipyrétique',
        form: 'Comprimé',
        dosage: '500mg',
        usage: 'Traitement symptomatique des douleurs et de la fièvre',
        contraindications: 'Hypersensibilité au paracétamol, insuffisance hépatocellulaire sévère',
        imageUrl: 'assets/icone/medicament.png',
      ),
      MedicationModel(
        id: '550e8400-e29b-41d4-a716-446655440002',
        name: 'Ibuprofène',
        description: 'Anti-inflammatoire non stéroïdien',
        form: 'Comprimé',
        dosage: '400mg',
        usage: 'Traitement de la douleur et de l\'inflammation',
        contraindications: 'Grossesse à partir du 6ème mois, ulcère gastroduodénal en évolution',
        imageUrl: 'assets/icone/medicament.png',
      ),
      MedicationModel(
        id: '550e8400-e29b-41d4-a716-446655440003',
        name: 'Amoxicilline',
        description: 'Antibiotique de la famille des bêta-lactamines',
        form: 'Gélule',
        dosage: '500mg',
        usage: 'Traitement des infections bactériennes',
        contraindications: 'Hypersensibilité aux pénicillines, mononucléose infectieuse',
        imageUrl: 'assets/icone/medicament.png',
      ),
      MedicationModel(
        id: '550e8400-e29b-41d4-a716-446655440004',
        name: 'Doliprane',
        description: 'Médicament à base de paracétamol',
        form: 'Comprimé',
        dosage: '1000mg',
        usage: 'Traitement symptomatique des douleurs et de la fièvre',
        contraindications: 'Hypersensibilité au paracétamol, insuffisance hépatocellulaire sévère',
        imageUrl: 'assets/icone/medicament.png',
      ),
      MedicationModel(
        id: '550e8400-e29b-41d4-a716-446655440005',
        name: 'Efferalgan',
        description: 'Médicament à base de paracétamol',
        form: 'Comprimé effervescent',
        dosage: '500mg',
        usage: 'Traitement symptomatique des douleurs et de la fièvre',
        contraindications: 'Hypersensibilité au paracétamol, phénylcétonurie',
        imageUrl: 'assets/icone/medicament.png',
      ),
    ];
  }
}
