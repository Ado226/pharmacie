// Fichier: lib/features/evaluations/data/datasources/evaluation_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';

class EvaluationRemoteDatasource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  EvaluationRemoteDatasource({
    required this.client,
    required this.sharedPreferences,
  });

  String? get _token => sharedPreferences.getString(ApiConfig.tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Créer une évaluation
  Future<Map<String, dynamic>> createEvaluation({
    required int pharmacieId,
    required int commandeId,
    required int note,
    String? commentaire,
  }) async {
    final response = await client.post(
      Uri.parse(ApiConfig.evaluationsUrl),
      headers: _headers,
      body: jsonEncode({
        'pharmacie_id': pharmacieId,
        'commande_id': commandeId,
        'note': note,
        if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la création de l\'évaluation');
    }
  }

  /// Récupérer mes évaluations
  Future<Map<String, dynamic>> getMesEvaluations({int page = 1, int limit = 10}) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.evaluationsUrl}/mes?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la récupération des évaluations');
    }
  }

  /// Récupérer les évaluations d'une pharmacie
  Future<Map<String, dynamic>> getEvaluationsPharmacie(int pharmacieId, {int page = 1, int limit = 10}) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.evaluationsUrl}/pharmacie/$pharmacieId?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la récupération des évaluations');
    }
  }

  /// Modifier une évaluation
  Future<Map<String, dynamic>> updateEvaluation({
    required int evaluationId,
    required int note,
    String? commentaire,
  }) async {
    final response = await client.put(
      Uri.parse('${ApiConfig.evaluationsUrl}/$evaluationId'),
      headers: _headers,
      body: jsonEncode({
        'note': note,
        if (commentaire != null) 'commentaire': commentaire,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la modification');
    }
  }

  /// Supprimer une évaluation
  Future<void> deleteEvaluation(int evaluationId) async {
    final response = await client.delete(
      Uri.parse('${ApiConfig.evaluationsUrl}/$evaluationId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la suppression');
    }
  }

  /// Vérifier si une commande a déjà été évaluée
  Future<Map<String, dynamic>?> getEvaluationByCommande(int commandeId) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.evaluationsUrl}/commande/$commandeId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la vérification');
    }
  }
}
