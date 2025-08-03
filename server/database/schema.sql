-- Supprimer les tables existantes dans le bon ordre (relations d'abord)
DROP TABLE IF EXISTS pharmacy_response_details;
DROP TABLE IF EXISTS pharmacy_responses;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS prescription_medications;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS pharmacies;
DROP TABLE IF EXISTS users;

-- Table des utilisateurs
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des pharmacies
CREATE TABLE pharmacies (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des médicaments
CREATE TABLE medications (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    form VARCHAR(50) NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    `usage` TEXT NOT NULL,
    image_url VARCHAR(255),
    price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des ordonnances
CREATE TABLE prescriptions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('en_attente', 'soumise', 'confirmee', 'terminee', 'annulee') DEFAULT 'en_attente',
    selected_pharmacy_id VARCHAR(36),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (selected_pharmacy_id) REFERENCES pharmacies(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table de relation entre ordonnances et médicaments
CREATE TABLE prescription_medications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id VARCHAR(36) NOT NULL,
    medication_id VARCHAR(36) NOT NULL,
    patient_type ENUM('enfant', 'adulte') NOT NULL,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des réponses des pharmacies
CREATE TABLE pharmacy_responses (
    id VARCHAR(36) PRIMARY KEY,
    prescription_id VARCHAR(36) NOT NULL,
    pharmacy_id VARCHAR(36) NOT NULL,
    response_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_price DECIMAL(10, 2) NOT NULL,
    availability_status ENUM('disponible', 'partiellement_disponible', 'indisponible') NOT NULL,
    delivery_option BOOLEAN NOT NULL DEFAULT 0,
    estimated_delivery_time VARCHAR(50),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des détails de réponse des pharmacies (prix par médicament)
CREATE TABLE pharmacy_response_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    response_id VARCHAR(36) NOT NULL,
    medication_id VARCHAR(36) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    available BOOLEAN NOT NULL DEFAULT 1,
    alternative_id VARCHAR(36),
    FOREIGN KEY (response_id) REFERENCES pharmacy_responses(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    FOREIGN KEY (alternative_id) REFERENCES medications(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des commandes
CREATE TABLE orders (
    id VARCHAR(36) PRIMARY KEY,
    prescription_id VARCHAR(36) NOT NULL,
    pharmacy_id VARCHAR(36) NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('en_attente', 'en_traitement', 'pret', 'livre', 'annule') DEFAULT 'en_attente',
    delivery_address TEXT,
    delivery_date TIMESTAMP NULL,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insertion de données de test pour les médicaments
INSERT INTO medications (id, name, description, form, dosage, `usage`) VALUES
('MED1', 'Paracétamol', 'Médicament antalgique et antipyrétique', 'Comprimé', '500mg', 'Traitement symptomatique des douleurs et de la fièvre'),
('MED2', 'Ibuprofène', 'Anti-inflammatoire non stéroïdien', 'Comprimé', '400mg', 'Traitement de la douleur et de l\'inflammation'),
('MED3', 'Amoxicilline', 'Antibiotique de la famille des bêta-lactamines', 'Gélule', '500mg', 'Traitement des infections bactériennes'),
('MED4', 'Doliprane', 'Médicament à base de paracétamol', 'Comprimé', '1000mg', 'Traitement symptomatique des douleurs et de la fièvre'),
('MED5', 'Efferalgan', 'Médicament à base de paracétamol', 'Comprimé effervescent', '500mg', 'Traitement symptomatique des douleurs et de la fièvre');

-- Insertion de données de test pour les pharmacies
INSERT INTO pharmacies (id, name, address, phone, email, latitude, longitude) VALUES
('PHARM1', 'Pharmacie Centrale', '15 Rue de la République, 75001 Paris', '01 23 45 67 89', 'contact@pharmaciecentrale.fr', 48.856614, 2.3522219),
('PHARM2', 'Pharmacie du Marché', '8 Place du Marché, 75002 Paris', '01 23 45 67 90', 'contact@pharmaciemarche.fr', 48.865614, 2.3622219),
('PHARM3', 'Pharmacie Saint-Michel', '25 Boulevard Saint-Michel, 75005 Paris', '01 23 45 67 91', 'contact@pharmaciesaintmichel.fr', 48.846614, 2.3422219);
