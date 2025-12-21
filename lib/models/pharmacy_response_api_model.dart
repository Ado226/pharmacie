// Fichier: lib/models/pharmacy_response_api_model.dart

/// Modèle pour une pharmacie proche
class PharmacieProximite {
  final int pharmacieId;
  final String nom;
  final String adresse;
  final String quartier;
  final String? numeroTelephone;
  final String? email;
  final double distanceMetres;
  final int rangProximite;

  PharmacieProximite({
    required this.pharmacieId,
    required this.nom,
    required this.adresse,
    required this.quartier,
    this.numeroTelephone,
    this.email,
    required this.distanceMetres,
    required this.rangProximite,
  });

  factory PharmacieProximite.fromJson(Map<String, dynamic> json) {
    // Helper pour convertir String/int en int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    // Helper pour convertir String/num en double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return PharmacieProximite(
      pharmacieId: _toInt(json['pharmacie_id']),
      nom: json['nom'],
      adresse: json['adresse'],
      quartier: json['quartier'],
      numeroTelephone: json['numero_telephone'],
      email: json['email'],
      distanceMetres: _toDouble(json['distance_metres']),
      rangProximite: _toInt(json['rang_proximite']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pharmacie_id': pharmacieId,
      'nom': nom,
      'adresse': adresse,
      'quartier': quartier,
      'numero_telephone': numeroTelephone,
      'email': email,
      'distance_metres': distanceMetres,
      'rang_proximite': rangProximite,
    };
  }
}

/// Modèle pour un produit de commande
class CommandeProduitApi {
  final int id;
  final int commandeId;
  final int produitId;
  final int quantite;
  final String ageCible;
  final String? nomProduitPersonnalise;
  final bool? disponible;
  final double? prixUnitaire;
  final Map<String, dynamic>? produit;

  CommandeProduitApi({
    required this.id,
    required this.commandeId,
    required this.produitId,
    required this.quantite,
    required this.ageCible,
    this.nomProduitPersonnalise,
    this.disponible,
    this.prixUnitaire,
    this.produit,
  });

  factory CommandeProduitApi.fromJson(Map<String, dynamic> json) {
    print('   🔧 DEBUG CommandeProduitApi.fromJson:');
    print('      - json keys: ${json.keys.toList()}');
    print('      - produit_id: ${json['produit_id']} (${json['produit_id'].runtimeType})');
    print('      - quantite: ${json['quantite']} (${json['quantite'].runtimeType})');

    // Le backend peut retourner soit 'Produit' (capitalisé), soit 'produit' (minuscule)
    Map<String, dynamic>? produitData = json['Produit'];
    if (produitData == null) {
      produitData = json['produit'];
    }
    print('      - produitData present: ${produitData != null}');

    // Fonction helper pour convertir String/int en int
    int _toInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is num) return value.toInt();
      return defaultValue;
    }

    // Fonction helper pour convertir String/num en double
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    return CommandeProduitApi(
      id: _toInt(json['id'], 0),
      commandeId: _toInt(json['commande_id'], 0),
      produitId: _toInt(json['produit_id'], 0),
      quantite: _toInt(json['quantite'], 1),
      ageCible: json['age_cible'] ?? 'adulte',
      nomProduitPersonnalise: json['nom_produit_personnalise'],
      disponible: json['disponible'],
      prixUnitaire: _toDouble(json['prix_unitaire']),
      produit: produitData,
    );
  }

  String get nomProduit {
    if (nomProduitPersonnalise != null && nomProduitPersonnalise!.isNotEmpty) {
      return nomProduitPersonnalise!;
    }
    if (produit != null && produit!['nom'] != null) {
      return produit!['nom'];
    }
    return 'Produit #$produitId';
  }
}

/// Modèle pour une commande avec détails
class CommandeApi {
  final int id;
  final int clientId;
  final String typeCommande;
  final String statut;
  final String? ordonnancePhotoUrl;
  final double? montantTotal;
  final int? pharmacieAssigneeId;
  final String? nomPatient;
  final DateTime createdAt;
  final List<CommandeProduitApi> commandeProduits;

