// Fichier: lib/features/auth/data/datasources/auth_local_datasource.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';

/// Interface du DataSource local (SharedPreferences)
abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> getCachedToken();
  Future<void> cacheUser(Map<String, dynamic> user);
  Future<Map<String, dynamic>?> getCachedUser();
  Future<void> clearToken();
  Future<void> clearAll();
  Future<bool> isAuthenticated();
}

/// Implémentation avec SharedPreferences
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String TOKEN_KEY = 'auth_token';
  static const String USER_KEY = 'cached_user';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheToken(String token) async {
    try {
      await sharedPreferences.setString(TOKEN_KEY, token);
    } catch (e) {
      throw CacheException('Erreur lors de la sauvegarde du token: $e');
    }
  }

  @override
  Future<String?> getCachedToken() async {
    try {
      return sharedPreferences.getString(TOKEN_KEY);
    } catch (e) {
      throw CacheException('Erreur lors de la récupération du token: $e');
    }
  }

  @override
  Future<void> cacheUser(Map<String, dynamic> user) async {
    try {
      final userJson = json.encode(user); // Convertir en JSON string
      await sharedPreferences.setString(USER_KEY, userJson);
    } catch (e) {
      throw CacheException('Erreur lors de la sauvegarde de l\'utilisateur: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedUser() async {
    try {
      final userString = sharedPreferences.getString(USER_KEY);
      if (userString == null) return null;
      return json.decode(userString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await sharedPreferences.remove(TOKEN_KEY);
    } catch (e) {
      throw CacheException('Erreur lors de la suppression du token: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await sharedPreferences.remove(TOKEN_KEY);
      await sharedPreferences.remove(USER_KEY);
    } catch (e) {
      throw CacheException('Erreur lors de la suppression des données: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await getCachedToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
