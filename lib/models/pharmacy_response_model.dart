// Fichier: lib/models/pharmacy_response_model.dart
import 'medication_model.dart';

class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.email = '',
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  // Méthode pour créer une liste de pharmacies fictives pour les tests
  static List<PharmacyModel> getMockPharmacies() {
    return [
      PharmacyModel(
        id: '1',
        name: 'Pharmacie Centrale',
        address: '15 Rue de la République, 75001 Paris',
        phone: '01 23 45 67 89',
        email: 'contact@pharmaciecentrale.fr',
        latitude: 48.856614,
        longitude: 2.3522219,
        imageUrl: 'assets/images/pharmacy1.jpg',
      ),
      PharmacyModel(
        id: '2',
        name: 'Pharmacie du Marché',
        address: '8 Place du Marché, 75002 Paris',
        phone: '01 23 45 67 90',
        email: 'contact@pharmaciemarche.fr',
        latitude: 48.865614,
        longitude: 2.3622219,
        imageUrl: 'assets/images/pharmacy2.jpg',
      ),
      PharmacyModel(
        id: '3',
        name: 'Pharmacie Saint-Michel',
        address: '25 Boulevard Saint-Michel, 75005 Paris',
        phone: '01 23 45 67 91',
        email: 'contact@pharmaciesaintmichel.fr',
        latitude: 48.846614,
        longitude: 2.3422219,
        imageUrl: 'assets/images/pharmacy3.jpg',
      ),
    ];
  }
}

enum AvailabilityStatus {
  available, // Tous les médicaments sont disponibles
  partiallyAvailable, // Certains médicaments sont disponibles
  unavailable, // Aucun médicament n'est disponible
}

class MedicationResponseItem {
  final MedicationModel medication;
  final double price;
  final bool available;
  final MedicationModel? alternative; // Médicament alternatif proposé si non disponible

  MedicationResponseItem({
    required this.medication,
    required this.price,
    required this.available,
    this.alternative,
  });
}

class PharmacyResponseModel {
  final String id;
  final String prescriptionId;
  final PharmacyModel pharmacy;
  final DateTime responseDate;
  final List<MedicationResponseItem> medicationResponses;
  final double totalPrice;
  final AvailabilityStatus availabilityStatus;
  final bool deliveryOption;
  final String? estimatedDeliveryTime;

  PharmacyResponseModel({
    required this.id,
    required this.prescriptionId,
    required this.pharmacy,
    required this.responseDate,
    required this.medicationResponses,
    required this.totalPrice,
    required this.availabilityStatus,
    required this.deliveryOption,
    this.estimatedDeliveryTime,
  });

  // Méthode pour calculer le nombre de médicaments disponibles
  int get availableMedicationsCount => medicationResponses.where((item) => item.available).length;

  // Méthode pour calculer le nombre total de médicaments
  int get totalMedicationsCount => medicationResponses.length;

  // Méthode pour calculer le pourcentage de disponibilité
  double get availabilityPercentage => totalMedicationsCount > 0 
      ? (availableMedicationsCount / totalMedicationsCount) * 100 
      : 0;

  // Méthode pour créer une liste de réponses de pharmacies fictives pour les tests
  static List<PharmacyResponseModel> getMockPharmacyResponses(String prescriptionId) {
    final pharmacies = PharmacyModel.getMockPharmacies();
    final medications = MedicationModel.getMockMedications();
    
    return [
      PharmacyResponseModel(
        id: '1',
        prescriptionId: prescriptionId,
        pharmacy: pharmacies[0],
        responseDate: DateTime.now().subtract(const Duration(hours: 2)),
        medicationResponses: [
          MedicationResponseItem(
            medication: medications[0],
            price: 5.99,
            available: true,
          ),
          MedicationResponseItem(
            medication: medications[1],
            price: 7.50,
            available: true,
          ),
          MedicationResponseItem(
            medication: medications[2],
            price: 12.30,
            available: false,
            alternative: medications[3],
          ),
        ],
        totalPrice: 25.79,
        availabilityStatus: AvailabilityStatus.partiallyAvailable,
        deliveryOption: true,
        estimatedDeliveryTime: '30 minutes',
      ),
      PharmacyResponseModel(
        id: '2',
        prescriptionId: prescriptionId,
        pharmacy: pharmacies[1],
        responseDate: DateTime.now().subtract(const Duration(hours: 1)),
        medicationResponses: [
          MedicationResponseItem(
            medication: medications[0],
            price: 6.20,
            available: true,
          ),
          MedicationResponseItem(
            medication: medications[1],
            price: 7.80,
            available: true,
          ),
          MedicationResponseItem(
            medication: medications[2],
            price: 11.90,
            available: true,
          ),
        ],
        totalPrice: 25.90,
        availabilityStatus: AvailabilityStatus.available,
        deliveryOption: false,
        estimatedDeliveryTime: null,
      ),
      PharmacyResponseModel(
        id: '3',
        prescriptionId: prescriptionId,
        pharmacy: pharmacies[2],
        responseDate: DateTime.now().subtract(const Duration(minutes: 30)),
        medicationResponses: [
          MedicationResponseItem(
            medication: medications[0],
            price: 5.80,
            available: true,
          ),
          MedicationResponseItem(
            medication: medications[1],
            price: 8.10,
            available: false,
            alternative: medications[4],
          ),
          MedicationResponseItem(
            medication: medications[2],
            price: 12.50,
            available: false,
            alternative: null,
          ),
        ],
        totalPrice: 26.40,
        availabilityStatus: AvailabilityStatus.partiallyAvailable,
        deliveryOption: true,
        estimatedDeliveryTime: '45 minutes',
      ),
    ];
  }
}
