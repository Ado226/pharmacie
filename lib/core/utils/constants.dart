// Fichier: lib/core/utils/constants.dart

import '../config/api_config.dart';

/// Constantes globales de l'application
class AppConstants {
  // API - Utilise la configuration centralisée
  // ⚠️ IMPORTANT: Pour changer l'URL de l'API, modifiez lib/core/config/api_config.dart
  static String get baseUrl => ApiConfig.baseUrl;
  static Duration get connectionTimeout => ApiConfig.connectionTimeout;
  static Duration get receiveTimeout => ApiConfig.receiveTimeout;

  // Cache
  static const String cacheBoxName = 'pharmacie_cache';
  static const Duration cacheExpiration = Duration(hours: 24);

  // Database
  static const String databaseName = 'pharmacie.db';
  static const int databaseVersion = 1;

  // Pagination
  static const int itemsPerPage = 20;

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
}

/// Messages d'erreur
class ErrorMessages {
  static const String noInternet = 'Pas de connexion internet';
  static const String serverError = 'Erreur serveur, veuillez réessayer';
  static const String cacheError = 'Erreur lors de la récupération des données locales';
  static const String unexpected = 'Une erreur inattendue s\'est produite';
  static const String validationError = 'Données invalides';
  static const String authError = 'Erreur d\'authentification';
}
