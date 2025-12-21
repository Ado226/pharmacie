// Fichier: lib/core/config/api_config.dart

/// Configuration centralisée de l'API backend Node.js
///
/// ⚠️ CONFIGURATION IMPORTANTE ⚠️
/// Pour changer l'adresse de l'API, modifiez UNIQUEMENT les valeurs ci-dessous.
/// Tous les services et vues utilisent cette configuration centralisée.
///
/// Exemples de configuration selon votre environnement:
/// - Téléphone physique : '192.168.11.101' (adresse IP de votre PC)
/// - Windows/Web : 'localhost'
/// - Émulateur Android : '10.0.2.2' (pointe vers localhost de votre PC)
/// - Production : 'api.votre-domaine.com'
class ApiConfig {
  // ============================================================================
  // 🔧 CONFIGURATION PRINCIPALE - MODIFIEZ ICI UNIQUEMENT
  // ============================================================================

  /// Hôte de l'API (IP ou domaine)
  /// - Production : 'api.pharmacie.logicieels.cloud'
  /// - Local : '192.168.11.151'
  static const String baseHost = 'api.pharmacie.logicieels.cloud';

  /// Port de l'API (vide pour utiliser le port par défaut 443/80)
  /// - Production : '' (vide, Nginx gère le port)
  /// - Local : '5000'
  static const String basePort = '';

  /// Protocole (http ou https)
  /// - Production : 'https'
  /// - Local : 'http'
  static const String scheme = 'https';

  // ============================================================================
  // 📡 URLs GÉNÉRÉES AUTOMATIQUEMENT - NE PAS MODIFIER
  // ============================================================================

  /// URL de base complète de l'API
  /// Pour production (sans port): https://api.pharmacie.logicieels.cloud/api
  /// Pour local (avec port): http://192.168.11.151:5000/api
  static const String baseUrl = basePort == ''
      ? '$scheme://$baseHost/api'
      : '$scheme://$baseHost:$basePort/api';

  /// URL de base pour les ressources (images, fichiers)
  static const String resourceUrl = basePort == ''
      ? '$scheme://$baseHost'
      : '$scheme://$baseHost:$basePort';

  // URLs spécifiques des endpoints
  static const String authUrl = '$baseUrl/auth';
  static const String commandesUrl = '$baseUrl/client/commandes';
  static const String pharmaciesUrl = '$baseUrl/admin/pharmacies';
  static const String produitsUrl = '$baseUrl/admin/produits';

  // Nouvelles URLs pour les fonctionnalités ajoutées
  static const String profilUrl = '$baseUrl/client/profil';
  static const String paiementsUrl = '$baseUrl/client/paiements';
  static const String notificationsUrl = '$baseUrl/client/notifications';
  static const String evaluationsUrl = '$baseUrl/client/evaluations';
  static const String ticketsUrl = '$baseUrl/client/tickets';

  // ============================================================================
  // ⏱️ TIMEOUTS
  // ============================================================================

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ============================================================================
  // 🔑 CLÉS DE STOCKAGE LOCAL
  // ============================================================================

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';

  // ============================================================================
  // 🛠️ MÉTHODES UTILITAIRES
  // ============================================================================

  /// Construit une URL complète pour une ressource (image, fichier)
  ///
  /// Exemple:
  /// ```dart
  /// String imageUrl = ApiConfig.buildResourceUrl('/uploads/images/photo.jpg');
  /// // Résultat: http://192.168.11.101:5000/uploads/images/photo.jpg
  /// ```
  static String buildResourceUrl(String path) {
    // Nettoie le path pour éviter les doubles slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$resourceUrl/$cleanPath';
  }

  /// Construit une URL complète pour un endpoint de l'API
  ///
  /// Exemple:
  /// ```dart
  /// String endpoint = ApiConfig.buildApiUrl('/custom/endpoint');
  /// // Résultat: http://192.168.11.101:5000/api/custom/endpoint
  /// ```
  static String buildApiUrl(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }

  /// Vérifie si une URL est déjà complète (commence par http:// ou https://)
  static bool isCompleteUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Construit une URL d'image en gérant les cas où l'URL est déjà complète
  ///
  /// Exemple:
  /// ```dart
  /// String url1 = ApiConfig.buildImageUrl('/uploads/photo.jpg');
  /// // Résultat: http://192.168.11.101:5000/uploads/photo.jpg
  ///
  /// String url2 = ApiConfig.buildImageUrl('https://example.com/photo.jpg');
  /// // Résultat: https://example.com/photo.jpg (inchangé)
  /// ```
  static String buildImageUrl(String imagePath) {
    if (isCompleteUrl(imagePath)) {
      return imagePath;
    }
    return buildResourceUrl(imagePath);
  }

  // ============================================================================
  // 📝 INFORMATIONS DE DEBUG
  // ============================================================================

  /// Affiche la configuration actuelle dans la console
  static void printConfig() {
    print('╔════════════════════════════════════════════════════════════╗');
    print('║            CONFIGURATION API CENTRALISÉE                   ║');
    print('╠════════════════════════════════════════════════════════════╣');
    print('║ Hôte       : $baseHost');
    print('║ Port       : $basePort');
    print('║ Protocole  : $scheme');
    print('║ Base URL   : $baseUrl');
    print('║ Resource   : $resourceUrl');
    print('╚════════════════════════════════════════════════════════════╝');
  }
}
