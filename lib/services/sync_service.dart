// Fichier: lib/services/sync_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart';
import '../services/supabase_config.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';

class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Services
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _localDbService = LocalDatabaseService();
  final SupabaseService _supabaseService = SupabaseService();

  // Clé pour stocker la date de dernière synchronisation
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Méthode pour obtenir la date de dernière synchronisation
  Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Méthode pour enregistrer la date de dernière synchronisation
  Future<void> _updateLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Méthode principale pour synchroniser les données
  Future<bool> synchronize() async {
    try {
      print('Début de la synchronisation des données...');
      
      // S'assurer que Supabase est initialisé
      await _supabaseService.initialize();
      
      // 1. Synchroniser les données modifiées localement vers le serveur
      await _syncLocalChangesToServer();
      
      // 2. Récupérer les nouvelles données du serveur
      await _syncServerChangesToLocal();
      
      // 3. Mettre à jour la date de dernière synchronisation
      await _updateLastSyncDate();
      
      print('Synchronisation terminée avec succès.');
      return true;
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
      return false;
    }
  }

  // Méthode pour synchroniser les modifications locales vers le serveur
  Future<void> _syncLocalChangesToServer() async {
    // 1. Synchroniser les médicaments modifiés
    final unsyncedMedications = await _localDbService.getUnsyncedData('medications');
    for (var medication in unsyncedMedications) {
      try {
        // Convertir les données en modèle
        final medicationModel = MedicationModel(
          id: medication['id'],
          name: medication['name'],
          description: medication['description'] ?? '',
          form: medication['form'] ?? 'Comprimé',
          dosage: medication['dosage'] ?? 'N/A',
          usage: medication['usage'] ?? 'N/A',
          contraindications: medication['contraindications'] ?? '',
          imageUrl: medication['image_url'] ?? '',
        );
        
        // Envoyer au serveur via Supabase
        try {
          await _supabaseService.client
              .from(SupabaseConfig.medicationsTable)
              .upsert({
                'id': medicationModel.id,
                'name': medicationModel.name,
                'description': medicationModel.description,
                'form': medicationModel.form,
                'dosage': medicationModel.dosage,
                'usage': medicationModel.usage,
                'contraindications': medicationModel.contraindications,
                'image_url': medicationModel.imageUrl,
              });
          
          // Marquer comme synchronisé
          await _localDbService.markAsSynced('medications', medication['id']);
          
          print('Médicament synchronisé: ${medication['name']}');
        } catch (e) {
          print('Erreur Supabase lors de la synchronisation du médicament: $e');
        }
      } catch (e) {
        print('Erreur lors de la synchronisation du médicament ${medication['id']}: $e');
      }
    }

    // 2. Synchroniser les ordonnances modifiées
    final unsyncedPrescriptions = await _localDbService.getUnsyncedData('prescriptions');
    for (var prescription in unsyncedPrescriptions) {
      try {
        // Récupérer l'ordonnance complète avec ses médicaments
        final prescriptionModel = await _localDbService.getPrescription(prescription['id']);
        if (prescriptionModel != null) {
          // Envoyer au serveur via Supabase
          await _apiService.createPrescription(prescriptionModel);
          
          // Marquer comme synchronisé
          await _localDbService.markAsSynced('prescriptions', prescription['id']);
          
          print('Ordonnance synchronisée: ${prescription['name']}');
        }
      } catch (e) {
        print('Erreur lors de la synchronisation de l\'ordonnance ${prescription['id']}: $e');
      }
    }
  }

  // Méthode pour récupérer les nouvelles données du serveur
  Future<void> _syncServerChangesToLocal() async {
    // 1. Récupérer la date de dernière synchronisation
    final lastSync = await getLastSyncDate();
    
    // 2. Récupérer les médicaments mis à jour depuis la dernière synchronisation
    try {
      final medications = await _apiService.getMedications();
      for (var medication in medications) {
        await _localDbService.insertMedication(medication);
        print('Médicament récupéré du serveur: ${medication.name}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des médicaments: $e');
    }
    
    // 3. Récupérer les ordonnances mises à jour depuis la dernière synchronisation
    try {
      final prescriptions = await _apiService.getPrescriptions();
      for (var prescription in prescriptions) {
        await _localDbService.insertPrescription(prescription);
        print('Ordonnance récupérée du serveur: ${prescription.name}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des ordonnances: $e');
    }
  }

  // Méthode pour synchroniser en arrière-plan
  Future<void> startBackgroundSync(Duration interval) async {
    Timer.periodic(interval, (timer) async {
      final result = await synchronize();
      if (result) {
        print('Synchronisation en arrière-plan réussie à ${DateTime.now()}');
      } else {
        print('Échec de la synchronisation en arrière-plan à ${DateTime.now()}');
      }
    });
  }
}
