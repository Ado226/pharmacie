# Intégration MySQL pour l'application Pharmacie

Ce dossier contient les fichiers nécessaires pour intégrer une base de données MySQL hébergée sur cPanel LWS à votre application Flutter Pharmacie.

## Structure des fichiers

```
server/
  ├── config.php              # Configuration de la base de données et de l'API
  ├── api/                    # API REST pour communiquer avec la base de données
  │   ├── index.php           # Point d'entrée de l'API
  │   └── controllers/        # Contrôleurs pour gérer les requêtes API
  │       └── pharmacy_responses_controller.php  # Contrôleur pour les réponses des pharmacies
  └── database/
      └── schema.sql          # Script SQL pour créer les tables de la base de données
```

## Configuration de la base de données MySQL sur cPanel LWS

1. **Connexion à votre cPanel LWS**
   - Connectez-vous à votre compte cPanel LWS à l'adresse fournie par LWS
   - Utilisez vos identifiants de connexion

2. **Création de la base de données MySQL**
   - Dans cPanel, recherchez la section "Bases de données" et cliquez sur "MySQL Databases"
   - Créez une nouvelle base de données en lui donnant un nom (ex: pharmacie_db)
   - Créez un nouvel utilisateur MySQL avec un mot de passe sécurisé
   - Associez l'utilisateur à la base de données en lui accordant tous les privilèges

3. **Importation du schéma de la base de données**
   - Dans cPanel, accédez à "phpMyAdmin"
   - Sélectionnez la base de données que vous venez de créer
   - Cliquez sur l'onglet "Importer"
   - Sélectionnez le fichier `schema.sql` et cliquez sur "Exécuter"

## Configuration de l'API PHP

1. **Téléchargement des fichiers sur votre hébergement**
   - Utilisez un client FTP (comme FileZilla) pour vous connecter à votre hébergement
   - Créez un dossier `api` à la racine de votre hébergement
   - Téléchargez tous les fichiers du dossier `server` dans ce dossier

2. **Configuration des paramètres de connexion**
   - Ouvrez le fichier `config.php`
   - Modifiez les informations de connexion à la base de données :
     ```php
     define('DB_HOST', 'localhost'); // Généralement 'localhost' sur cPanel
     define('DB_USER', 'votre_utilisateur_cpanel'); // Remplacer par votre nom d'utilisateur MySQL
     define('DB_PASS', 'votre_mot_de_passe_cpanel'); // Remplacer par votre mot de passe MySQL
     define('DB_NAME', 'votre_base_de_donnees'); // Remplacer par le nom de votre base de données
     ```
   - Définissez une clé API sécurisée :
     ```php
     define('API_KEY', 'votre_cle_api_secrete'); // Remplacer par une clé API sécurisée
     ```

3. **Configuration des permissions**
   - Assurez-vous que les fichiers PHP ont les permissions appropriées (généralement 644)
   - Assurez-vous que les dossiers ont les permissions appropriées (généralement 755)

## Configuration de l'application Flutter

1. **Modification du fichier de configuration**
   - Ouvrez le fichier `lib/services/database_config.dart`
   - Modifiez les informations de connexion à la base de données :
     ```dart
     static const String host = 'votre_hote_mysql.lws.fr'; // À remplacer par l'hôte de votre base de données
     static const int port = 3306; // Port MySQL standard
     static const String user = 'votre_utilisateur'; // À remplacer par votre nom d'utilisateur
     static const String password = 'votre_mot_de_passe'; // À remplacer par votre mot de passe
     static const String db = 'votre_base_de_donnees'; // À remplacer par le nom de votre base de données
     ```
   - Modifiez l'URL de l'API :
     ```dart
     static const String apiUrl = 'https://votre_domaine.lws.fr/api'; // À remplacer par l'URL de votre API
     ```

2. **Installation des dépendances**
   - Exécutez la commande suivante pour installer les dépendances nécessaires :
     ```bash
     flutter pub get
     ```

3. **Initialisation de la base de données locale**
   - Lors du premier lancement de l'application, la base de données locale sera automatiquement créée
   - Les données seront synchronisées avec la base de données MySQL lorsque l'application est connectée à Internet

## Utilisation de l'API

L'API REST est accessible à l'adresse `https://votre_domaine.lws.fr/api/`.

Voici quelques exemples de requêtes :

- `GET /api/medications` : Liste tous les médicaments
- `GET /api/prescriptions` : Liste toutes les ordonnances
- `GET /api/pharmacy_responses?prescription_id=ID` : Liste les réponses des pharmacies pour une ordonnance spécifique
- `POST /api/pharmacy_responses/ID/select` : Sélectionne une pharmacie pour une ordonnance

Toutes les requêtes doivent inclure l'en-tête `X-API-Key` avec la clé API définie dans `config.php`.

## Dépannage

Si vous rencontrez des problèmes lors de l'installation ou de la configuration, voici quelques solutions :

1. **Erreur de connexion à la base de données**
   - Vérifiez que les informations de connexion dans `config.php` sont correctes
   - Assurez-vous que l'utilisateur MySQL a les privilèges nécessaires
   - Vérifiez que la base de données existe

2. **Erreur 404 lors de l'accès à l'API**
   - Vérifiez que les fichiers ont été correctement téléchargés sur votre hébergement
   - Assurez-vous que le chemin de l'API est correct
   - Vérifiez que le serveur est configuré pour exécuter PHP

3. **Erreur d'authentification**
   - Vérifiez que la clé API dans l'application Flutter correspond à celle définie dans `config.php`
   - Assurez-vous que l'en-tête `X-API-Key` est correctement envoyé avec chaque requête

Pour toute autre question ou problème, n'hésitez pas à contacter le support technique.
