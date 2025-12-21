// Fichier: lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

/// Implémentation du repository d'authentification
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthResult>> registerClient({
    required String numero,
    required String password,
    String? nom,
    String? prenom,
  }) async {
    try {
      final authResult = await remoteDataSource.registerClient(
        numero: numero,
        password: password,
        nom: nom,
        prenom: prenom,
      );

      // Sauvegarder le token et les données utilisateur localement
      await localDataSource.cacheToken(authResult.token);
      await localDataSource.cacheUser(authResult.user.toJson());

      return Right(authResult);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      // Même si le cache échoue, on retourne quand même le résultat
      print('Erreur cache lors de l\'inscription: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> loginClient({
    required String numero,
    required String password,
  }) async {
    try {
      final authResult = await remoteDataSource.loginClient(
        numero: numero,
        password: password,
      );

      // Sauvegarder le token et les données utilisateur localement
      await localDataSource.cacheToken(authResult.token);
      await localDataSource.cacheUser(authResult.user.toJson());

      return Right(authResult);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      print('Erreur cache lors de la connexion: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> loginAdmin({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final authResult = await remoteDataSource.loginAdmin(
        email: email,
        motDePasse: motDePasse,
      );

      // Sauvegarder le token localement
      await localDataSource.cacheToken(authResult.token);

      return Right(authResult);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await localDataSource.clearAll(); // Supprimer token ET user
      return const Right(true);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur lors de la déconnexion: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await localDataSource.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await localDataSource.getCachedToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedUser() async {
    try {
      return await localDataSource.getCachedUser();
    } catch (e) {
      return null;
    }
  }
}
