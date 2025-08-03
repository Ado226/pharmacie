// Fichier: lib/services/database_config.dart
// Configuration pour la connexion à la base de données MySQL sur cPanel

class DatabaseConfig {
  // Informations de connexion à la base de données MySQL sur cPanel
  static const String host = 'localhost'; // À remplacer par l'hôte de votre base de données
  static const int port = 3306; // Port MySQL standard
  static const String user = 'cp2575543p44_pharmacie'; // À remplacer par votre nom d'utilisateur
  static const String password = 'Cf}VJfweHEz,'; // À remplacer par votre mot de passe
  static const String db = 'cp2575543p44_pharmacie'; // À remplacer par le nom de votre base de données
  
  // URL de l'API pour les requêtes HTTP (alternative à la connexion directe)
  static const String apiUrl = 'https://globalstage-recruting.com/api'; // À remplacer par l'URL de votre API
}
