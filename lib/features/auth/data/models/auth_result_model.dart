// Fichier: lib/features/auth/data/models/auth_result_model.dart
import '../../domain/entities/auth_result.dart';
import 'user_model.dart';

/// Model AuthResult
class AuthResultModel extends AuthResult {
  const AuthResultModel({
    required super.user,
    required super.token,
  });

  /// Créer depuis JSON (Backend Node.js)
  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    return AuthResultModel(
      user: UserModel.fromJson(json['user'] ?? json['client'] ?? json['admin']),
      token: json['token'] ?? '',
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'user': (user as UserModel).toJson(),
      'token': token,
    };
  }
}
