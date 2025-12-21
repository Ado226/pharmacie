// Data Layer - Commande Detail Model
// Convertit JSON ↔ Entity

import '../../domain/entities/commande_detail_entity.dart';
import 'commande_model.dart';
import 'pharmacie_model.dart';
import 'reponse_pharmacie_model.dart';

class CommandeDetailModel extends CommandeDetailEntity {
  const CommandeDetailModel({
    required super.commande,
    required super.pharmaciesProximite,
    required super.reponsesExistantes,
  });

  factory CommandeDetailModel.fromJson(Map<String, dynamic> json) {
    return CommandeDetailModel(
      commande: CommandeModel.fromJson(json['commande']),
      pharmaciesProximite: (json['pharmacies_proximite'] as List<dynamic>?)
              ?.map((p) => PharmacieProximiteModel.fromJson(p))
              .toList() ??
          [],
      reponsesExistantes: (json['reponses_existantes'] as List<dynamic>?)
              ?.map((r) => ReponsePharmacieModel.fromJson(r))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commande': (commande as CommandeModel).toJson(),
      'pharmacies_proximite': pharmaciesProximite
          .map((p) => (p as PharmacieProximiteModel).toJson())
          .toList(),
      'reponses_existantes': reponsesExistantes
          .map((r) => (r as ReponsePharmacieModel).toJson())
          .toList(),
    };
  }
}
