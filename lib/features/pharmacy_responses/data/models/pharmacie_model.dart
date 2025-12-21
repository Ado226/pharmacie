// Data Layer - Pharmacie Model
// Convertit JSON ↔ Entity

import '../../domain/entities/pharmacie_entity.dart';

class PharmacieProximiteModel extends PharmacieProximiteEntity {
  const PharmacieProximiteModel({
    required super.pharmacieId,
    required super.nom,
    required super.adresse,
    required super.quartier,
    super.numeroTelephone,
    super.email,
    required super.distanceMetres,
    required super.rangProximite,
  });

  factory PharmacieProximiteModel.fromJson(Map<String, dynamic> json) {
    return PharmacieProximiteModel(
      pharmacieId: json['pharmacie_id'],
      nom: json['nom'],
      adresse: json['adresse'],
      quartier: json['quartier'],
      numeroTelephone: json['numero_telephone'],
      email: json['email'],
      distanceMetres: (json['distance_metres'] as num).toDouble(),
      rangProximite: json['rang_proximite'],
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

class PharmacieInfoModel extends PharmacieInfoEntity {
  const PharmacieInfoModel({
    required super.id,
    required super.nom,
    required super.adresse,
    required super.quartier,
    super.numeroTelephone,
    super.email,
  });

  factory PharmacieInfoModel.fromJson(Map<String, dynamic> json) {
    return PharmacieInfoModel(
      id: json['id'],
      nom: json['nom'],
      adresse: json['adresse'],
      quartier: json['quartier'],
      numeroTelephone: json['numero_telephone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'quartier': quartier,
      'numero_telephone': numeroTelephone,
      'email': email,
    };
  }
}
