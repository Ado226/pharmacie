// Fichier: lib/features/prescription/data/repositories/prescription_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../datasources/prescription_local_datasource.dart';
import '../datasources/prescription_remote_datasource.dart';
import '../models/prescription_model.dart';

/// Implémentation du Repository
/// CETTE CLASSE DÉCIDE entre remote et local selon la connexion
class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionRemoteDataSource remoteDataSource;
  final PrescriptionLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PrescriptionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Prescription>>> getAllPrescriptions() async {
    try {
      // Vérifier la connexion internet
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        // En ligne : récupérer depuis l'API
        final remotePrescriptions = await remoteDataSource.getAllPrescriptions();

        // Mettre en cache
        await localDataSource.cachePrescriptions(remotePrescriptions);

        return Right(remotePrescriptions);
      } else {
        // Hors ligne : récupérer depuis le cache
        final localPrescriptions = await localDataSource.getCachedPrescriptions();
        return Right(localPrescriptions);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, Prescription>> getPrescriptionById(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        final remotePrescription = await remoteDataSource.getPrescriptionById(id);
        await localDataSource.cachePrescription(remotePrescription);
        return Right(remotePrescription);
      } else {
        final localPrescription = await localDataSource.getCachedPrescriptionById(id);
        return Right(localPrescription);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createPrescription(Prescription prescription) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return const Left(NetworkFailure('Pas de connexion internet pour créer une prescription'));
      }

      final prescriptionModel = PrescriptionModel.fromEntity(prescription);
      final prescriptionId = await remoteDataSource.createPrescription(prescriptionModel);

      // Mettre en cache
      await localDataSource.cachePrescription(prescriptionModel.copyWith(id: prescriptionId) as PrescriptionModel);

      return Right(prescriptionId);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePrescription(Prescription prescription) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return const Left(NetworkFailure('Pas de connexion internet pour mettre à jour une prescription'));
      }

      final prescriptionModel = PrescriptionModel.fromEntity(prescription);
      final success = await remoteDataSource.updatePrescription(prescriptionModel);

      if (success) {
        await localDataSource.cachePrescription(prescriptionModel);
      }

      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePrescription(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (!isConnected) {
        return const Left(NetworkFailure('Pas de connexion internet pour supprimer une prescription'));
      }

      final success = await remoteDataSource.deletePrescription(id);

      if (success) {
        await localDataSource.deleteCachedPrescription(id);
      }

      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }
}
