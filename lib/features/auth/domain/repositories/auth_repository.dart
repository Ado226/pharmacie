// Fichier: lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_result.dart';

/// Interface du repository d'authentification
/// Contrat que la Data Layer doit implémenter
abstract class AuthRepository {
  /// Inscription d'un nouveau client
  Future<Either<Failure, AuthResult>> registerClient({
    required String numero,
    required String password,
    String? nom,
    String? prenom,
  });

  /// Connexion d'un client
  Future<Either<Failure, AuthResult>> loginClient({
    required String numero,
    required String password,
  });

  /// Connexion d'un admin
  Future<Either<Failure, AuthResult>> loginAdmin({
    required String email,
    required String motDePasse,
  });

  /// Déconnexion
  Future<Either<Failure, bool>> logout();

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated();

  /// Récupérer le token actuel
  Future<String?> getToken();

  /// Récupérer les données utilisateur en cache
  Future<Map<String, dynamic>?> getCachedUser();
}
