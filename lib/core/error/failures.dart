// Fichier: lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

/// Classe abstraite pour représenter les erreurs métier
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Erreurs réseau
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

// Erreurs locales
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

// Erreurs de validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Erreurs d'authentification
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

// Erreurs génériques
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
