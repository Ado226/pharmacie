<?php
// Fichier: server/api/controllers/pharmacy_responses_controller.php
// Contrôleur pour gérer les réponses des pharmacies

class PharmacyResponsesController {
    private $conn;
    
    public function __construct() {
        $this->conn = getDbConnection();
    }
    
    // Méthode pour lister les réponses des pharmacies (filtrer par ordonnance)
    public function index() {
        // Vérifier si un ID d'ordonnance est fourni
        $prescriptionId = isset($_GET['prescription_id']) ? $_GET['prescription_id'] : null;
        
        if ($prescriptionId) {
            // Récupérer les réponses pour une ordonnance spécifique
            $stmt = $this->conn->prepare("
                SELECT pr.id, pr.prescription_id, pr.pharmacy_id, pr.response_date, 
                       pr.total_price, pr.availability_status, pr.delivery_option, 
                       pr.estimated_delivery_time
                FROM pharmacy_responses pr
                WHERE pr.prescription_id = ?
                ORDER BY pr.response_date DESC
            ");
            $stmt->bind_param("s", $prescriptionId);
        } else {
            // Récupérer toutes les réponses
            $stmt = $this->conn->prepare("
                SELECT pr.id, pr.prescription_id, pr.pharmacy_id, pr.response_date, 
                       pr.total_price, pr.availability_status, pr.delivery_option, 
                       pr.estimated_delivery_time
                FROM pharmacy_responses pr
                ORDER BY pr.response_date DESC
            ");
        }
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $responses = [];
        
        while ($row = $result->fetch_assoc()) {
            // Récupérer les informations de la pharmacie
            $pharmacyId = $row['pharmacy_id'];
            $pharmacy = $this->getPharmacy($pharmacyId);
            
            // Récupérer les détails des médicaments
            $medicationResponses = $this->getMedicationResponses($row['id']);
            
            // Construire la réponse complète
            $response = [
                'id' => $row['id'],
                'prescription_id' => $row['prescription_id'],
                'pharmacy' => $pharmacy,
                'response_date' => $row['response_date'],
                'medication_responses' => $medicationResponses,
                'total_price' => (float) $row['total_price'],
                'availability_status' => $row['availability_status'],
                'delivery_option' => (bool) $row['delivery_option'],
                'estimated_delivery_time' => $row['estimated_delivery_time'],
            ];
            
            $responses[] = $response;
        }
        
        $stmt->close();
        
        // Envoyer la réponse JSON
        sendJsonResponse($responses);
    }
    
    // Méthode pour afficher une réponse spécifique
    public function show($id) {
        $stmt = $this->conn->prepare("
            SELECT pr.id, pr.prescription_id, pr.pharmacy_id, pr.response_date, 
                   pr.total_price, pr.availability_status, pr.delivery_option, 
                   pr.estimated_delivery_time
            FROM pharmacy_responses pr
            WHERE pr.id = ?
        ");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            handleError('Réponse de pharmacie non trouvée', 404);
        }
        
        $row = $result->fetch_assoc();
        
        // Récupérer les informations de la pharmacie
        $pharmacyId = $row['pharmacy_id'];
        $pharmacy = $this->getPharmacy($pharmacyId);
        
        // Récupérer les détails des médicaments
        $medicationResponses = $this->getMedicationResponses($row['id']);
        
        // Construire la réponse complète
        $response = [
            'id' => $row['id'],
            'prescription_id' => $row['prescription_id'],
            'pharmacy' => $pharmacy,
            'response_date' => $row['response_date'],
            'medication_responses' => $medicationResponses,
            'total_price' => (float) $row['total_price'],
            'availability_status' => $row['availability_status'],
            'delivery_option' => (bool) $row['delivery_option'],
            'estimated_delivery_time' => $row['estimated_delivery_time'],
        ];
        
        $stmt->close();
        
        // Envoyer la réponse JSON
        sendJsonResponse($response);
    }
    
    // Méthode pour sélectionner une pharmacie (confirmer une commande)
    public function select($id) {
        // Vérifier si la réponse existe
        $stmt = $this->conn->prepare("
            SELECT id, prescription_id, pharmacy_id
            FROM pharmacy_responses
            WHERE id = ?
        ");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            handleError('Réponse de pharmacie non trouvée', 404);
        }
        
        $row = $result->fetch_assoc();
        $prescriptionId = $row['prescription_id'];
        $pharmacyId = $row['pharmacy_id'];
        
        $stmt->close();
        
        // Commencer une transaction
        $this->conn->begin_transaction();
        
        try {
            // Mettre à jour le statut de l'ordonnance
            $updateStmt = $this->conn->prepare("
                UPDATE prescriptions
                SET status = 'confirmed', selected_pharmacy_id = ?
                WHERE id = ?
            ");
            $updateStmt->bind_param("ss", $pharmacyId, $prescriptionId);
            $updateStmt->execute();
            $updateStmt->close();
            
            // Créer une entrée dans la table des commandes
            $orderId = uniqid('ORD');
            $orderDate = date('Y-m-d H:i:s');
            $status = 'pending';
            
            $orderStmt = $this->conn->prepare("
                INSERT INTO orders (id, prescription_id, pharmacy_id, order_date, status)
                VALUES (?, ?, ?, ?, ?)
            ");
            $orderStmt->bind_param("sssss", $orderId, $prescriptionId, $pharmacyId, $orderDate, $status);
            $orderStmt->execute();
            $orderStmt->close();
            
            // Valider la transaction
            $this->conn->commit();
            
            // Envoyer la réponse JSON
            sendJsonResponse([
                'success' => true,
                'message' => 'Pharmacie sélectionnée avec succès',
                'order_id' => $orderId
            ]);
        } catch (Exception $e) {
            // Annuler la transaction en cas d'erreur
            $this->conn->rollback();
            handleError('Erreur lors de la sélection de la pharmacie: ' . $e->getMessage());
        }
    }
    
    // Méthode pour récupérer les informations d'une pharmacie
    private function getPharmacy($pharmacyId) {
        $stmt = $this->conn->prepare("
            SELECT id, name, address, phone, email, latitude, longitude, image_url
            FROM pharmacies
            WHERE id = ?
        ");
        $stmt->bind_param("s", $pharmacyId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            return null;
        }
        
        $row = $result->fetch_assoc();
        $pharmacy = [
            'id' => $row['id'],
            'name' => $row['name'],
            'address' => $row['address'],
            'phone' => $row['phone'],
            'email' => $row['email'],
            'latitude' => $row['latitude'] ? (float) $row['latitude'] : null,
            'longitude' => $row['longitude'] ? (float) $row['longitude'] : null,
            'image_url' => $row['image_url'],
        ];
        
        $stmt->close();
        return $pharmacy;
    }
    
    // Méthode pour récupérer les détails des médicaments d'une réponse
    private function getMedicationResponses($responseId) {
        $stmt = $this->conn->prepare("
            SELECT prd.id, prd.medication_id, prd.price, prd.available, prd.alternative_id
            FROM pharmacy_response_details prd
            WHERE prd.response_id = ?
        ");
        $stmt->bind_param("s", $responseId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $medicationResponses = [];
        
        while ($row = $result->fetch_assoc()) {
            // Récupérer les informations du médicament
            $medicationId = $row['medication_id'];
            $medication = $this->getMedication($medicationId);
            
            // Récupérer les informations de l'alternative si elle existe
            $alternativeId = $row['alternative_id'];
            $alternative = $alternativeId ? $this->getMedication($alternativeId) : null;
            
            $medicationResponse = [
                'id' => $row['id'],
                'medication' => $medication,
                'price' => (float) $row['price'],
                'available' => (bool) $row['available'],
                'alternative' => $alternative,
            ];
            
            $medicationResponses[] = $medicationResponse;
        }
        
        $stmt->close();
        return $medicationResponses;
    }
    
    // Méthode pour récupérer les informations d'un médicament
    private function getMedication($medicationId) {
        $stmt = $this->conn->prepare("
            SELECT id, name, description, form, dosage, usage, image_url, price
            FROM medications
            WHERE id = ?
        ");
        $stmt->bind_param("s", $medicationId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            return null;
        }
        
        $row = $result->fetch_assoc();
        $medication = [
            'id' => $row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'form' => $row['form'],
            'dosage' => $row['dosage'],
            'usage' => $row['usage'],
            'image_url' => $row['image_url'],
            'price' => $row['price'] ? (float) $row['price'] : null,
        ];
        
        $stmt->close();
        return $medication;
    }
}
