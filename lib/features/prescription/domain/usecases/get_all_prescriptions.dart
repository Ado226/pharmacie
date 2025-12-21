// Fichier: lib/features/prescription/domain/usecases/get_all_prescriptions.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/prescription.dart';
import '../repositories/prescription_repository.dart';

/// UseCase pour récupérer toutes les prescriptions
class GetAllPrescriptions implements UseCase<List<Prescription>, NoParams> {
  final PrescriptionRepository repository;

  GetAllPrescriptions(this.repository);

  @override
  Future<Either<Failure, List<Prescription>>> call(NoParams params) async {
    return await repository.getAllPrescriptions();
  }
}
