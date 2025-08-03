<?php
// Fichier: server/config.php
// Configuration de la base de données MySQL sur cPanel

// Informations de connexion à la base de données
define('DB_HOST', 'localhost'); // Généralement 'localhost' sur cPanel
define('DB_USER', 'votre_utilisateur_cpanel'); // Remplacer par votre nom d'utilisateur cPanel
define('DB_PASS', 'votre_mot_de_passe_cpanel'); // Remplacer par votre mot de passe cPanel
define('DB_NAME', 'votre_base_de_donnees'); // Remplacer par le nom de votre base de données

// Configuration de l'API
define('API_KEY', 'votre_cle_api_secrete'); // Clé d'API pour sécuriser les requêtes
define('ALLOW_CORS', true); // Autoriser les requêtes Cross-Origin (CORS)
define('DEBUG_MODE', false); // Mode débogage (à désactiver en production)

// Fuseau horaire
date_default_timezone_set('Europe/Paris');

// Fonction pour se connecter à la base de données
function getDbConnection() {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    // Vérifier la connexion
    if ($conn->connect_error) {
        if (DEBUG_MODE) {
            die("Erreur de connexion à la base de données: " . $conn->connect_error);
        } else {
            die("Erreur de connexion à la base de données");
        }
    }
    
    // Définir l'encodage des caractères
    $conn->set_charset("utf8");
    
    return $conn;
}

// Fonction pour vérifier l'authentification de l'API
function checkApiAuth() {
    // Vérifier si l'en-tête d'API est présent
    $headers = getallheaders();
    $apiKey = isset($headers['X-API-Key']) ? $headers['X-API-Key'] : '';
    
    if ($apiKey !== API_KEY) {
        header('HTTP/1.1 401 Unauthorized');
        echo json_encode(['error' => 'Accès non autorisé']);
        exit;
    }
    
    return true;
}

// Fonction pour gérer les erreurs
function handleError($message, $statusCode = 500) {
    header('HTTP/1.1 ' . $statusCode . ' Error');
    echo json_encode(['error' => $message]);
    exit;
}

// Fonction pour gérer les réponses JSON
function sendJsonResponse($data, $statusCode = 200) {
    header('Content-Type: application/json');
    http_response_code($statusCode);
    echo json_encode($data);
    exit;
}

// Configuration CORS si activée
if (ALLOW_CORS) {
    // Autoriser l'accès depuis n'importe quelle origine
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, X-API-Key');
    
    // Gérer les requêtes OPTIONS (pre-flight)
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        exit(0);
    }
}
