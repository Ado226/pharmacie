// Domain Entity - Commande Detail
// Représente la réponse complète avec commande, pharmacies et réponses

import 'package:equatable/equatable.dart';
import 'commande_entity.dart';
import 'pharmacie_entity.dart';
import 'reponse_pharmacie_entity.dart';

class CommandeDetailEntity extends Equatable {
  final CommandeEntity commande;
  final List<PharmacieProximiteEntity> pharmaciesProximite;
  final List<ReponsePharmacieEntity> reponsesExistantes;

  const CommandeDetailEntity({
    required this.commande,
    required this.pharmaciesProximite,
    required this.reponsesExistantes,
  });

  /// Logique métier: Vérifier si des réponses ont été reçues
  bool get hasReponses => reponsesExistantes.isNotEmpty;

  /// Logique métier: Vérifier si des pharmacies ont été contactées
  bool get hasPharmaciesContactees => pharmaciesProximite.isNotEmpty;

  /// Logique métier: Obtenir le nombre de pharmacies qui ont répondu
  int get nombrePharmaciesRepondu => reponsesExistantes.length;

  /// Logique métier: Obtenir le nombre de pharmacies contactées
  int get nombrePharmaciesContactees => pharmaciesProximite.length;

  @override
  List<Object?> get props => [
        commande,
        pharmaciesProximite,
        reponsesExistantes,
      ];
}
