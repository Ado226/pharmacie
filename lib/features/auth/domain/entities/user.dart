// Fichier: lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

/// Entity User (Domain Layer)
/// Représente un utilisateur dans le domaine
class User extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String? role;
  final String? adresse;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.role,
    this.adresse,
  });

  @override
  List<Object?> get props => [id, nom, prenom, email, telephone, role, adresse];

  @override
  String toString() =>
      'User(id: $id, nom: $nom, prenom: $prenom, email: $email)';

  /// Convertir l'utilisateur en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': role,
      'adresse': adresse,
    };
  }

  /// Créer un User depuis un Map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'],
      adresse: json['adresse'],
    );
  }
}
