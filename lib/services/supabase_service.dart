// Fichier: lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../services/supabase_config.dart';
import 'dart:async';
import 'dart:math';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Référence au client Supabase
  SupabaseClient? _supabaseClient;
  
  // Variable pour suivre l'état d'initialisation
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Getter pour accéder au client Supabase avec gestion des erreurs
  SupabaseClient get client {
    if (_supabaseClient == null) {
      throw Exception('Supabase client not initialized. Call initialize() first.');
    }
    return _supabaseClient!;
  }

  // Initialiser Supabase
  Future<void> initialize() async {
    // Si déjà initialisé ou en cours d'initialisation, ne rien faire
    if (_isInitialized) {
      print('SupabaseService: déjà initialisé');
      return;
    }
    
    if (_isInitializing) {
      print('SupabaseService: initialisation déjà en cours');
      return;
    }
    
    _isInitializing = true;
    
    try {
      // Initialiser Supabase directement
      print('SupabaseService: initialisation en cours...');
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      
      _supabaseClient = Supabase.instance.client;
      _isInitialized = true;
      print('SupabaseService: initialisé avec succès');
    } catch (e) {
      // Si l'erreur est due à une initialisation multiple, essayer de récupérer le client
      if (e.toString().contains('already initialized')) {
        print('SupabaseService: déjà initialisé ailleurs, récupération du client');
        try {
          _supabaseClient = Supabase.instance.client;
          _isInitialized = true;
        } catch (innerError) {
          print('SupabaseService: erreur lors de la récupération du client: $innerError');
          _isInitialized = false;
        }
      } else {
        print('SupabaseService: erreur d\'initialisation: $e');
        _isInitialized = false;
      }
    } finally {
      _isInitializing = false;
    }
  }

  // Méthode pour tester la connexion à Supabase
  Future<bool> testConnection() async {
    try {
      final response = await _supabaseClient
          ?.from(SupabaseConfig.prescriptionsTable)
          .select('id')
          .limit(1);
      
      print('Connexion à Supabase réussie!');
      return true;
    } catch (e) {
      print('Exception lors du test de connexion à Supabase: $e');
      return false;
    }
  }

  // Méthodes pour les prescriptions
  
  // Récupérer toutes les prescriptions
  Future<List<PrescriptionModel>> getPrescriptions() async {
    try {
      final response = await _supabaseClient
          ?.from(SupabaseConfig.prescriptionsTable)
          .select('*, ${SupabaseConfig.prescriptionMedicationsTable}(*, ${SupabaseConfig.medicationsTable}(*))')
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => _convertToPrescription(item)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des prescriptions: $e');
      return [];
    }
  }
  

  // Récupérer une prescription spécifique
  Future<PrescriptionModel?> getPrescription(String id) async {
    try {
      print('Récupération de la prescription avec ID: $id');
      final response = await _supabaseClient
          ?.from(SupabaseConfig.prescriptionsTable)
          .select('*, ${SupabaseConfig.prescriptionMedicationsTable}(*, ${SupabaseConfig.medicationsTable}(*))')
          .eq('id', id)
          .single();

      print('Réponse reçue de Supabase: $response');

      if (response != null) {
        final prescription = _convertToPrescription(response);
        print('Prescription convertie: ${prescription.name}, Nombre de médicaments: ${prescription.medications.length}');
        return prescription;
      } else {
        print('Aucune prescription trouvée avec cet ID');
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la prescription $id: $e');
      return null;
    }
  }
  
  // Vérifier si un médicament existe dans la base de données
  Future<bool> medicationExists(String id) async {
    try {
      final response = await _supabaseClient
          ?.from(SupabaseConfig.medicationsTable)
          .select('id')
          .eq('id', id)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Erreur lors de la vérification du médicament: $e');
      return false;
    }
  }
  
  // Insérer un médicament dans la base de données
  Future<bool> insertMedication(MedicationModel medication) async {
    try {
      await _supabaseClient
          ?.from(SupabaseConfig.medicationsTable)
          .insert({
            'id': medication.id,
            'name': medication.name,
            'description': medication.description,
            'form': medication.form,
            'dosage': medication.dosage,
            'usage': medication.usage,
            'contraindications': medication.contraindications,
            'image_url': medication.imageUrl,
          });
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'insertion du médicament: $e');
      return false;
    }
  }
  
  // Créer une nouvelle prescription
  Future<String> createPrescription(PrescriptionModel prescription) async {
    try {
      // Commencer une transaction Supabase
      // Note: Supabase ne supporte pas directement les transactions, mais nous pouvons utiliser des requêtes séquentielles
      
      // 0. Vérifier et insérer les médicaments s'ils n'existent pas
      for (var medicationItem in prescription.medications) {
        final medication = medicationItem.medication;
        final exists = await medicationExists(medication.id);
        
        if (!exists) {
          await insertMedication(medication);
        }
      }
      
      // 1. Insérer la prescription avec un UUID généré manuellement
      final uuid = _generateUuid();
      
      final prescriptionResponse = await _supabaseClient
          ?.from(SupabaseConfig.prescriptionsTable)
          .insert({
            'id': uuid,
            'patient_name': prescription.name,
            'created_at': prescription.createdAt.toIso8601String(),
            'status': 'en_attente',
          })
          .select('id')
          .single();
      
      // Récupérer l'ID généré
      final String prescriptionId = prescriptionResponse?['id'] ?? uuid;
      
      // 2. Insérer les médicaments de la prescription
      for (var medication in prescription.medications) {
        await _supabaseClient
            ?.from(SupabaseConfig.prescriptionMedicationsTable)
            .insert({
              'prescription_id': prescriptionId,
              'medication_id': medication.medication.id,
              'patient_type': medication.patientType.toString().split('.').last,
            });
      }
      
      return prescriptionId;
    } catch (e) {
      print('Erreur lors de la création de la prescription: $e');
      rethrow;
    }
  }
  
  // Méthode pour générer un UUID valide
  String _generateUuid() {
    // Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    // où x est n'importe quel caractère hexadécimal et y est l'un des 8, 9, A ou B
    final random = Random();
    final hexDigits = '0123456789abcdef';
    
    String generateHex(int length) {
      return List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
    }
    
    // Version 4 UUID (aléatoire)
    final uuid = '${generateHex(8)}-${generateHex(4)}-4${generateHex(3)}-'
        '${hexDigits[random.nextInt(4) + 8]}${generateHex(3)}-${generateHex(12)}';
    
    return uuid;
  }
  
  // Mettre à jour une prescription existante
  Future<bool> updatePrescription(PrescriptionModel prescription) async {
    try {
      // 1. Mettre à jour les informations de base de la prescription
      await _supabaseClient
          ?.from(SupabaseConfig.prescriptionsTable)
          .update({
            'patient_name': prescription.name,
            'created_at': prescription.createdAt.toIso8601String(),
          })
          .eq('id', prescription.id);
      
      // 2. Supprimer les médicaments existants
      await _supabaseClient
          ?.from(SupabaseConfig.prescriptionMedicationsTable)
          .delete()
          .eq('prescription_id', prescription.id);
      
      // 3. Insérer les nouveaux médicaments
      for (var medication in prescription.medications) {
        await _supabaseClient
            ?.from(SupabaseConfig.prescriptionMedicationsTable)
            .insert({
              'prescription_id': prescription.id,
              'medication_id': medication.medication.id,
              'patient_type': medication.patientType.toString().split('.').last,
            });
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la prescription: $e');
      return false;
    }
  }
  
  // Supprimer une prescription
  Future<bool> deletePrescription(String id) async {
    try {
      // 1. Supprimer les médicaments associés
      await _supabaseClient
          ?.from(SupabaseConfig.prescriptionMedicationsTable)
          .delete()
          .eq('prescription_id', id);
      
      // 2. Supprimer la prescription
      await _supabaseClient
          ?.from(SupabaseConfig.prescriptionsTable)
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la prescription: $e');
      return false;
    }
  }
  
  // Méthodes pour les réponses des pharmacies
  
  // Récupérer les réponses des pharmacies pour une prescription
  Future<List<dynamic>> getPharmacyResponses(String prescriptionId) async {
    try {
      final response = await _supabaseClient
          ?.from(SupabaseConfig.pharmacyResponsesTable)
          .select('*, ${SupabaseConfig.pharmaciesTable}(*), ${SupabaseConfig.medicationResponsesTable}(*)')
          .eq('prescription_id', prescriptionId);
      
      return response as List<dynamic>;
    } catch (e) {
      print('Erreur lors de la récupération des réponses pour la prescription $prescriptionId: $e');
      return [];
    }
  }
  
  // Méthodes utilitaires
  


  PrescriptionModel _convertToPrescription(Map<String, dynamic> data) {
    final List<PrescriptionMedicationItem> medications = [];

    print('Données de prescription: $data');

    // Traiter les médicaments s'ils sont présents
    if (data[SupabaseConfig.prescriptionMedicationsTable] != null) {
      final medicationsList = data[SupabaseConfig.prescriptionMedicationsTable] as List<dynamic>;
      print('Médicaments trouvés: ${medicationsList.length}');

      for (var med in medicationsList) {
        print('Données du médicament: $med');
        final medicationData = med[SupabaseConfig.medicationsTable];

        if (medicationData != null) {
          final medication = MedicationModel(
            id: medicationData['id'],
            name: medicationData['name'],
            description: medicationData['description'] ?? '',
            form: medicationData['form'],
            dosage: medicationData['dosage'],
            usage: medicationData['usage'],
            contraindications: medicationData['contraindications'] ?? '',
            imageUrl: medicationData['image_url'] ?? '',
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
        } else {
          print('Données du médicament nulles pour: $med');
        }
      }
    } else {
      print('Aucun médicament trouvé dans les données');
    }

    return PrescriptionModel(
      id: data['id'],
      name: data['patient_name'],
      createdAt: DateTime.parse(data['created_at']),
      medications: medications,
    );
  }

}
