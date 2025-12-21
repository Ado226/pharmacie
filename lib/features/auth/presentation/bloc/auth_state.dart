// Fichier: lib/features/auth/presentation/bloc/auth_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// States pour AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Chargement en cours
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authentifié avec succès
class Authenticated extends AuthState {
  final User user;
  final String token;

  const Authenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object> get props => [user, token];
}

/// Non authentifié
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Erreur d'authentification
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

/// Inscription réussie
class RegisterSuccess extends AuthState {
  final User user;
  final String token;

  const RegisterSuccess({
    required this.user,
    required this.token,
  });

  @override
  List<Object> get props => [user, token];
}

/// Connexion réussie
class LoginSuccess extends AuthState {
  final User user;
  final String token;

  const LoginSuccess({
    required this.user,
    required this.token,
  });

  @override
  List<Object> get props => [user, token];
}

/// Déconnexion réussie
class LogoutSuccess extends AuthState {
  const LogoutSuccess();
}
