// Fichier: lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user.dart';

/// Model User (Data Layer - DTO)
/// Gère la sérialisation/désérialisation JSON
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.telephone,
    super.role,
    super.adresse,
  });

  /// Créer depuis JSON (Backend Node.js)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['numero'] ?? json['telephone'] ?? '', // Backend utilise 'numero'
      role: json['role'],
      adresse: json['adresse'],
    );
  }

  /// Convertir en JSON
  @override
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

  /// Créer depuis Entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      nom: user.nom,
      prenom: user.prenom,
      email: user.email,
      telephone: user.telephone,
      role: user.role,
      adresse: user.adresse,
    );
  }

  /// Convertir en Entity
  User toEntity() {
    return User(
      id: id,
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      role: role,
      adresse: adresse,
    );
  }
}
