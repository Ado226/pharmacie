// Data Layer - Réponse Pharmacie Model
// Convertit JSON ↔ Entity

import '../../domain/entities/reponse_pharmacie_entity.dart';
import 'pharmacie_model.dart';

class ReponsePharmacieModel extends ReponsePharmacieEntity {
  const ReponsePharmacieModel({
    required super.id,
    required super.commandeId,
    required super.pharmacieId,
    required super.contactee,
    required super.reponseObtenue,
    required super.produitsDisponibles,
    super.produitsRemplacement,
    required super.montantTotalPharmacie,
    super.commentairePharmacie,
    super.contacteLe,
    required super.createdAt,
    super.pharmacie,
  });

  factory ReponsePharmacieModel.fromJson(Map<String, dynamic> json) {
    return ReponsePharmacieModel(
      id: json['id'],
      commandeId: json['commande_id'],
      pharmacieId: json['pharmacie_id'],
      contactee: json['contactee'] ?? false,
      reponseObtenue: json['reponse_obtenue'] ?? false,
      produitsDisponibles: (json['produits_disponibles'] as List<dynamic>?)
              ?.map((p) => ProduitDisponibleModel.fromJson(p))
              .toList() ??
          [],
      produitsRemplacement: json['produits_remplacement'],
      montantTotalPharmacie: (json['montant_total_pharmacie'] as num).toDouble(),
      commentairePharmacie: json['commentaire_pharmacie'],
      contacteLe: json['contacte_le'] != null
          ? DateTime.parse(json['contacte_le'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      pharmacie: json['Pharmacie'] != null
          ? PharmacieInfoModel.fromJson(json['Pharmacie'])
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
      'produits_disponibles': produitsDisponibles
          .map((p) => (p as ProduitDisponibleModel).toJson())
          .toList(),
      'produits_remplacement': produitsRemplacement,
      'montant_total_pharmacie': montantTotalPharmacie,
      'commentaire_pharmacie': commentairePharmacie,
      'contacte_le': contacteLe?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProduitDisponibleModel extends ProduitDisponibleEntity {
  const ProduitDisponibleModel({
    required super.produitId,
    required super.disponible,
    super.prixUnitaire,
    super.quantite,
    super.prixTotal,
  });

  factory ProduitDisponibleModel.fromJson(Map<String, dynamic> json) {
    return ProduitDisponibleModel(
      produitId: json['produit_id'],
      disponible: json['disponible'] ?? false,
      prixUnitaire: json['prix_unitaire'] != null
          ? (json['prix_unitaire'] as num).toDouble()
          : null,
      quantite: json['quantite'],
      prixTotal: json['prix_total'] != null
          ? (json['prix_total'] as num).toDouble()
          : null,
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
