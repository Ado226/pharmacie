// Fichier: lib/features/prescription/domain/usecases/get_prescription_by_id.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/prescription.dart';
import '../repositories/prescription_repository.dart';

/// Paramètres pour le UseCase
class GetPrescriptionParams extends Equatable {
  final String id;

  const GetPrescriptionParams(this.id);

  @override
  List<Object?> get props => [id];
}

/// UseCase pour récupérer une prescription par ID
class GetPrescriptionById implements UseCase<Prescription, GetPrescriptionParams> {
  final PrescriptionRepository repository;

  GetPrescriptionById(this.repository);

  @override
  Future<Either<Failure, Prescription>> call(GetPrescriptionParams params) async {
    return await repository.getPrescriptionById(params.id);
  }
}
