# 📡 Configuration de l'API - Guide Complet

## 🎯 Configuration Rapide

**Pour changer l'adresse de l'API, modifiez UNIQUEMENT ce fichier :**
```
lib/core/config/api_config.dart
```

### Paramètres à modifier

```dart
class ApiConfig {
  // Modifiez ces 3 valeurs selon votre environnement
  static const String baseHost = '192.168.11.101';  // IP ou domaine
  static const String basePort = '5000';             // Port
  static const String scheme = 'http';               // http ou https
}
```

## 🔧 Exemples de Configuration

### 1. Téléphone Physique (Développement)
```dart
static const String baseHost = '192.168.11.101';  // IP de votre PC
static const String basePort = '5000';
static const String scheme = 'http';
```

### 2. Émulateur Android
```dart
static const String baseHost = '10.0.2.2';  // Pointe vers localhost du PC
static const String basePort = '5000';
static const String scheme = 'http';
```

### 3. Windows/Web (Développement Local)
```dart
static const String baseHost = 'localhost';
static const String basePort = '5000';
static const String scheme = 'http';
```

### 4. Production
```dart
static const String baseHost = 'api.votre-domaine.com';
static const String basePort = '443';
static const String scheme = 'https';
```

## 📂 Architecture de Configuration

### Fichier Principal (À MODIFIER)
```
lib/core/config/api_config.dart  ← Modifiez ICI uniquement
```

### Fichiers qui utilisent la configuration (NE PAS MODIFIER)
```
lib/core/utils/constants.dart          → Importe ApiConfig
lib/services/database_config.dart      → Importe ApiConfig
lib/views/pharmacy_responses_view.dart → Importe ApiConfig
lib/features/auth/data/datasources/    → Utilise ApiConfig
lib/features/prescription/data/        → Utilise ApiConfig
lib/features/pharmacy_responses/data/  → Utilise ApiConfig
```

## 🛠️ Méthodes Utilitaires Disponibles

### `ApiConfig.buildResourceUrl(path)`
Construit une URL complète pour une ressource (image, fichier).

```dart
// Exemple
String imageUrl = ApiConfig.buildResourceUrl('/uploads/images/photo.jpg');
// Résultat: http://192.168.11.101:5000/uploads/images/photo.jpg
```

### `ApiConfig.buildApiUrl(endpoint)`
Construit une URL complète pour un endpoint de l'API.

```dart
// Exemple
String url = ApiConfig.buildApiUrl('/custom/endpoint');
// Résultat: http://192.168.11.101:5000/api/custom/endpoint
```

### `ApiConfig.buildImageUrl(imagePath)`
Construit une URL d'image en gérant automatiquement les URLs complètes et relatives.

```dart
// URL relative
String url1 = ApiConfig.buildImageUrl('/uploads/photo.jpg');
// Résultat: http://192.168.11.101:5000/uploads/photo.jpg

// URL complète (déjà formée)
String url2 = ApiConfig.buildImageUrl('https://example.com/photo.jpg');
// Résultat: https://example.com/photo.jpg (inchangé)
```

### `ApiConfig.printConfig()`
Affiche la configuration actuelle dans la console (utile pour le debug).

```dart
// Dans main.dart ou pour débugger
void main() {
  ApiConfig.printConfig();
  runApp(MyApp());
}
```

Sortie:
```
╔════════════════════════════════════════════════════════════╗
║            CONFIGURATION API CENTRALISÉE                   ║
╠════════════════════════════════════════════════════════════╣
║ Hôte       : 192.168.11.101
║ Port       : 5000
║ Protocole  : http
║ Base URL   : http://192.168.11.101:5000/api
║ Resource   : http://192.168.11.101:5000
╚════════════════════════════════════════════════════════════╝
```

## 📝 URLs Générées Automatiquement

Ces URLs sont générées automatiquement à partir de la configuration :

```dart
ApiConfig.baseUrl        // http://192.168.11.101:5000/api
ApiConfig.resourceUrl    // http://192.168.11.101:5000
ApiConfig.authUrl        // http://192.168.11.101:5000/api/auth
ApiConfig.commandesUrl   // http://192.168.11.101:5000/api/client/commandes
ApiConfig.pharmaciesUrl  // http://192.168.11.101:5000/api/admin/pharmacies
ApiConfig.produitsUrl    // http://192.168.11.101:5000/api/admin/produits
```

