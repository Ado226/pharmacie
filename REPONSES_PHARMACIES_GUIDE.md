# 📋 Guide Complet - Réponses des Pharmacies

## 🎯 Vue d'ensemble

Ce document explique comment fonctionne le système de réponses des pharmacies dans l'application, depuis la création d'une commande jusqu'à l'affichage des réponses.

## 🗄️ Structure de la Base de Données

### Table `reponses_pharmacies`

```sql
CREATE TABLE reponses_pharmacies (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  commande_id INTEGER NOT NULL,
  pharmacie_id INTEGER NOT NULL,
  contactee BOOLEAN DEFAULT false,
  reponse_obtenue BOOLEAN DEFAULT false,
  produits_disponibles JSON,
  produits_remplacement JSON,
  montant_total_pharmacie DECIMAL(10,2),
  commentaire_pharmacie TEXT,
  contacte_le DATETIME,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Structure des Données JSON

#### `produits_disponibles`
```json
[
  {
    "produit_id": 1,
    "disponible": true,
    "prix_unitaire": 5000,
    "quantite": 2,
    "prix_total": 10000
  },
  {
    "produit_id": 2,
    "disponible": false
  }
]
```

#### `produits_remplacement`
```json
[
  {
    "produit_id": 2,
    "nom_remplacement": "Paracétamol 500mg (générique)"
  }
]
```

## 🔄 Flux Complet du Système

### 1. Création d'une Commande (Client)

**Endpoint:** `POST /api/client/commandes`

**Processus:**
1. Client crée une commande (photo ou saisie manuelle)
2. Backend crée l'enregistrement dans `commandes` avec `statut = 'en_attente'`
3. Backend calcule les pharmacies les plus proches
4. Backend enregistre les distances dans `pharmacies_distances`

**Code:** `Services/commandeService.js` - `createCommande()`

### 2. Consultation du Statut (Client)

**Endpoint:** `GET /api/client/commandes/:id/status`

**Réponse:**
```json
{
  "id": 8,
  "client_id": 2,
  "type_commande": "saisie_manuelle",
  "statut": "en_attente",
  "ordonnance_photo_url": null,
  "montant_total": null,
  "pharmacie_assignee_id": null,
  "created_at": "2025-01-04T10:30:00Z",
  "produits": [
    {
      "produit_id": 1,
      "nom_produit_personnalise": "Doliprane",
      "quantite": 2,
      "age_cible": "adulte",
      "produit": {
        "nom": "Paracétamol 1000mg",
        "description": "Antalgique et antipyrétique"
      }
    }
  ],
  "pharmacies_proximite": [
    {
      "pharmacie_id": 1,
      "nom": "Pharmacie Centrale",
      "adresse": "123 Rue Principale",
      "quartier": "Centre-ville",
      "distance_metres": 500,
      "rang_proximite": 1
    }
  ],
  "reponses_existantes": [
    {
      "id": 1,
      "commande_id": 8,
      "pharmacie_id": 1,
      "contactee": true,
      "reponse_obtenue": true,
      "produits_disponibles": [...],
      "montant_total_pharmacie": 15000,
      "commentaire_pharmacie": "Tous les produits disponibles",
      "contacte_le": "2025-01-04T11:00:00Z",
      "created_at": "2025-01-04T11:00:00Z",
      "Pharmacie": {
        "id": 1,
        "nom": "Pharmacie Centrale",
        "adresse": "123 Rue Principale",
        "quartier": "Centre-ville",
        "numero_telephone": "+229 12345678",
        "email": "contact@pharmacie-centrale.bj"
      }
    }
  ]
}
```

**Code:** `Services/commandeService.js` - `getCommandeStatus()`

### 3. Admin Crée une Réponse Pharmacie

**Endpoint:** `POST /api/admin/commandes/:id/reponses`

**Body:**
```json
{
  "pharmacie_id": 1,
  "produits_disponibles": [
    {
      "produit_id": 1,
      "disponible": true,
      "prix_unitaire": 5000,
      "produit_remplacement": ""
    }
  ],
  "commentaire_pharmacie": "Produits en stock"
}
```

**Processus:**
1. Backend valide que la commande existe
2. Backend valide que la pharmacie existe
3. Backend calcule le montant total basé sur les produits disponibles
4. Backend crée l'enregistrement dans `reponses_pharmacies`

**Code:** `Controllers/reponsePharmacieController.js` - `createReponsePharmacie()`

### 4. Récupération des Réponses (Admin)

**Endpoint:** `GET /api/admin/commandes/:id/reponses`

**Réponse:**
```json
[
  {
    "id": 1,
    "commande_id": 8,
    "pharmacie_id": 1,
    "contactee": true,
    "reponse_obtenue": true,
    "produits_disponibles": [...],
    "montant_total_pharmacie": 15000,
    "Pharmacie": {
      "id": 1,
      "nom": "Pharmacie Centrale",
      ...
    }
  }
]
```

**Code:** `Controllers/reponsePharmacieController.js` - `getReponsesForCommande()`

## 📱 Frontend Flutter

### Architecture

```
lib/
├── models/
│   └── pharmacy_response_api_model.dart    # Modèles de données
├── services/
│   └── pharmacy_response_service.dart      # Service API
└── views/
    ├── mes_commandes_view.dart             # Liste des commandes
    ├── pharmacy_responses_list_view.dart   # Liste pour voir les réponses
    └── pharmacy_responses_view.dart        # Détails des réponses
