// Fichier: lib/services/pharmacy_response_service.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/pharmacy_response_model.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';

class PharmacyResponseService {
  // Singleton pattern
  static final PharmacyResponseService _instance = PharmacyResponseService._internal();
  factory PharmacyResponseService() => _instance;
  PharmacyResponseService._internal();

  // Services
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _localDbService = LocalDatabaseService();

  // Méthode pour obtenir les réponses des pharmacies pour une ordonnance
  Future<List<PharmacyResponseModel>> getPharmacyResponses(String prescriptionId) async {
    // D'abord, récupérer les données locales pour un affichage immédiat
    List<PharmacyResponseModel> localResponses = await _getPharmacyResponsesFromLocalDb(prescriptionId);
    
    try {
      // Ensuite, essayer de récupérer les données depuis le serveur pour les actualiser
      final data = await _apiService.get('pharmacy_responses?prescription_id=$prescriptionId');
      final List<PharmacyResponseModel> serverResponses = _convertToPharmacyResponses(data);
      
      // Sauvegarder les réponses dans la base de données locale
      for (var response in serverResponses) {
        await _savePharmacyResponseLocally(response);
      }
      
      // Si on a réussi à récupérer des données du serveur, les retourner
      if (serverResponses.isNotEmpty) {
        return serverResponses;
      }
    } catch (e) {
      print('Erreur lors de la récupération des réponses des pharmacies depuis le serveur: $e');
      // En cas d'erreur, on continue avec les données locales
    }
    
    // Retourner les données locales (soit parce qu'il n'y a pas de données serveur, 
    // soit parce que la récupération a échoué)
    return localResponses;
  }

  // Méthode pour convertir les données JSON en modèles PharmacyResponseModel
  List<PharmacyResponseModel> _convertToPharmacyResponses(dynamic data) {
    if (data == null || !(data is List)) return [];
    
    return (data as List).map((item) {
      return PharmacyResponseModel(
        id: item['id'],
        prescriptionId: item['prescription_id'],
        pharmacy: PharmacyModel(
          id: item['pharmacy']['id'],
          name: item['pharmacy']['name'],
          address: item['pharmacy']['address'],
          phone: item['pharmacy']['phone'],
          email: item['pharmacy']['email'] ?? '',
          latitude: item['pharmacy']['latitude'],
          longitude: item['pharmacy']['longitude'],
          imageUrl: item['pharmacy']['image_url'],
        ),
        responseDate: DateTime.parse(item['response_date']),
        medicationResponses: (item['medication_responses'] as List).map((medItem) {
          return MedicationResponseItem(
            medication: _convertToMedication(medItem['medication']),
            price: medItem['price'].toDouble(),
            available: medItem['available'],
            alternative: medItem['alternative'] != null 
                ? _convertToMedication(medItem['alternative']) 
                : null,
          );
        }).toList(),
        totalPrice: item['total_price'].toDouble(),
        availabilityStatus: _convertToAvailabilityStatus(item['availability_status']),
        deliveryOption: item['delivery_option'],
        estimatedDeliveryTime: item['estimated_delivery_time'],
      );
    }).toList();
  }

