// Domain Layer - Use Case: Delete Réponse Pharmacie
// Supprime une réponse pharmacie

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/pharmacy_response_repository.dart';

class DeleteReponsePharmacie extends UseCase<void, DeleteReponsePharmacieParams> {
  final PharmacyResponseRepository repository;

  DeleteReponsePharmacie(this.repository);

  @override
  Future<Either<Failure, void>> call(
    DeleteReponsePharmacieParams params,
  ) async {
    return await repository.deleteReponsePharmacie(params.reponseId);
  }
}

class DeleteReponsePharmacieParams {
  final int reponseId;

  const DeleteReponsePharmacieParams({required this.reponseId});
}
