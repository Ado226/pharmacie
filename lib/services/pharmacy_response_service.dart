// Fichier: lib/services/pharmacy_response_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../models/pharmacy_response_api_model.dart';

class PharmacyResponseService {
  /// R??cup??rer les d??tails d'une commande avec les pharmacies proches
  static Future<CommandeDetailResponse> getCommandeDetails(int commandeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Token non trouv??. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/client/commandes/$commandeId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // DEBUG: Afficher la structure complète de la réponse
        print('🔍 DEBUG API Response /status:');
        print('   - Keys: ${data.keys.toList()}');
        print('   - Structure plate détectée: ${!data.containsKey('commande')}');
        print('   - Type de produits: ${data['produits'].runtimeType}');
        print('   - Nombre de produits: ${data['produits'] is List ? (data['produits'] as List).length : 'N/A'}');

        // NOUVEAU: Vérifier si reponses_existantes est présent
        print('   - reponses_existantes présent: ${data.containsKey('reponses_existantes')}');
        if (data.containsKey('reponses_existantes')) {
          print('   - Type reponses_existantes: ${data['reponses_existantes'].runtimeType}');
          print('   - Nombre reponses: ${data['reponses_existantes'] is List ? (data['reponses_existantes'] as List).length : 'N/A'}');
          if (data['reponses_existantes'] is List && (data['reponses_existantes'] as List).isNotEmpty) {
            print('   - Première réponse COMPLETE:');
            print('   ${json.encode((data['reponses_existantes'] as List)[0])}');
          }
        }

        // NOUVEAU: Vérifier pharmacies_proximite
        print('   - pharmacies_proximite présent: ${data.containsKey('pharmacies_proximite')}');
        if (data.containsKey('pharmacies_proximite')) {
          print('   - Nombre pharmacies: ${data['pharmacies_proximite'] is List ? (data['pharmacies_proximite'] as List).length : 'N/A'}');
        }

        print('   - AVANT de parser avec CommandeDetailResponse.fromJson');
        final result = CommandeDetailResponse.fromJson(data);
        print('   - APRES parsing - reponsesExistantes.length: ${result.reponsesExistantes.length}');
        return result;
      } else if (response.statusCode == 401) {
        throw Exception('Session expir??e. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la r??cup??ration des d??tails: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur r??seau: $e');
    }
  }

  /// R??cup??rer toutes les r??ponses des pharmacies pour une commande
  static Future<List<ReponsePharmacieApi>> getReponsesForCommande(int commandeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Token non trouv??. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/client/commandes/$commandeId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // L'endpoint /status retourne la structure complète avec les réponses
        // Extraire les réponses existantes du statut
        if (data['reponses_existantes'] != null) {
          final List<dynamic> reponsesData = data['reponses_existantes'];
          return reponsesData.map((json) => ReponsePharmacieApi.fromJson(json)).toList();
        }

        // Si pas de réponses, retourner liste vide
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Session expir??e. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la r??cup??ration des r??ponses: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur r??seau: $e');
    }
  }

  /// Cr??er une r??ponse pharmacie pour une commande
  static Future<ReponsePharmacieApi> createReponsePharmacieForCommande({
    required int commandeId,
    required int pharmacieId,
    required List<Map<String, dynamic>> produitsDisponibles,
    String? commentairePharmacae,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Token non trouv??. Veuillez vous connecter.');
      }

      final body = {
        'pharmacie_id': pharmacieId,
        'produits_disponibles': produitsDisponibles,
        'commentaire_pharmacie': commentairePharmacae,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/commandes/$commandeId/reponses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ReponsePharmacieApi.fromJson(data['reponse']);
      } else if (response.statusCode == 401) {
        throw Exception('Session expir??e. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la cr??ation de la r??ponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur r??seau: $e');
    }
  }

  /// Supprimer une r??ponse pharmacie
  static Future<void> deleteReponsePharmacie(int reponseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Token non trouv??. Veuillez vous connecter.');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/commandes/reponses/$reponseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Session expir??e. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la suppression: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur r??seau: $e');
    }
  }

  /// R??cup??rer la liste des commandes du client connect??
  static Future<List<Map<String, dynamic>>> getMesCommandes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        throw Exception('Token non trouv??. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/client/commandes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expir??e. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur lors de la r??cup??ration des commandes: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur r??seau: $e');
    }
  }
}