```

### Modèles de Données

#### `ReponsePharmacieApi`
Représente une réponse complète d'une pharmacie.

```dart
class ReponsePharmacieApi {
  final int id;
  final int commandeId;
  final int pharmacieId;
  final bool contactee;
  final bool reponseObtenue;
  final List<ProduitDisponible> produitsDisponibles;
  final double montantTotalPharmacie;
  final String? commentairePharmacie;
  final PharmacieInfo? pharmacie;

  // Méthodes utiles
  int get nombreProduitsDisponibles { ... }
  double get pourcentageDisponibilite { ... }
}
```

#### `CommandeDetailResponse`
Réponse complète de `/status` incluant la commande, pharmacies proches et réponses.

```dart
class CommandeDetailResponse {
  final CommandeApi commande;
  final List<PharmacieProximite> pharmaciesProximite;
  final List<ReponsePharmacieApi> reponsesExistantes;
}
```

### Service API

**Fichier:** `lib/services/pharmacy_response_service.dart`

#### Méthodes principales

##### `getCommandeDetails(int commandeId)`
Récupère les détails complets d'une commande incluant les réponses des pharmacies.

```dart
final details = await PharmacyResponseService.getCommandeDetails(8);
print('Réponses: ${details.reponsesExistantes.length}');
```

**Endpoint appelé:** `GET /api/client/commandes/:id/status`

##### `getReponsesForCommande(int commandeId)`
Récupère uniquement les réponses des pharmacies pour une commande.

```dart
final reponses = await PharmacyResponseService.getReponsesForCommande(8);
```

**Endpoint appelé:** `GET /api/client/commandes/:id/status` (extrait `reponses_existantes`)

##### `getMesCommandes()`
Récupère la liste des commandes du client connecté.

```dart
final commandes = await PharmacyResponseService.getMesCommandes();
```

**Endpoint appelé:** `GET /api/client/commandes`

### Vues

#### 1. `MesCommandesView` ou `PharmacyResponsesListView`

**Rôle:** Affiche la liste des commandes du client

**Flux:**
1. Charge les commandes via `PharmacyResponseService.getMesCommandes()`
2. Affiche chaque commande avec son statut
3. Au clic sur une commande:
   - Charge les détails via `PharmacyResponseService.getCommandeDetails(commandeId)`
   - Extrait les réponses: `commandeDetails.reponsesExistantes`
   - Détermine le statut:
     - Si `reponses.isEmpty` → `PrescriptionStatus.enAttente`
     - Si `reponses.isNotEmpty` → `PrescriptionStatus.enCours`
   - Navigate vers `PharmacyResponsesView`

**Code clé:**
```dart
// pharmacy_responses_list_view.dart ligne 421-423
final status = reponses.isNotEmpty
    ? PrescriptionStatus.enCours
    : PrescriptionStatus.enAttente;

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PharmacyResponsesView(
      patientName: patientName,
      productsList: productsList,
      status: status,
      commandeId: commandeId,
      pharmacyResponses: reponses,  // ← Réponses passées ici
      ordonnancePhotoUrl: ordonnancePhotoUrl,
    ),
  ),
);
```

#### 2. `PharmacyResponsesView`

**Rôle:** Affiche les réponses des pharmacies ou "Analyse en cours"

**États d'affichage:**

##### État 1: `PrescriptionStatus.enAttente` (Aucune réponse)
```dart
Widget _buildNoResponsesSection() {
  return Container(
    child: Column(
      children: [
        Icon(Icons.hourglass_empty_rounded),
        Text('Analyse en cours...'),
        Text('Les pharmacies analysent votre demande.'),
      ],
    ),
  );
}
```

**Quand:** Aucune réponse dans `reponses_existantes` de l'API

##### État 2: `PrescriptionStatus.enCours` (Réponses disponibles)
```dart
Widget _buildMultipleResponsesSection() {
  return Column(
    children: [
      Text('Offres disponibles'),
      ListView.builder(
        itemCount: _pharmacies.length,
        itemBuilder: (context, index) {
          return _buildModernPharmacyCard(_pharmacies[index], index);
        },
      ),
    ],
  );
}
```

**Quand:** Une ou plusieurs réponses dans `reponses_existantes`

**Chargement des données:**
```dart
void _loadPharmacyResponses() async {
  List<ReponsePharmacieApi> reponses = [];

  // Cas 1: Réponses fournies en paramètre (depuis la liste)
  if (widget.pharmacyResponses != null && widget.pharmacyResponses!.isNotEmpty) {
    reponses = widget.pharmacyResponses!;
  }
  // Cas 2: Charger depuis l'API via commandeId
  else if (widget.commandeId != null) {
    final commandeDetails = await PharmacyResponseService.getCommandeDetails(widget.commandeId!);
    reponses = commandeDetails.reponsesExistantes;
  }

  // Convertir les réponses en format d'affichage
  if (reponses.isNotEmpty) {
    setState(() {
      _pharmacies = reponses.map((response) {
        return {
          'id': response.pharmacieId,
          'name': response.pharmacie?.nom ?? 'Pharmacie',
          'address': response.pharmacie?.adresse ?? '',
          'availableCount': response.nombreProduitsDisponibles,
          'totalCount': response.nombreTotalProduits,
          'price': response.montantTotalPharmacie,
          'produitsDetails': response.produitsDisponibles.map((p) => {
            'nom': 'Produit #${p.produitId}',
            'disponible': p.disponible,
            'prix': p.prixUnitaire,
            'quantite': p.quantite,
          }).toList(),
        };
      }).toList();
    });
  }
}
```

##### État 3: `PrescriptionStatus.livree` (Pharmacie sélectionnée)
```dart
Widget _buildSelectedPharmacySection() {
  // Affiche la pharmacie sélectionnée pour la livraison
}
```

**Quand:** La commande a un `pharmacie_assignee_id` et `statut = 'validee'`

## 🐛 Débogage

### Logs Importants

#### Backend
```javascript
// commandeService.js - getCommandeStatus()
console.log('Récupération statut commande #' + id);
console.log('Nombre de réponses:', reponses.length);
```

#### Frontend
```dart
// pharmacy_responses_list_view.dart - _navigateToPharmacyResponses()
print('   - reponsesExistantes.length: ${commandeDetails.reponsesExistantes.length}');
print('   - Status: $status');

