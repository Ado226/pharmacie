// Domain Entity - Commande
// Les entités représentent les objets métier purs sans dépendances externes

import 'package:equatable/equatable.dart';

class CommandeEntity extends Equatable {
  final int id;
  final int clientId;
  final String typeCommande;
  final String statut;
  final String? ordonnancePhotoUrl;
  final String? nomPatient;
  final double? montantTotal;
  final int? pharmacieAssigneeId;
  final DateTime createdAt;
  final List<CommandeProduitEntity> commandeProduits;

  const CommandeEntity({
    required this.id,
    required this.clientId,
    required this.typeCommande,
    required this.statut,
    this.ordonnancePhotoUrl,
    this.nomPatient,
    this.montantTotal,
    this.pharmacieAssigneeId,
    required this.createdAt,
    required this.commandeProduits,
  });

  /// Retourne le nom du patient ou une valeur par défaut
  String get displayPatientName {
    if (nomPatient != null && nomPatient!.isNotEmpty) {
      return nomPatient!;
    }
    return 'Patient non renseigné';
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        typeCommande,
        statut,
        ordonnancePhotoUrl,
        nomPatient,
        montantTotal,
        pharmacieAssigneeId,
        createdAt,
        commandeProduits,
      ];
}

class CommandeProduitEntity extends Equatable {
  final int id;
  final int commandeId;
  final int produitId;
  final int quantite;
  final String ageCible;
  final String? nomProduitPersonnalise;
  final bool? disponible;
  final double? prixUnitaire;
  final String? nomProduit;

  const CommandeProduitEntity({
    required this.id,
    required this.commandeId,
    required this.produitId,
    required this.quantite,
    required this.ageCible,
    this.nomProduitPersonnalise,
    this.disponible,
    this.prixUnitaire,
    this.nomProduit,
  });

  String get displayName {
    if (nomProduitPersonnalise != null && nomProduitPersonnalise!.isNotEmpty) {
      return nomProduitPersonnalise!;
    }
    if (nomProduit != null && nomProduit!.isNotEmpty) {
      return nomProduit!;
    }
    return 'Produit #$produitId';
  }

  @override
  List<Object?> get props => [
        id,
        commandeId,
        produitId,
        quantite,
        ageCible,
        nomProduitPersonnalise,
        disponible,
        prixUnitaire,
        nomProduit,
      ];
}