  CommandeApi({
    required this.id,
    required this.clientId,
    required this.typeCommande,
    required this.statut,
    this.ordonnancePhotoUrl,
    this.montantTotal,
    this.pharmacieAssigneeId,
    this.nomPatient,
    required this.createdAt,
    required this.commandeProduits,
  });

  /// Getter pour accéder aux produits de la commande
  List<CommandeProduitApi> get produits => commandeProduits;

  factory CommandeApi.fromJson(Map<String, dynamic> json) {
    // Le backend peut retourner soit 'CommandeProduits' (liste), soit 'produits' (status)
    List<dynamic>? produitsData = json['CommandeProduits'] as List?;
    if (produitsData == null || produitsData.isEmpty) {
      produitsData = json['produits'] as List?;
    }

    print('📦 DEBUG CommandeApi.fromJson:');
    print('   - produitsData type: ${produitsData.runtimeType}');
    print('   - produitsData length: ${produitsData?.length ?? 0}');

    // Fonction helper pour convertir String/int en int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    // Fonction helper pour convertir String/int en int nullable
    int? _toIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    // Fonction helper pour convertir String/num en double nullable
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    return CommandeApi(
      id: _toInt(json['id']),
      clientId: _toInt(json['client_id']),
      typeCommande: json['type_commande'],
      statut: json['statut'],
      ordonnancePhotoUrl: json['ordonnance_photo_url'],
      montantTotal: _toDouble(json['montant_total']),
      pharmacieAssigneeId: _toIntNullable(json['pharmacie_assignee_id']),
      nomPatient: json['nom_patient'],
      createdAt: DateTime.parse(json['created_at']),
      commandeProduits: produitsData
              ?.map((p) {
                print('   - Parsing produit: ${p.runtimeType}');
                return CommandeProduitApi.fromJson(p);
              })
              .toList() ??
          [],
    );
  }
}

/// Modèle pour la réponse complète des détails de commande
class CommandeDetailResponse {
  final CommandeApi commande;
  final List<PharmacieProximite> pharmaciesProximite;
  final List<ReponsePharmacieApi> reponsesExistantes;

  CommandeDetailResponse({
    required this.commande,
    required this.pharmaciesProximite,
    required this.reponsesExistantes,
  });

  factory CommandeDetailResponse.fromJson(Map<String, dynamic> json) {
    // Le backend /status retourne une structure plate, pas imbriquée
    // Il faut vérifier si 'commande' existe (structure imbriquée) ou non (structure plate)
    bool isNestedStructure = json.containsKey('commande');

    print('📋 DEBUG CommandeDetailResponse.fromJson:');
    print('   - isNestedStructure: $isNestedStructure');
    print('   - reponses_existantes key exists: ${json.containsKey('reponses_existantes')}');
    print('   - reponses_existantes type: ${json['reponses_existantes']?.runtimeType}');
    print('   - reponses_existantes length: ${json['reponses_existantes'] is List ? (json['reponses_existantes'] as List).length : 'N/A'}');

    final reponsesData = json['reponses_existantes'] as List?;
    final reponses = reponsesData?.map((r) {
      print('   - Parsing reponse: ${r.runtimeType}');
      return ReponsePharmacieApi.fromJson(r);
    }).toList() ?? [];

    print('   - Nombre de reponses parsées: ${reponses.length}');

    return CommandeDetailResponse(
      commande: isNestedStructure
          ? CommandeApi.fromJson(json['commande'])
          : CommandeApi.fromJson(json), // Structure plate
      pharmaciesProximite: (json['pharmacies_proximite'] as List?)
              ?.map((p) => PharmacieProximite.fromJson(p))
              .toList() ??
          [],
      reponsesExistantes: reponses,
    );
  }
}

/// Modèle pour un produit disponible dans une réponse pharmacie
class ProduitDisponible {
  final int produitId;
  final bool disponible;
  final double? prixUnitaire;
  final int? quantite;
  final double? prixTotal;

  ProduitDisponible({
    required this.produitId,
    required this.disponible,
    this.prixUnitaire,
    this.quantite,
    this.prixTotal,
  });