## 🚀 Workflow de Développement

### 1. Développement sur téléphone physique

1. Trouvez l'IP de votre PC :
   ```bash
   # Windows
   ipconfig

   # Linux/Mac
   ifconfig
   ```

2. Modifiez `lib/core/config/api_config.dart` :
   ```dart
   static const String baseHost = '192.168.X.X';  // Votre IP
   ```

3. Assurez-vous que votre téléphone et PC sont sur le même réseau WiFi

### 2. Développement sur émulateur Android

1. Modifiez `lib/core/config/api_config.dart` :
   ```dart
   static const String baseHost = '10.0.2.2';
   ```

2. L'émulateur redirige automatiquement vers localhost de votre PC

### 3. Déploiement en Production

1. Modifiez `lib/core/config/api_config.dart` :
   ```dart
   static const String baseHost = 'api.votre-domaine.com';
   static const String basePort = '443';
   static const String scheme = 'https';
   ```

2. Rebuild l'application :
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

## 🔍 Vérification de la Configuration

Pour vérifier que votre configuration fonctionne :

1. **Dans le code** :
   ```dart
   print('API URL: ${ApiConfig.baseUrl}');
   ApiConfig.printConfig();
   ```

2. **Test de connectivité** :
   - Lancez votre backend Node.js
   - Essayez de vous connecter depuis l'app
   - Vérifiez les logs du backend pour voir les requêtes

## ⚠️ Dépannage

### Problème : "Connection refused"
- ✅ Vérifiez que le backend est lancé
- ✅ Vérifiez l'IP dans `api_config.dart`
- ✅ Vérifiez que PC et téléphone sont sur le même réseau
- ✅ Désactivez le pare-feu temporairement pour tester

### Problème : "Network unreachable"
- ✅ Vérifiez la connexion WiFi
- ✅ Vérifiez que l'IP est correcte
- ✅ Testez avec `ping` depuis le terminal de votre téléphone

### Problème : Images ne s'affichent pas
- ✅ Utilisez `ApiConfig.buildImageUrl()` dans votre code
- ✅ Vérifiez que le chemin de l'image est correct
- ✅ Vérifiez les logs du backend

## 📚 Bonnes Pratiques

### ✅ À FAIRE
- Modifier uniquement `lib/core/config/api_config.dart`
- Utiliser les méthodes utilitaires (`buildImageUrl`, etc.)
- Appeler `ApiConfig.printConfig()` au démarrage pour vérifier
- Tester sur plusieurs environnements avant de déployer

### ❌ À NE PAS FAIRE
- Ne modifiez PAS les autres fichiers pour changer l'URL
- N'écrivez PAS d'URLs en dur dans les vues
- N'utilisez PAS d'URLs complètes dans le code métier
- Ne commitez PAS de configurations de production dans Git

## 🔐 Sécurité

### Fichiers à NE PAS commiter (ajoutez dans .gitignore)
```gitignore
# Configuration locale
lib/core/config/api_config.dart

# Secrets
lib/services/database_config.dart
.env
.env.local
*.key
*.pem
```

### Utiliser des variables d'environnement (optionnel)
Pour une meilleure sécurité, vous pouvez utiliser le package `flutter_dotenv` :

1. Installez le package :
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```

2. Créez un fichier `.env` :
   ```env
   API_HOST=192.168.11.101
   API_PORT=5000
   API_SCHEME=http
   ```

3. Modifiez `api_config.dart` :
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   class ApiConfig {
     static String get baseHost => dotenv.env['API_HOST']!;
     static String get basePort => dotenv.env['API_PORT']!;
     static String get scheme => dotenv.env['API_SCHEME']!;
   }
   ```

## 📞 Support

En cas de problème, vérifiez :
1. Ce fichier de documentation
2. Les commentaires dans `lib/core/config/api_config.dart`
3. Les logs du backend Node.js
4. Les logs de l'application Flutter (via `flutter logs`)

---

**Dernière mise à jour** : 2025-11-04
**Version** : 1.0.0
