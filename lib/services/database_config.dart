// Fichier: lib/services/database_config.dart
// Configuration pour la connexion à la base de données MySQL sur cPanel

import '../core/config/api_config.dart';

/// Configuration de la base de données MySQL
///
/// ⚠️ NOTE: Ce fichier est conservé pour la compatibilité avec le code legacy.
/// Pour l'URL de l'API, utilisez directement ApiConfig.baseUrl
class DatabaseConfig {
  // Informations de connexion à la base de données MySQL sur cPanel
  static const String host = 'localhost'; // À remplacer par l'hôte de votre base de données
  static const int port = 3306; // Port MySQL standard
  static const String user = 'cp2575543p44_pharmacie'; // À remplacer par votre nom d'utilisateur
  static const String password = 'Cf}VJfweHEz,'; // À remplacer par votre mot de passe
  static const String db = 'cp2575543p44_pharmacie'; // À remplacer par le nom de votre base de données

  // URL de l'API pour les requêtes HTTP (utilise la configuration centralisée)
  // ⚠️ IMPORTANT: Pour changer l'URL de l'API, modifiez lib/core/config/api_config.dart
  static String get apiUrl => ApiConfig.baseUrl;
}
