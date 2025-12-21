// Fichier: lib/features/auth/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

/// Events pour AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Inscription d'un client
class RegisterClientEvent extends AuthEvent {
  final String numero;
  final String password;
  final String? nom;
  final String? prenom;

  const RegisterClientEvent({
    required this.numero,
    required this.password,
    this.nom,
    this.prenom,
  });

  @override
  List<Object?> get props => [numero, password, nom, prenom];
}

/// Event: Connexion d'un client
class LoginClientEvent extends AuthEvent {
  final String numero;
  final String password;

  const LoginClientEvent({
    required this.numero,
    required this.password,
  });

  @override
  List<Object> get props => [numero, password];
}

/// Event: Connexion admin
class LoginAdminEvent extends AuthEvent {
  final String email;
  final String motDePasse;

  const LoginAdminEvent({
    required this.email,
    required this.motDePasse,
  });

  @override
  List<Object> get props => [email, motDePasse];
}

/// Event: Déconnexion
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Event: Vérifier si authentifié
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}
