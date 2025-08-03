// Fichier: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pharmacie/services/supabase_config.dart';
import '../services/database_config.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../services/local_database_service.dart'; // Importer le service de base de données locale
import '../services/supabase_service.dart'; // Importer le service Supabase

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Headers pour les requêtes HTTP
  Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Méthode pour définir un token d'authentification
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // Méthode générique pour effectuer une requête GET
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${DatabaseConfig.apiUrl}/$endpoint'),
        headers: _headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la requête GET: $e');
      rethrow;
    }
  }

  // Méthode générique pour effectuer une requête POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${DatabaseConfig.apiUrl}/$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la requête POST: $e');
      rethrow;
    }
  }

  // Méthode générique pour effectuer une requête PUT
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${DatabaseConfig.apiUrl}/$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la requête PUT: $e');
      rethrow;
    }
  }

  // Méthode générique pour effectuer une requête DELETE
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('${DatabaseConfig.apiUrl}/$endpoint'),
        headers: _headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('Erreur lors de la requête DELETE: $e');
      rethrow;
    }
  }

  // Méthode pour gérer les réponses HTTP
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur HTTP: ${response.statusCode}, ${response.body}');
    }
  }

  // Méthode pour tester la connexion à la base de données
  Future<bool> testConnection() async {
    try {
      // Utiliser le service Supabase pour tester la connexion
      final supabaseService = SupabaseService();
      return await supabaseService.testConnection();
    } catch (e) {
      print('Erreur lors du test de connexion: $e');
      return false;
    }
  }

  // Méthodes spécifiques pour les ordonnances
  Future<List<PrescriptionModel>> getPrescriptions() async {
    try {
      // Utiliser le service Supabase pour récupérer les prescriptions
      final supabaseService = SupabaseService();
      return await supabaseService.getPrescriptions();
    } catch (e) {
      print('Erreur lors de la récupération des données depuis le serveur: $e');
      // En cas d'erreur, retourner une liste vide au lieu de planter l'application
      return [];
    }
  }

  Future<PrescriptionModel?> getPrescription(String id) async {
    try {
      // Utiliser le service Supabase pour récupérer une prescription spécifique
      final supabaseService = SupabaseService();
      return await supabaseService.getPrescription(id);
    } catch (e) {
      print('Erreur lors de la récupération de la prescription $id: $e');
      // En cas d'erreur, retourner null au lieu de planter l'application
      return null;
    }
  }

  Future<String> createPrescription(PrescriptionModel prescription) async {
    try {
      // Utiliser le service Supabase pour créer une prescription
      final supabaseService = SupabaseService();
      final prescriptionId = await supabaseService.createPrescription(prescription);
      
      // Sauvegarder l'ordonnance localement
      final LocalDatabaseService _localDbService = LocalDatabaseService();
      await _localDbService.insertPrescription(prescription);
      
      return prescriptionId;
    } catch (e) {
      print('Erreur lors de la création de l\'ordonnance: $e');
      
      // En cas d'erreur, sauvegarder quand même localement
      final LocalDatabaseService _localDbService = LocalDatabaseService();
      await _localDbService.insertPrescription(prescription);
      
      return prescription.id;
    }
  }

  Future<bool> updatePrescription(String id, PrescriptionModel prescription) async {
    try {
      // Utiliser le service Supabase pour mettre à jour une prescription
      final supabaseService = SupabaseService();
      final success = await supabaseService.updatePrescription(prescription);
      
      if (success) {
        // Mettre à jour l'ordonnance localement
        final LocalDatabaseService _localDbService = LocalDatabaseService();
        await _localDbService.updatePrescription(prescription);
      }
      
      return success;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'ordonnance: $e');
      return false;
    }
  }

  Future<bool> deletePrescription(String id) async {
    try {
      // Utiliser le service Supabase pour supprimer une prescription
      final supabaseService = SupabaseService();
      final success = await supabaseService.deletePrescription(id);
      
      if (success) {
        // Supprimer l'ordonnance localement
        final LocalDatabaseService _localDbService = LocalDatabaseService();
        await _localDbService.deletePrescription(id);
      }
      
      return success;
    } catch (e) {
      print('Erreur lors de la suppression de l\'ordonnance: $e');
      return false;
    }
  }

  // Méthodes spécifiques pour les médicaments
  Future<List<MedicationModel>> getMedications() async {
    try {
      // Utiliser le service Supabase pour récupérer les médicaments
      final supabaseService = SupabaseService();
      final response = await supabaseService.client
          .from(SupabaseConfig.medicationsTable)
          .select();
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => MedicationModel(
        id: item['id'],
        name: item['name'],
        description: item['description'] ?? '',
        form: item['form'] ?? 'Comprimé',
        dosage: item['dosage'] ?? 'N/A',
        usage: item['usage'] ?? 'N/A',
        contraindications: item['contraindications'] ?? '',
        imageUrl: item['image_url'] ?? '',
      )).toList();
    } catch (e) {
      print('Erreur lors de la récupération des médicaments: $e');
      return [];
    }
  }

  Future<MedicationModel?> getMedication(String id) async {
    try {
      // Utiliser le service Supabase pour récupérer un médicament spécifique
      final supabaseService = SupabaseService();
      final response = await supabaseService.client
          .from(SupabaseConfig.medicationsTable)
          .select()
          .eq('id', id)
          .single();
      
      final item = response;
      return MedicationModel(
        id: item['id'],
        name: item['name'],
        description: item['description'] ?? '',
        form: item['form'] ?? 'Comprimé',
        dosage: item['dosage'] ?? 'N/A',
        usage: item['usage'] ?? 'N/A',
        contraindications: item['contraindications'] ?? '',
        imageUrl: item['image_url'] ?? '',
      );
    } catch (e) {
      print('Erreur lors de la récupération du médicament $id: $e');
      return null;
    }
  }

  // Méthodes pour les réponses des pharmacies
  Future<List<dynamic>> getPharmacyResponses(String prescriptionId) async {
    try {
      // Utiliser le service Supabase pour récupérer les réponses des pharmacies
      final supabaseService = SupabaseService();
      return await supabaseService.getPharmacyResponses(prescriptionId);
    } catch (e) {
      print('Erreur lors de la récupération des réponses des pharmacies: $e');
      return [];
    }
  }

  // Méthodes de conversion
  Map<String, dynamic> _convertFromPrescription(PrescriptionModel prescription) {
    return {
      'id': prescription.id,
      'name': prescription.name,
      'created_at': prescription.createdAt.toIso8601String(),
      'medications': prescription.medications.map((med) => {
        'medication': {
          'id': med.medication.id,
          'name': med.medication.name,
          'form': med.medication.form,
          'dosage': med.medication.dosage,
          'usage': med.medication.usage,
          'contraindications': med.medication.contraindications,
        },
        'patient_type': med.patientType.toString().split('.').last,
      }).toList(),
    };
  }

  PrescriptionModel _convertToPrescription(Map<String, dynamic> data) {
    List<PrescriptionMedicationItem> medications = [];
    
    if (data['medications'] != null) {
      for (var med in data['medications']) {
        final medication = MedicationModel(
          id: med['medication']['id'],
          name: med['medication']['name'],
          description: med['medication']['description'] ?? '',
          form: med['medication']['form'],
          dosage: med['medication']['dosage'],
          usage: med['medication']['usage'],
          contraindications: med['medication']['contraindications'] ?? '',
          imageUrl: med['medication']['image_url'] ?? '',
        );
        
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
    
    return PrescriptionModel(
      id: data['id'],
      name: data['name'],
      createdAt: DateTime.parse(data['created_at']),
      medications: medications,
    );
  }
}