// pharmacy_responses_view.dart - _loadPharmacyResponses()
print('   - widget.commandeId: ${widget.commandeId}');
print('   - widget.pharmacyResponses?.length: ${widget.pharmacyResponses?.length}');
print('   - ${reponses.length} réponse(s) chargée(s)');
print('   - _pharmacies.length final: ${_pharmacies.length}');

// pharmacy_responses_view.dart - _buildPharmaciesSection()
print('   - widget.status: ${widget.status}');
print('   - _pharmacies.length: ${_pharmacies.length}');
```

### Vérifications à Faire

#### 1. Vérifier qu'une réponse existe dans la BDD
```sql
SELECT * FROM reponses_pharmacies WHERE commande_id = 8;
```

#### 2. Vérifier la réponse de l'API
```bash
curl -X GET "http://192.168.1.11:5000/api/client/commandes/8/status" \
  -H "Authorization: Bearer <votre_token>"
```

Chercher la clé `reponses_existantes` dans la réponse.

#### 3. Vérifier les logs Flutter
```bash
flutter logs | grep "🔍 DEBUG"
```

Chercher:
- `reponsesExistantes.length`
- `_pharmacies.length`
- `Status:`

### Problèmes Courants

#### Problème 1: "Analyse en cours" alors qu'il y a des réponses

**Symptômes:**
- L'API retourne `reponses_existantes` avec des données
- Le frontend affiche quand même "Analyse en cours"

**Causes possibles:**
1. **Statut mal défini** - Le statut est resté `enAttente` au lieu de `enCours`
   - **Solution:** Vérifier la ligne 421-423 de `pharmacy_responses_list_view.dart`

2. **Réponses non chargées** - `_pharmacies` est vide
   - **Solution:** Vérifier les logs de `_loadPharmacyResponses()`

3. **Statut surchargé** - Le widget `status` passé force `enAttente`
   - **Solution:** Vérifier le paramètre `status` lors de la navigation

#### Problème 2: Réponses vides alors que l'admin a répondu

**Causes possibles:**
1. **Token expiré** - L'API retourne 401
   - **Solution:** Se reconnecter

2. **Mauvais endpoint** - L'app appelle le mauvais endpoint
   - **Solution:** Vérifier que `/status` est appelé, pas `/reponses`

3. **Format de réponse incorrect** - Le parsing JSON échoue
   - **Solution:** Vérifier les logs de parsing dans `ReponsePharmacieApi.fromJson()`

#### Problème 3: Crash au parsing

**Symptômes:**
```
type 'String' is not a subtype of type 'int'
```

**Solution:**
Les helpers `_toInt()` et `_toDouble()` gèrent déjà les conversions.
Vérifier que tous les champs utilisent ces helpers dans les modèles.

## ✅ Checklist de Vérification

Quand un client dit "Analyse en cours ne montre pas les réponses":

- [ ] 1. Vérifier dans la BDD si des réponses existent
  ```sql
  SELECT * FROM reponses_pharmacies WHERE commande_id = <id>;
  ```

- [ ] 2. Vérifier la réponse de l'API `/status`
  - Clé `reponses_existantes` présente?
  - Longueur du tableau > 0?

- [ ] 3. Vérifier les logs Flutter
  - `reponsesExistantes.length` = ?
  - `_pharmacies.length` = ?
  - `widget.status` = ?

- [ ] 4. Vérifier la navigation
  - Quel statut est passé à `PharmacyResponsesView`?
  - Les `pharmacyResponses` sont-ils passés?

- [ ] 5. Vérifier le chargement
  - `_loadPharmacyResponses()` est appelé?
  - Les réponses sont converties en `_pharmacies`?

## 🚀 Améliorations Futures

### 1. Notifications Push
Quand une pharmacie répond, envoyer une notification au client.

### 2. Rafraîchissement Automatique
Rafraîchir automatiquement la liste des réponses toutes les 30 secondes quand `statut = enAttente`.

### 3. Statut Plus Détaillé
- `en_attente` → Aucune pharmacie contactée
- `en_analyse` → Pharmacies contactées, en attente de réponses
- `reponses_recues` → Au moins une réponse reçue
- `validee` → Pharmacie sélectionnée

### 4. Historique des Réponses
Garder un historique de toutes les modifications des réponses.

## 📞 Support

En cas de problème, vérifier dans l'ordre:
1. Les logs du backend Node.js
2. Les logs Flutter (rechercher "🔍 DEBUG")
3. La base de données directement
4. La réponse de l'API avec curl/Postman

---

**Dernière mise à jour:** 2025-11-04
**Version:** 1.0.0
