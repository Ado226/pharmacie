// Fichier: lib/services/api_service.dart
// Version simplifiée - Les fonctionnalités ont été migrées vers Clean Architecture
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/database_config.dart';

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

  // Token d'authentification
  String? _authToken;

  // Méthode pour définir un token d'authentification
  void setAuthToken(String token) {
    _authToken = token;
    _headers['Authorization'] = 'Bearer $token';
  }

  // Méthode pour retirer le token
  void clearAuthToken() {
    _authToken = null;
    _headers.remove('Authorization');
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

  // Méthode pour tester la connexion au backend Node.js
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${DatabaseConfig.apiUrl}/health'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== AUTHENTIFICATION ==========
  // Note: Utiliser AuthBloc et AuthRepository (Clean Architecture)

  // ========== COMMANDES (PRESCRIPTIONS) ==========
  // Note: Utiliser PrescriptionBloc et PrescriptionRepository (Clean Architecture)

  // Récupérer toutes les prescriptions
  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    try {
      final response = await get('client/commandes');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Créer une commande/ordonnance
  Future<Map<String, dynamic>> createCommande({
    required String typeCommande,
    required double latitude,
    required double longitude,
    List<Map<String, dynamic>>? produits,
    String? ordonnancePhotoUrl,
  }) async {
    try {
      final data = {
        'type_commande': typeCommande,
        'localisation_client_latitude': latitude,
        'localisation_client_longitude': longitude,
        'localisation_timestamp': DateTime.now().toIso8601String(),
      };

      if (produits != null && produits.isNotEmpty) {
        data['produits'] = produits;
      }

      if (ordonnancePhotoUrl != null) {
        data['ordonnance_photo_url'] = ordonnancePhotoUrl;
      }

      final response = await post('client/commandes', data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer toutes les commandes du client connecté
  Future<List<dynamic>> getCommandesClient() async {
    try {
      final response = await get('client/commandes');
      return response as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // Récupérer le statut d'une commande
  Future<Map<String, dynamic>?> getCommandeStatus(int commandeId) async {
    try {
      final response = await get('client/commandes/$commandeId/status');
      return response as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