  factory ProduitDisponible.fromJson(Map<String, dynamic> json) {
    // Helper pour convertir String/int en int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    // Helper pour convertir String/num en double nullable
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    // Helper pour convertir String/int en int nullable
    int? _toIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    return ProduitDisponible(
      produitId: _toInt(json['produit_id']),
      disponible: json['disponible'] ?? false,
      prixUnitaire: _toDouble(json['prix_unitaire']),
      quantite: _toIntNullable(json['quantite']),
      prixTotal: _toDouble(json['prix_total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produit_id': produitId,
      'disponible': disponible,
      'prix_unitaire': prixUnitaire,
      'quantite': quantite,
      'prix_total': prixTotal,
    };
  }
}

/// Modèle pour une pharmacie (info basique)
class PharmacieInfo {
  final int id;
  final String nom;
  final String adresse;
  final String quartier;
  final String? numeroTelephone;
  final String? email;

  PharmacieInfo({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.quartier,
    this.numeroTelephone,
    this.email,
  });

  factory PharmacieInfo.fromJson(Map<String, dynamic> json) {
    // Helper pour convertir String/int en int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    return PharmacieInfo(
      id: _toInt(json['id']),
      nom: json['nom'],
      adresse: json['adresse'],
      quartier: json['quartier'],
      numeroTelephone: json['numero_telephone'],
      email: json['email'],
    );
  }
}

/// Modèle pour une réponse pharmacie
class ReponsePharmacieApi {
  final int id;
  final int commandeId;
  final int pharmacieId;
  final bool contactee;
  final bool reponseObtenue;
  final List<ProduitDisponible> produitsDisponibles;
  final List<dynamic>? produitsRemplacement;
  final double montantTotalPharmacie;
  final String? commentairePharmacie;
  final DateTime? contacteLe;
  final DateTime createdAt;
  final PharmacieInfo? pharmacie;

  ReponsePharmacieApi({
    required this.id,
    required this.commandeId,
    required this.pharmacieId,
    required this.contactee,
    required this.reponseObtenue,
    required this.produitsDisponibles,
    this.produitsRemplacement,
    required this.montantTotalPharmacie,
    this.commentairePharmacie,
    this.contacteLe,
    required this.createdAt,
    this.pharmacie,
  });

  factory ReponsePharmacieApi.fromJson(Map<String, dynamic> json) {
    // Helper pour convertir String/int en int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    // Helper pour convertir String/num en double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return ReponsePharmacieApi(
      id: _toInt(json['id']),
      commandeId: _toInt(json['commande_id']),
      pharmacieId: _toInt(json['pharmacie_id']),
      contactee: json['contactee'] ?? false,
      reponseObtenue: json['reponse_obtenue'] ?? false,
      produitsDisponibles: (json['produits_disponibles'] as List?)
              ?.map((p) => ProduitDisponible.fromJson(p))
              .toList() ??
          [],
      produitsRemplacement: json['produits_remplacement'],
      montantTotalPharmacie: _toDouble(json['montant_total_pharmacie']),
      commentairePharmacie: json['commentaire_pharmacie'],
      contacteLe: json['contacte_le'] != null
          ? DateTime.parse(json['contacte_le'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      pharmacie: json['Pharmacie'] != null
          ? PharmacieInfo.fromJson(json['Pharmacie'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commande_id': commandeId,
      'pharmacie_id': pharmacieId,
      'contactee': contactee,
      'reponse_obtenue': reponseObtenue,
      'produits_disponibles': produitsDisponibles.map((p) => p.toJson()).toList(),
      'produits_remplacement': produitsRemplacement,
      'montant_total_pharmacie': montantTotalPharmacie,
      'commentaire_pharmacie': commentairePharmacie,
      'contacte_le': contacteLe?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Calculer le nombre de produits disponibles
  int get nombreProduitsDisponibles {
    return produitsDisponibles.where((p) => p.disponible).length;
  }

  /// Calculer le nombre total de produits
  int get nombreTotalProduits {
    return produitsDisponibles.length;
  }

  /// Calculer le pourcentage de disponibilité
  double get pourcentageDisponibilite {
    if (nombreTotalProduits == 0) return 0.0;
    return (nombreProduitsDisponibles / nombreTotalProduits) * 100;
  }

  /// Vérifier si tous les produits sont disponibles
  bool get tousProduitsDiponibles {
    return nombreProduitsDisponibles == nombreTotalProduits;
  }
}
