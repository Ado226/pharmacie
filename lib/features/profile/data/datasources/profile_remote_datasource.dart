// Fichier: lib/features/profile/data/datasources/profile_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';

class ProfileRemoteDatasource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  ProfileRemoteDatasource({
    required this.client,
    required this.sharedPreferences,
  });

  String? get _token => sharedPreferences.getString(ApiConfig.tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  /// Récupérer le profil
  Future<Map<String, dynamic>> getProfile() async {
    final response = await client.get(
      Uri.parse(ApiConfig.profilUrl),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la récupération du profil');
    }
  }

  /// Mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile({
    String? nom,
    String? prenom,
    String? adresse,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (nom != null) body['nom'] = nom;
    if (prenom != null) body['prenom'] = prenom;
    if (adresse != null) body['adresse'] = adresse;
    if (email != null) body['email'] = email;

    final response = await client.put(
      Uri.parse(ApiConfig.profilUrl),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la mise à jour du profil');
    }
  }

  /// Changer le mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String ancienPassword,
    required String nouveauPassword,
  }) async {
    final response = await client.put(
      Uri.parse('${ApiConfig.profilUrl}/password'),
      headers: _headers,
      body: json.encode({
        'ancien_password': ancienPassword,
        'nouveau_password': nouveauPassword,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors du changement de mot de passe');
    }
  }

  /// Supprimer le compte
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    final request = http.Request(
      'DELETE',
      Uri.parse('${ApiConfig.profilUrl}/account'),
    );
    request.headers.addAll(_headers);
    request.body = json.encode({'password': password});

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la suppression du compte');
    }
  }

  /// Historique des commandes
  Future<Map<String, dynamic>> getHistorique({int page = 1, int limit = 10}) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.profilUrl}/historique?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la récupération de l\'historique');
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await client.post(
        Uri.parse('${ApiConfig.authUrl}/client/logout'),
        headers: _headers,
      );
    } catch (e) {
      // Ignore les erreurs réseau lors de la déconnexion
    }

    // Nettoyer le stockage local
    await sharedPreferences.remove(ApiConfig.tokenKey);
    await sharedPreferences.remove(ApiConfig.userIdKey);
    await sharedPreferences.remove('refresh_token');
    await sharedPreferences.remove('user_data');
  }

  /// Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.authUrl}/client/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Sauvegarder les nouveaux tokens
      await sharedPreferences.setString(ApiConfig.tokenKey, data['accessToken']);
      if (data['refreshToken'] != null) {
        await sharedPreferences.setString('refresh_token', data['refreshToken']);
      }
      return data;
    } else {
      throw Exception('Session expirée, veuillez vous reconnecter');
    }
  }
}
