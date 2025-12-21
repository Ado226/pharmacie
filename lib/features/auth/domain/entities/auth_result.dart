// Fichier: lib/features/auth/domain/entities/auth_result.dart
import 'package:equatable/equatable.dart';
import 'user.dart';

/// Résultat d'authentification
class AuthResult extends Equatable {
  final User user;
  final String token;

  const AuthResult({
    required this.user,
    required this.token,
  });

  @override
  List<Object> get props => [user, token];

  @override
  String toString() => 'AuthResult(user: ${user.email}, token: ${token.substring(0, 10)}...)';
}