  // Méthode pour convertir les données JSON en modèle MedicationModel
  MedicationModel _convertToMedication(Map<String, dynamic> data) {
    return MedicationModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      form: data['form'] ?? 'Comprimé',
      dosage: data['dosage'] ?? 'N/A',
      usage: data['usage'] ?? 'N/A',
      imageUrl: data['image_url'] ?? '',
    );
  }

  // Méthode pour convertir une chaîne en AvailabilityStatus
  AvailabilityStatus _convertToAvailabilityStatus(String status) {
    switch (status) {
      case 'available':
        return AvailabilityStatus.available;
      case 'partially_available':
        return AvailabilityStatus.partiallyAvailable;
      case 'unavailable':
        return AvailabilityStatus.unavailable;
      default:
        return AvailabilityStatus.unavailable;
    }
  }

  // Méthode pour convertir un AvailabilityStatus en chaîne
  String _convertFromAvailabilityStatus(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.available:
        return 'available';
      case AvailabilityStatus.partiallyAvailable:
        return 'partially_available';
      case AvailabilityStatus.unavailable:
        return 'unavailable';
    }
  }

  // Méthode pour sauvegarder une réponse de pharmacie dans la base de données locale
  Future<void> _savePharmacyResponseLocally(PharmacyResponseModel response) async {
    final db = await _localDbService.database;
    
    // 1. Sauvegarder la pharmacie
    await db.insert(
      'pharmacies',
      {
        'id': response.pharmacy.id,
        'name': response.pharmacy.name,
        'address': response.pharmacy.address,
        'phone': response.pharmacy.phone,
        'email': response.pharmacy.email,
        'latitude': response.pharmacy.latitude,
        'longitude': response.pharmacy.longitude,
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // 2. Sauvegarder la réponse de la pharmacie
    final responseId = await db.insert(
      'pharmacy_responses',
      {
        'prescription_id': response.prescriptionId,
        'pharmacy_id': response.pharmacy.id,
        'response_date': response.responseDate.toIso8601String(),
        'total_price': response.totalPrice,
        'availability_status': _convertFromAvailabilityStatus(response.availabilityStatus),
        'delivery_option': response.deliveryOption ? 1 : 0,
        'estimated_delivery_time': response.estimatedDeliveryTime,
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // 3. Sauvegarder les détails de la réponse (médicaments)
    for (var medResponse in response.medicationResponses) {
      await db.insert(
        'pharmacy_response_details',
        {
          'response_id': responseId,
          'medication_id': medResponse.medication.id,
          'price': medResponse.price,
          'available': medResponse.available ? 1 : 0,
          'alternative_id': medResponse.alternative?.id,
          'sync_status': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Méthode pour récupérer les réponses des pharmacies depuis la base de données locale
  Future<List<PharmacyResponseModel>> _getPharmacyResponsesFromLocalDb(String prescriptionId) async {
    final db = await _localDbService.database;
    
    // 1. Récupérer les réponses pour cette ordonnance
    final List<Map<String, dynamic>> responseMaps = await db.query(
      'pharmacy_responses',
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
    );
    
    List<PharmacyResponseModel> responses = [];
    
    for (var responseMap in responseMaps) {
      final int responseId = responseMap['id'];
      final String pharmacyId = responseMap['pharmacy_id'];
      
      // 2. Récupérer les informations de la pharmacie
      final List<Map<String, dynamic>> pharmacyMaps = await db.query(
        'pharmacies',
        where: 'id = ?',
        whereArgs: [pharmacyId],
      );
      
      if (pharmacyMaps.isEmpty) continue;
      
      final pharmacyMap = pharmacyMaps.first;
      
      // 3. Récupérer les détails de la réponse (médicaments)
      final List<Map<String, dynamic>> detailMaps = await db.query(
        'pharmacy_response_details',
        where: 'response_id = ?',
        whereArgs: [responseId],
      );
      
      List<MedicationResponseItem> medicationResponses = [];
      
      for (var detailMap in detailMaps) {
        final String medicationId = detailMap['medication_id'];
        final String? alternativeId = detailMap['alternative_id'];
        
        // Récupérer le médicament
        final medication = await _localDbService.getMedication(medicationId);
        if (medication == null) continue;
        
        // Vérifier que le médicament a tous les champs requis
        final validMedication = MedicationModel(
          id: medication.id,
          name: medication.name,
          description: medication.description,
          form: medication.form,
          dosage: medication.dosage,
          usage: medication.usage,
          imageUrl: medication.imageUrl,
        );
        
        // Récupérer l'alternative si elle existe
        MedicationModel? alternative;
        if (alternativeId != null) {
          final altMed = await _localDbService.getMedication(alternativeId);
          if (altMed != null) {
            // Vérifier que l'alternative a tous les champs requis
            alternative = MedicationModel(
              id: altMed.id,
              name: altMed.name,
              description: altMed.description,
              form: altMed.form,
              dosage: altMed.dosage,
              usage: altMed.usage,
              imageUrl: altMed.imageUrl,
            );
          }
        }
        
        medicationResponses.add(MedicationResponseItem(
          medication: validMedication,
          price: detailMap['price'],
          available: detailMap['available'] == 1,
          alternative: alternative,
        ));
      }
      
      // 4. Créer le modèle de réponse de pharmacie
      responses.add(PharmacyResponseModel(
        id: responseId.toString(),
        prescriptionId: prescriptionId,
        pharmacy: PharmacyModel(
          id: pharmacyMap['id'],
          name: pharmacyMap['name'],
          address: pharmacyMap['address'],
          phone: pharmacyMap['phone'],
          email: pharmacyMap['email'] ?? '',
          latitude: pharmacyMap['latitude'],
          longitude: pharmacyMap['longitude'],
          imageUrl: pharmacyMap['image_url'],
        ),
        responseDate: DateTime.parse(responseMap['response_date']),
        medicationResponses: medicationResponses,
        totalPrice: responseMap['total_price'],
        availabilityStatus: _convertToAvailabilityStatus(responseMap['availability_status']),
        deliveryOption: responseMap['delivery_option'] == 1,
        estimatedDeliveryTime: responseMap['estimated_delivery_time'],
      ));
    }
    
    return responses;
  }

  // Méthode pour sélectionner une pharmacie et confirmer la commande
  Future<bool> selectPharmacy(String responseId) async {
    try {
      // Envoyer la sélection au serveur
      await _apiService.post('pharmacy_responses/$responseId/select', {});
      return true;
    } catch (e) {
      print('Erreur lors de la sélection de la pharmacie: $e');
      return false;
    }
  }

  // Méthode pour obtenir des réponses fictives (pour les tests)
  Future<List<PharmacyResponseModel>> getMockPharmacyResponses(String prescriptionId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));
    return PharmacyResponseModel.getMockPharmacyResponses(prescriptionId);
  }
}
