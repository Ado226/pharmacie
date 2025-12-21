// Data Layer - Commande Model
// Convertit JSON ↔ Entity

import '../../domain/entities/commande_entity.dart';

class CommandeModel extends CommandeEntity {
  const CommandeModel({
    required super.id,
    required super.clientId,
    required super.typeCommande,
    required super.statut,
    super.ordonnancePhotoUrl,
    super.nomPatient,
    super.montantTotal,
    super.pharmacieAssigneeId,
    required super.createdAt,
    required super.commandeProduits,
  });

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id: json['id'],
      clientId: json['client_id'],
      typeCommande: json['type_commande'],
      statut: json['statut'],
      ordonnancePhotoUrl: json['ordonnance_photo_url'],
      nomPatient: json['nom_patient'],
      montantTotal: json['montant_total'] != null
          ? (json['montant_total'] as num).toDouble()
          : null,
      pharmacieAssigneeId: json['pharmacie_assignee_id'],
      createdAt: DateTime.parse(json['created_at']),
      commandeProduits: (json['CommandeProduits'] as List<dynamic>?)
              ?.map((p) => CommandeProduitModel.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'type_commande': typeCommande,
      'statut': statut,
      'ordonnance_photo_url': ordonnancePhotoUrl,
      'nom_patient': nomPatient,
      'montant_total': montantTotal,
      'pharmacie_assignee_id': pharmacieAssigneeId,
      'created_at': createdAt.toIso8601String(),
      'CommandeProduits': commandeProduits
          .map((p) => (p as CommandeProduitModel).toJson())
          .toList(),
    };
  }
}

class CommandeProduitModel extends CommandeProduitEntity {
  const CommandeProduitModel({
    required super.id,
    required super.commandeId,
    required super.produitId,
    required super.quantite,
    required super.ageCible,
    super.nomProduitPersonnalise,
    super.disponible,
    super.prixUnitaire,
    super.nomProduit,
  });

  factory CommandeProduitModel.fromJson(Map<String, dynamic> json) {
    return CommandeProduitModel(
      id: json['id'],
      commandeId: json['commande_id'],
      produitId: json['produit_id'],
      quantite: json['quantite'],
      ageCible: json['age_cible'],
      nomProduitPersonnalise: json['nom_produit_personnalise'],
      disponible: json['disponible'],
      prixUnitaire: json['prix_unitaire'] != null
          ? (json['prix_unitaire'] as num).toDouble()
          : null,
      nomProduit: json['Produit'] != null ? json['Produit']['nom'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commande_id': commandeId,
      'produit_id': produitId,
      'quantite': quantite,
      'age_cible': ageCible,
      'nom_produit_personnalise': nomProduitPersonnalise,
      'disponible': disponible,
      'prix_unitaire': prixUnitaire,
    };
  }
}
