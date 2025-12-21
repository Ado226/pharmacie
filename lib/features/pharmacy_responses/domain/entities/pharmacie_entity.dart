// Domain Entity - Pharmacie
// Représente une pharmacie avec ses informations de base et distance

import 'package:equatable/equatable.dart';

class PharmacieProximiteEntity extends Equatable {
  final int pharmacieId;
  final String nom;
  final String adresse;
  final String quartier;
  final String? numeroTelephone;
  final String? email;
  final double distanceMetres;
  final int rangProximite;

  const PharmacieProximiteEntity({
    required this.pharmacieId,
    required this.nom,
    required this.adresse,
    required this.quartier,
    this.numeroTelephone,
    this.email,
    required this.distanceMetres,
    required this.rangProximite,
  });

  double get distanceKm => distanceMetres / 1000;

  @override
  List<Object?> get props => [
        pharmacieId,
        nom,
        adresse,
        quartier,
        numeroTelephone,
        email,
        distanceMetres,
        rangProximite,
      ];
}

class PharmacieInfoEntity extends Equatable {
  final int id;
  final String nom;
  final String adresse;
  final String quartier;
  final String? numeroTelephone;
  final String? email;

  const PharmacieInfoEntity({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.quartier,
    this.numeroTelephone,
    this.email,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        adresse,
        quartier,
        numeroTelephone,
        email,
      ];
}
