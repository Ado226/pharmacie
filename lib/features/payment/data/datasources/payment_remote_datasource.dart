// Fichier: lib/features/payment/data/datasources/payment_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';

class PaymentRemoteDatasource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  PaymentRemoteDatasource({
    required this.client,
    required this.sharedPreferences,
  });

  String? get _token => sharedPreferences.getString(ApiConfig.tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Initier un paiement Mobile Money
  Future<Map<String, dynamic>> initierPaiement({
    required int commandeId,
    required String methode,
    String? numeroTelephone,
  }) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.paiementsUrl}/initier'),
      headers: _headers,
      body: jsonEncode({
        'commande_id': commandeId,
        'methode': methode,
        if (numeroTelephone != null) 'numero_telephone': numeroTelephone,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de l\'initiation du paiement');
    }
  }

  /// Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> verifierStatut(String reference) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.paiementsUrl}/statut/$reference'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la vérification');
    }
  }

  /// Récupérer l'historique des paiements
  Future<Map<String, dynamic>> getHistorique({int page = 1, int limit = 10}) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.paiementsUrl}/historique?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la récupération de l\'historique');
    }
  }

  /// Récupérer un paiement par ID
  Future<Map<String, dynamic>> getPaiementById(int paiementId) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.paiementsUrl}/$paiementId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Paiement non trouvé');
    }
  }

  /// Simuler la confirmation d'un paiement (pour tests)
  Future<Map<String, dynamic>> simulerConfirmation(int paiementId) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.paiementsUrl}/$paiementId/confirmer'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la confirmation');
    }
  }
}
