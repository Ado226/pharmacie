// Fichier: lib/features/prescription/domain/repositories/prescription_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/prescription.dart';

/// Interface du repository (contrat)
/// Ne contient QUE des méthodes abstraites
abstract class PrescriptionRepository {
  /// Récupérer toutes les prescriptions
  Future<Either<Failure, List<Prescription>>> getAllPrescriptions();

  /// Récupérer une prescription par ID
  Future<Either<Failure, Prescription>> getPrescriptionById(String id);

  /// Créer une nouvelle prescription
  Future<Either<Failure, String>> createPrescription(Prescription prescription);

  /// Mettre à jour une prescription
  Future<Either<Failure, bool>> updatePrescription(Prescription prescription);

  /// Supprimer une prescription
  Future<Either<Failure, bool>> deletePrescription(String id);
}
