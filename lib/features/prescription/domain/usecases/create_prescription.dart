// Fichier: lib/features/prescription/domain/usecases/create_prescription.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/prescription.dart';
import '../repositories/prescription_repository.dart';

/// Paramètres pour créer une prescription
class CreatePrescriptionParams extends Equatable {
  final Prescription prescription;

  const CreatePrescriptionParams(this.prescription);

  @override
  List<Object?> get props => [prescription];
}

/// UseCase pour créer une prescription
class CreatePrescription implements UseCase<String, CreatePrescriptionParams> {
  final PrescriptionRepository repository;

  CreatePrescription(this.repository);

  @override
  Future<Either<Failure, String>> call(CreatePrescriptionParams params) async {
    return await repository.createPrescription(params.prescription);
  }
}
