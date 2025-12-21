// Fichier: lib/features/prescription/data/repositories/prescription_api_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../datasources/prescription_local_datasource.dart';
import '../datasources/prescription_api_datasource.dart';
import '../models/prescription_model.dart';

/// Repository pour BACKEND NODE.JS
class PrescriptionApiRepositoryImpl implements PrescriptionRepository {
  final PrescriptionApiDataSource apiDataSource;
  final PrescriptionLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AuthRepository authRepository;

  PrescriptionApiRepositoryImpl({
    required this.apiDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.authRepository,
  });

  /// Configurer le token d'authentification avant chaque appel API
  Future<void> _setupAuthToken() async {
    final token = await authRepository.getToken();
    if (token != null) {
      apiDataSource.setAuthToken(token);
    }
  }

  @override
  Future<Either<Failure, List<Prescription>>> getAllPrescriptions() async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        // Configurer le token d'authentification
        await _setupAuthToken();

        // En ligne : récupérer depuis l'API Node.js
        final apiPrescriptions = await apiDataSource.getAllPrescriptions();

        // Mettre en cache
        await localDataSource.cachePrescriptions(apiPrescriptions);

        return Right(apiPrescriptions);
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
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, Prescription>> getPrescriptionById(String id) async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        // Configurer le token d'authentification
        await _setupAuthToken();

        final apiPrescription = await apiDataSource.getPrescriptionById(id);
        await localDataSource.cachePrescription(apiPrescription);
        return Right(apiPrescription);
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
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
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

      // Configurer le token d'authentification
      await _setupAuthToken();

      final prescriptionModel = PrescriptionModel.fromEntity(prescription);
      final prescriptionId = await apiDataSource.createPrescription(prescriptionModel);

      // Mettre en cache
      final newPrescription = prescriptionModel.copyWith(id: prescriptionId) as PrescriptionModel;
      await localDataSource.cachePrescription(newPrescription);

      return Right(prescriptionId);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePrescription(Prescription prescription) async {
    return const Left(UnexpectedFailure('Mise à jour non implémentée dans le backend'));
  }

  @override
  Future<Either<Failure, bool>> deletePrescription(String id) async {
    return const Left(UnexpectedFailure('Suppression non implémentée dans le backend'));
  }
}
