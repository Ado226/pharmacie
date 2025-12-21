// Domain Entity - Réponse Pharmacie
// Représente la réponse d'une pharmacie avec logique métier

import 'package:equatable/equatable.dart';
import 'pharmacie_entity.dart';

class ReponsePharmacieEntity extends Equatable {
  final int id;
  final int commandeId;
  final int pharmacieId;
  final bool contactee;
  final bool reponseObtenue;
  final List<ProduitDisponibleEntity> produitsDisponibles;
  final List<dynamic>? produitsRemplacement;
  final double montantTotalPharmacie;
  final String? commentairePharmacie;
  final DateTime? contacteLe;
  final DateTime createdAt;
  final PharmacieInfoEntity? pharmacie;

  const ReponsePharmacieEntity({
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

  /// Logique métier: Calculer le nombre de produits disponibles
  int get nombreProduitsDisponibles {
    return produitsDisponibles.where((p) => p.disponible).length;
  }

  /// Logique métier: Calculer le nombre total de produits
  int get nombreTotalProduits {
    return produitsDisponibles.length;
  }

  /// Logique métier: Calculer le pourcentage de disponibilité
  double get pourcentageDisponibilite {
    if (nombreTotalProduits == 0) return 0.0;
    return (nombreProduitsDisponibles / nombreTotalProduits) * 100;
  }

  /// Logique métier: Vérifier si tous les produits sont disponibles
  bool get tousProduitsDiponibles {
    return nombreProduitsDisponibles == nombreTotalProduits;
  }

  /// Logique métier: Vérifier si aucun produit n'est disponible
  bool get aucunProduitDisponible {
    return nombreProduitsDisponibles == 0;
  }

  @override
  List<Object?> get props => [
        id,
        commandeId,
        pharmacieId,
        contactee,
        reponseObtenue,
        produitsDisponibles,
        produitsRemplacement,
        montantTotalPharmacie,
        commentairePharmacie,
        contacteLe,
        createdAt,
        pharmacie,
      ];
}

class ProduitDisponibleEntity extends Equatable {
  final int produitId;
  final bool disponible;
  final double? prixUnitaire;
  final int? quantite;
  final double? prixTotal;

  const ProduitDisponibleEntity({
    required this.produitId,
    required this.disponible,
    this.prixUnitaire,
    this.quantite,
    this.prixTotal,
  });

  @override
  List<Object?> get props => [
        produitId,
        disponible,
        prixUnitaire,
        quantite,
        prixTotal,
      ];
}
