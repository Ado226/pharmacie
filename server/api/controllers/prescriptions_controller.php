<?php
// Fichier: server/api/controllers/prescriptions_controller.php
// Contrôleur pour gérer les prescriptions

class PrescriptionsController {
    private $conn;
    
    public function __construct() {
        $this->conn = getDbConnection();
    }
    
    // Méthode pour lister toutes les prescriptions
    public function index() {
        // Vérifier si un ID de patient est fourni pour filtrer
        $patientName = isset($_GET['patient_name']) ? $_GET['patient_name'] : null;
        
        if ($patientName) {
            // Récupérer les prescriptions pour un patient spécifique
            $stmt = $this->conn->prepare("
                SELECT p.id, p.patient_name, p.created_at, p.status
                FROM prescriptions p
                WHERE p.patient_name LIKE ?
                ORDER BY p.created_at DESC
            ");
            $searchPattern = "%$patientName%";
            $stmt->bind_param("s", $searchPattern);
        } else {
            // Récupérer toutes les prescriptions
            $stmt = $this->conn->prepare("
                SELECT p.id, p.patient_name, p.created_at, p.status
                FROM prescriptions p
                ORDER BY p.created_at DESC
            ");
        }
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $prescriptions = [];
        
        while ($row = $result->fetch_assoc()) {
            // Récupérer les médicaments associés à cette prescription
            $medications = $this->getPrescriptionMedications($row['id']);
            
            // Construire la prescription complète
            $prescription = [
                'id' => $row['id'],
                'name' => $row['patient_name'],
                'created_at' => $row['created_at'],
                'status' => $row['status'] ?? 'en_attente',
                'medications' => $medications,
            ];
            
            $prescriptions[] = $prescription;
        }
        
        $stmt->close();
        
        // Envoyer la réponse JSON
        sendJsonResponse($prescriptions);
    }
    
    // Méthode pour afficher une prescription spécifique
    public function show($id) {
        $stmt = $this->conn->prepare("
            SELECT p.id, p.patient_name, p.created_at, p.status
            FROM prescriptions p
            WHERE p.id = ?
        ");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            handleError('Prescription non trouvée', 404);
        }
        
        $row = $result->fetch_assoc();
        
        // Récupérer les médicaments associés à cette prescription
        $medications = $this->getPrescriptionMedications($row['id']);
        
        // Construire la prescription complète
        $prescription = [
            'id' => $row['id'],
            'name' => $row['patient_name'],
            'created_at' => $row['created_at'],
            'status' => $row['status'] ?? 'en_attente',
            'medications' => $medications,
        ];
        
        $stmt->close();
        
        // Envoyer la réponse JSON
        sendJsonResponse($prescription);
    }
    
    // Méthode pour créer une nouvelle prescription
    public function store() {
        // Récupérer les données JSON de la requête
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Vérifier les données requises
        if (!isset($data['name']) || !isset($data['medications']) || empty($data['medications'])) {
            handleError('Données invalides pour créer une prescription', 400);
        }
        
        // Générer un ID unique pour la prescription
        $id = uniqid('presc_');
        $patientName = $data['name'];
        $createdAt = date('Y-m-d H:i:s');
        $status = $data['status'] ?? 'en_attente';
        
        // Commencer une transaction
        $this->conn->begin_transaction();
        
        try {
            // Insérer la prescription
            $stmt = $this->conn->prepare("
                INSERT INTO prescriptions (id, patient_name, created_at, status)
                VALUES (?, ?, ?, ?)
            ");
            $stmt->bind_param("ssss", $id, $patientName, $createdAt, $status);
            $stmt->execute();
            $stmt->close();
            
            // Insérer les médicaments de la prescription
            foreach ($data['medications'] as $medication) {
                $medicationId = $medication['medication']['id'];
                $patientType = $medication['patient_type'] ?? 'adulte';
                
                $stmt = $this->conn->prepare("
                    INSERT INTO prescription_medications (prescription_id, medication_id, patient_type)
                    VALUES (?, ?, ?)
                ");
                $stmt->bind_param("sss", $id, $medicationId, $patientType);
                $stmt->execute();
                $stmt->close();
            }
            
            // Valider la transaction
            $this->conn->commit();
            
            // Récupérer la prescription complète
            $prescription = [
                'id' => $id,
                'name' => $patientName,
                'created_at' => $createdAt,
                'status' => $status,
                'medications' => $data['medications'],
            ];
            
            // Envoyer la réponse JSON
            sendJsonResponse($prescription, 201);
        } catch (Exception $e) {
            // Annuler la transaction en cas d'erreur
            $this->conn->rollback();
            handleError('Erreur lors de la création de la prescription: ' . $e->getMessage(), 500);
        }
    }
    
    // Méthode pour mettre à jour une prescription
    public function update($id) {
        // Récupérer les données JSON de la requête
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Vérifier si la prescription existe
        $stmt = $this->conn->prepare("SELECT id FROM prescriptions WHERE id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            handleError('Prescription non trouvée', 404);
        }
        
        $stmt->close();
        
        // Commencer une transaction
        $this->conn->begin_transaction();
        
        try {
            // Mettre à jour les informations de base de la prescription
            if (isset($data['name']) || isset($data['status'])) {
                $updates = [];
                $params = [];
                $types = "";
                
                if (isset($data['name'])) {
                    $updates[] = "patient_name = ?";
                    $params[] = $data['name'];
                    $types .= "s";
                }
                
                if (isset($data['status'])) {
                    $updates[] = "status = ?";
                    $params[] = $data['status'];
                    $types .= "s";
                }
                
                $updateQuery = "UPDATE prescriptions SET " . implode(", ", $updates) . " WHERE id = ?";
                $stmt = $this->conn->prepare($updateQuery);
                
                // Ajouter l'ID à la fin des paramètres
                $params[] = $id;
                $types .= "s";
                
                // Lier les paramètres dynamiquement
                $stmt->bind_param($types, ...$params);
                $stmt->execute();
                $stmt->close();
            }
            
            // Mettre à jour les médicaments si fournis
            if (isset($data['medications'])) {
                // Supprimer les médicaments existants
                $stmt = $this->conn->prepare("DELETE FROM prescription_medications WHERE prescription_id = ?");
                $stmt->bind_param("s", $id);
                $stmt->execute();
                $stmt->close();
                
                // Insérer les nouveaux médicaments
                foreach ($data['medications'] as $medication) {
                    $medicationId = $medication['medication']['id'];
                    $patientType = $medication['patient_type'] ?? 'adulte';
                    
                    $stmt = $this->conn->prepare("
                        INSERT INTO prescription_medications (prescription_id, medication_id, patient_type)
                        VALUES (?, ?, ?)
                    ");
                    $stmt->bind_param("sss", $id, $medicationId, $patientType);
                    $stmt->execute();
                    $stmt->close();
                }
            }
            
            // Valider la transaction
            $this->conn->commit();
            
            // Récupérer la prescription mise à jour
            $this->show($id);
        } catch (Exception $e) {
            // Annuler la transaction en cas d'erreur
            $this->conn->rollback();
            handleError('Erreur lors de la mise à jour de la prescription: ' . $e->getMessage(), 500);
        }
    }
    
    // Méthode pour supprimer une prescription
    public function delete($id) {
        // Vérifier si la prescription existe
        $stmt = $this->conn->prepare("SELECT id FROM prescriptions WHERE id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            handleError('Prescription non trouvée', 404);
        }
        
        $stmt->close();
        
        // Commencer une transaction
        $this->conn->begin_transaction();
        
        try {
            // Supprimer les médicaments associés
            $stmt = $this->conn->prepare("DELETE FROM prescription_medications WHERE prescription_id = ?");
            $stmt->bind_param("s", $id);
            $stmt->execute();
            $stmt->close();
            
            // Supprimer la prescription
            $stmt = $this->conn->prepare("DELETE FROM prescriptions WHERE id = ?");
            $stmt->bind_param("s", $id);
            $stmt->execute();
            $stmt->close();
            
            // Valider la transaction
            $this->conn->commit();
            
            // Envoyer une réponse de succès
            sendJsonResponse(['message' => 'Prescription supprimée avec succès'], 200);
        } catch (Exception $e) {
            // Annuler la transaction en cas d'erreur
            $this->conn->rollback();
            handleError('Erreur lors de la suppression de la prescription: ' . $e->getMessage(), 500);
        }
    }
    
    // Méthode pour récupérer les médicaments d'une prescription
    private function getPrescriptionMedications($prescriptionId) {
        $stmt = $this->conn->prepare("
            SELECT pm.medication_id, pm.patient_type, 
                   m.name, m.form, m.dosage, m.usage, m.contraindications
            FROM prescription_medications pm
            JOIN medications m ON pm.medication_id = m.id
            WHERE pm.prescription_id = ?
        ");
        $stmt->bind_param("s", $prescriptionId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $medications = [];
        
        while ($row = $result->fetch_assoc()) {
            $medication = [
                'medication' => [
                    'id' => $row['medication_id'],
                    'name' => $row['name'],
                    'form' => $row['form'],
                    'dosage' => $row['dosage'],
                    'usage' => $row['usage'],
                    'contraindications' => $row['contraindications'],
                ],
                'patient_type' => $row['patient_type'],
            ];
            
            $medications[] = $medication;
        }
        
        $stmt->close();
        
        return $medications;
    }
}

// Déterminer l'action à effectuer en fonction de la méthode HTTP et des segments d'URL
$controller = new PrescriptionsController();
$action = '';
$id = '';

// Récupérer l'action et l'ID à partir des segments d'URL
if (isset($segments[1])) {
    if ($segments[1] === 'create') {
        $action = 'store';
    } elseif (is_numeric($segments[1]) || (is_string($segments[1]) && strlen($segments[1]) > 0)) {
        $id = $segments[1];
        
        if (isset($segments[2])) {
            $action = $segments[2];
        } else {
            $action = 'show';
        }
    }
} else {
    $action = 'index';
}

// Exécuter l'action appropriée
switch ($method) {
    case 'GET':
        if ($action === 'index') {
            $controller->index();
        } elseif ($action === 'show' && !empty($id)) {
            $controller->show($id);
        } else {
            handleError('Route non trouvée', 404);
        }
        break;
        
    case 'POST':
        if ($action === 'store') {
            $controller->store();
        } else {
            handleError('Méthode non autorisée', 405);
        }
        break;
        
    case 'PUT':
    case 'PATCH':
        if (!empty($id)) {
            $controller->update($id);
        } else {
            handleError('ID de prescription requis', 400);
        }
        break;
        
    case 'DELETE':
        if (!empty($id)) {
            $controller->delete($id);
        } else {
            handleError('ID de prescription requis', 400);
        }
        break;
        
    default:
        handleError('Méthode non autorisée', 405);
        break;
}
