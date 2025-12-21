// Data Layer - Remote Data Source
// Gère les appels HTTP vers l'API backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../models/commande_detail_model.dart';
import '../models/reponse_pharmacie_model.dart';

abstract class PharmacyResponseRemoteDataSource {
  /// Récupérer les détails complets d'une commande
  Future<CommandeDetailModel> getCommandeDetails(int commandeId);

  /// Récupérer uniquement les réponses pour une commande
  Future<List<ReponsePharmacieModel>> getReponsesForCommande(int commandeId);

  /// Créer une nouvelle réponse pharmacie
  Future<ReponsePharmacieModel> createReponsePharmacieForCommande({
    required int commandeId,
    required int pharmacieId,
    required List<Map<String, dynamic>> produitsDisponibles,
    String? commentairePharmacie,
  });

  /// Supprimer une réponse pharmacie
  Future<void> deleteReponsePharmacie(int reponseId);
}

class PharmacyResponseRemoteDataSourceImpl implements PharmacyResponseRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  PharmacyResponseRemoteDataSourceImpl({
    required this.client,
    required this.sharedPreferences,
  });

  /// Obtenir le token JWT stocké
  String? _getToken() {
    return sharedPreferences.getString(ApiConfig.tokenKey);
  }

  /// Construire les headers avec authentification
  Map<String, String> _getHeaders() {
    final token = _getToken();
    if (token == null) {
      throw Exception('Token non trouvé. Veuillez vous connecter.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<CommandeDetailModel> getCommandeDetails(int commandeId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/commandes/$commandeId/detail');

    final response = await client.get(
      url,
      headers: _getHeaders(),
    ).timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CommandeDetailModel.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else if (response.statusCode == 404) {
      throw Exception('Commande non trouvée.');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  @override
  Future<List<ReponsePharmacieModel>> getReponsesForCommande(int commandeId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/commandes/$commandeId/reponses');

    final response = await client.get(
      url,
      headers: _getHeaders(),
    ).timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((r) => ReponsePharmacieModel.fromJson(r)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else if (response.statusCode == 404) {
      throw Exception('Commande non trouvée.');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  @override
  Future<ReponsePharmacieModel> createReponsePharmacieForCommande({
    required int commandeId,
    required int pharmacieId,
    required List<Map<String, dynamic>> produitsDisponibles,
    String? commentairePharmacie,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/commandes/$commandeId/reponses');

    final body = {
      'pharmacie_id': pharmacieId,
      'produits_disponibles': produitsDisponibles,
      if (commentairePharmacie != null) 'commentaire_pharmacie': commentairePharmacie,
    };

    final response = await client.post(
      url,
      headers: _getHeaders(),
      body: json.encode(body),
    ).timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return ReponsePharmacieModel.fromJson(data['reponse'] ?? data);
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else if (response.statusCode == 400) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Données invalides.');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteReponsePharmacie(int reponseId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/commandes/reponses/$reponseId');

    final response = await client.delete(
      url,
      headers: _getHeaders(),
    ).timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else if (response.statusCode == 404) {
      throw Exception('Réponse non trouvée.');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }
}
