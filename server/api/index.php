<?php
// Fichier: server/api/index.php
// Point d'entrée principal de l'API

// Inclure le fichier de configuration
require_once '../config.php';

// Récupérer la méthode HTTP et l'URI demandée
$method = $_SERVER['REQUEST_METHOD'];
$request = $_SERVER['REQUEST_URI'];

// Supprimer les paramètres de requête de l'URI
$uri = parse_url($request, PHP_URL_PATH);

// Extraire le chemin de l'API (supprimer le préfixe du chemin)
// Note: Ajustez cette ligne en fonction de votre configuration serveur
$prefix = '/api/';
$path = substr($uri, strlen($prefix));

// Diviser le chemin en segments
$segments = explode('/', $path);

// Vérifier l'authentification de l'API (sauf pour les routes publiques)
if (!in_array($segments[0], ['auth', 'public'])) {
    checkApiAuth();
}

// Router les requêtes vers les bons contrôleurs
switch ($segments[0]) {
    case 'prescriptions':
        require_once 'controllers/prescriptions_controller.php';
        $controller = new PrescriptionsController();
        routePrescriptions($method, $segments, $controller);
        break;
        
    case 'medications':
        require_once 'controllers/medications_controller.php';
        $controller = new MedicationsController();
        routeMedications($method, $segments, $controller);
        break;
        
    case 'pharmacies':
        require_once 'controllers/pharmacies_controller.php';
        $controller = new PharmaciesController();
        routePharmacies($method, $segments, $controller);
        break;
        
    case 'pharmacy_responses':
        require_once 'controllers/pharmacy_responses_controller.php';
        $controller = new PharmacyResponsesController();
        routePharmacyResponses($method, $segments, $controller);
        break;
        
    case 'auth':
        require_once 'controllers/auth_controller.php';
        $controller = new AuthController();
        routeAuth($method, $segments, $controller);
        break;
        
    default:
        // Route non trouvée
        handleError('Route non trouvée', 404);
        break;
}

// Fonction pour router les requêtes liées aux ordonnances
function routePrescriptions($method, $segments, $controller) {
    // GET /prescriptions - Liste toutes les ordonnances
    // GET /prescriptions/{id} - Récupère une ordonnance spécifique
    // POST /prescriptions - Crée une nouvelle ordonnance
    // PUT /prescriptions/{id} - Met à jour une ordonnance existante
    // DELETE /prescriptions/{id} - Supprime une ordonnance
    
    if ($method === 'GET') {
        if (count($segments) === 1) {
            // GET /prescriptions
            $controller->index();
        } elseif (count($segments) === 2) {
            // GET /prescriptions/{id}
            $controller->show($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'POST') {
        if (count($segments) === 1) {
            // POST /prescriptions
            $controller->store();
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'PUT') {
        if (count($segments) === 2) {
            // PUT /prescriptions/{id}
            $controller->update($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'DELETE') {
        if (count($segments) === 2) {
            // DELETE /prescriptions/{id}
            $controller->destroy($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } else {
        handleError('Méthode non autorisée', 405);
    }
}

// Fonction pour router les requêtes liées aux médicaments
function routeMedications($method, $segments, $controller) {
    // GET /medications - Liste tous les médicaments
    // GET /medications/{id} - Récupère un médicament spécifique
    // POST /medications - Crée un nouveau médicament
    // PUT /medications/{id} - Met à jour un médicament existant
    // DELETE /medications/{id} - Supprime un médicament
    
    if ($method === 'GET') {
        if (count($segments) === 1) {
            // GET /medications
            $controller->index();
        } elseif (count($segments) === 2) {
            // GET /medications/{id}
            $controller->show($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'POST') {
        if (count($segments) === 1) {
            // POST /medications
            $controller->store();
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'PUT') {
        if (count($segments) === 2) {
            // PUT /medications/{id}
            $controller->update($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'DELETE') {
        if (count($segments) === 2) {
            // DELETE /medications/{id}
            $controller->destroy($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } else {
        handleError('Méthode non autorisée', 405);
    }
}

// Fonction pour router les requêtes liées aux pharmacies
function routePharmacies($method, $segments, $controller) {
    // GET /pharmacies - Liste toutes les pharmacies
    // GET /pharmacies/{id} - Récupère une pharmacie spécifique
    
    if ($method === 'GET') {
        if (count($segments) === 1) {
            // GET /pharmacies
            $controller->index();
        } elseif (count($segments) === 2) {
            // GET /pharmacies/{id}
            $controller->show($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } else {
        handleError('Méthode non autorisée', 405);
    }
}

// Fonction pour router les requêtes liées aux réponses des pharmacies
function routePharmacyResponses($method, $segments, $controller) {
    // GET /pharmacy_responses?prescription_id={id} - Liste les réponses pour une ordonnance
    // GET /pharmacy_responses/{id} - Récupère une réponse spécifique
    // POST /pharmacy_responses/{id}/select - Sélectionne une pharmacie
    
    if ($method === 'GET') {
        if (count($segments) === 1) {
            // GET /pharmacy_responses
            $controller->index();
        } elseif (count($segments) === 2) {
            // GET /pharmacy_responses/{id}
            $controller->show($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'POST') {
        if (count($segments) === 3 && $segments[2] === 'select') {
            // POST /pharmacy_responses/{id}/select
            $controller->select($segments[1]);
        } else {
            handleError('Route non trouvée', 404);
        }
    } else {
        handleError('Méthode non autorisée', 405);
    }
}

// Fonction pour router les requêtes liées à l'authentification
function routeAuth($method, $segments, $controller) {
    // POST /auth/login - Connexion
    // POST /auth/register - Inscription
    // POST /auth/logout - Déconnexion
    // GET /auth/user - Récupère l'utilisateur connecté
    
    if ($method === 'POST') {
        if (count($segments) === 2) {
            if ($segments[1] === 'login') {
                // POST /auth/login
                $controller->login();
            } elseif ($segments[1] === 'register') {
                // POST /auth/register
                $controller->register();
            } elseif ($segments[1] === 'logout') {
                // POST /auth/logout
                $controller->logout();
            } else {
                handleError('Route non trouvée', 404);
            }
        } else {
            handleError('Route non trouvée', 404);
        }
    } elseif ($method === 'GET') {
        if (count($segments) === 2 && $segments[1] === 'user') {
            // GET /auth/user
            $controller->user();
        } else {
            handleError('Route non trouvée', 404);
        }
    } else {
        handleError('Méthode non autorisée', 405);
    }
}
