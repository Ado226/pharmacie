// Fichier: lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/error/exceptions.dart';
import '../../../../core/config/api_config.dart';
import '../models/auth_result_model.dart';

/// Interface du DataSource distant (API Node.js)
abstract class AuthRemoteDataSource {
  Future<AuthResultModel> registerClient({
    required String numero,
    required String password,
    String? nom,
    String? prenom,
  });

  Future<AuthResultModel> loginClient({
    required String numero,
    required String password,
  });

  Future<AuthResultModel> loginAdmin({
    required String email,
    required String motDePasse,
  });
}

/// Implémentation avec le backend Node.js
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client httpClient;
  final String baseUrl;

  AuthRemoteDataSourceImpl({
    required this.httpClient,
    this.baseUrl = ApiConfig.baseUrl,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Future<AuthResultModel> registerClient({
    required String numero,
    required String password,
    String? nom,
    String? prenom,
  }) async {
    try {
      final body = <String, dynamic>{
        'numero': numero,
        'password': password,
      };
      if (nom != null && nom.isNotEmpty) body['nom'] = nom;
      if (prenom != null && prenom.isNotEmpty) body['prenom'] = prenom;

      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/client/register'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResultModel.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw ServerException(error['error'] ?? 'Erreur lors de l\'inscription');
      } else {
        throw ServerException('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('Erreur lors de l\'inscription: $e');
    }
  }

  @override
  Future<AuthResultModel> loginClient({
    required String numero,
    required String password,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/client/login'),
        headers: _headers,
        body: json.encode({
          'numero': numero,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResultModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Numéro ou mot de passe incorrect');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw ServerException(error['error'] ?? 'Erreur de connexion');
      } else {
        throw ServerException('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthenticationException) {
        rethrow;
      }
      throw ServerException('Erreur lors de la connexion: $e');
    }
  }

  @override
  Future<AuthResultModel> loginAdmin({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await httpClient.post(
        Uri.parse('$baseUrl/auth/admin/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'mot_de_passe': motDePasse,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResultModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Email ou mot de passe incorrect');
      } else {
        throw ServerException('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      if (e is ServerException || e is NetworkException || e is AuthenticationException) {
        rethrow;
      }
      throw ServerException('Erreur lors de la connexion admin: $e');
    }
  }
}
