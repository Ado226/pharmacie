// Data Layer - Repository Implementation
// Implémente le contrat du domaine et gère les erreurs

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/commande_detail_entity.dart';
import '../../domain/entities/reponse_pharmacie_entity.dart';
import '../../domain/repositories/pharmacy_response_repository.dart';
import '../datasources/pharmacy_response_remote_datasource.dart';

class PharmacyResponseRepositoryImpl implements PharmacyResponseRepository {
  final PharmacyResponseRemoteDataSource remoteDataSource;

  PharmacyResponseRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, CommandeDetailEntity>> getCommandeDetails(
    int commandeId,
  ) async {
    try {
      final result = await remoteDataSource.getCommandeDetails(commandeId);
      return Right(result);
    } on SocketException {
      return const Left(
        NetworkFailure('Erreur de connexion. Vérifiez votre connexion Internet.'),
      );
    } catch (e) {
      if (e.toString().contains('Token non trouvé') ||
          e.toString().contains('Session expirée')) {
        return Left(AuthenticationFailure(e.toString()));
      }
      if (e.toString().contains('Commande non trouvée')) {
        return Left(ServerFailure(e.toString()));
      }
      return Left(ServerFailure('Erreur lors de la récupération des détails: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ReponsePharmacieEntity>>> getReponsesForCommande(
    int commandeId,
  ) async {
    try {
      final result = await remoteDataSource.getReponsesForCommande(commandeId);
      return Right(result);
    } on SocketException {
      return const Left(
        NetworkFailure('Erreur de connexion. Vérifiez votre connexion Internet.'),
      );
    } catch (e) {
      if (e.toString().contains('Token non trouvé') ||
          e.toString().contains('Session expirée')) {
        return Left(AuthenticationFailure(e.toString()));
      }
      if (e.toString().contains('Commande non trouvée')) {
        return Left(ServerFailure(e.toString()));
      }
      return Left(ServerFailure('Erreur lors de la récupération des réponses: $e'));
    }
  }

  @override
  Future<Either<Failure, ReponsePharmacieEntity>> createReponsePharmacieForCommande({
    required int commandeId,
    required int pharmacieId,
    required List<Map<String, dynamic>> produitsDisponibles,
    String? commentairePharmacie,
  }) async {
    try {
      final result = await remoteDataSource.createReponsePharmacieForCommande(
        commandeId: commandeId,
        pharmacieId: pharmacieId,
        produitsDisponibles: produitsDisponibles,
        commentairePharmacie: commentairePharmacie,
      );
      return Right(result);
    } on SocketException {
      return const Left(
        NetworkFailure('Erreur de connexion. Vérifiez votre connexion Internet.'),
      );
    } catch (e) {
      if (e.toString().contains('Token non trouvé') ||
          e.toString().contains('Session expirée')) {
        return Left(AuthenticationFailure(e.toString()));
      }
      if (e.toString().contains('Données invalides')) {
        return Left(ValidationFailure(e.toString()));
      }
      return Left(ServerFailure('Erreur lors de la création de la réponse: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReponsePharmacie(int reponseId) async {
    try {
      await remoteDataSource.deleteReponsePharmacie(reponseId);
      return const Right(null);
    } on SocketException {
      return const Left(
        NetworkFailure('Erreur de connexion. Vérifiez votre connexion Internet.'),
      );
    } catch (e) {
      if (e.toString().contains('Token non trouvé') ||
          e.toString().contains('Session expirée')) {
        return Left(AuthenticationFailure(e.toString()));
      }
      if (e.toString().contains('Réponse non trouvée')) {
        return Left(ServerFailure(e.toString()));
      }
      return Left(ServerFailure('Erreur lors de la suppression: $e'));
    }
  }
}
