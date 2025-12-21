// Domain Layer - Use Case: Get Réponses for Commande
// Récupère uniquement les réponses pour une commande

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reponse_pharmacie_entity.dart';
import '../repositories/pharmacy_response_repository.dart';

class GetReponsesForCommande extends UseCase<List<ReponsePharmacieEntity>, GetReponsesForCommandeParams> {
  final PharmacyResponseRepository repository;

  GetReponsesForCommande(this.repository);

  @override
  Future<Either<Failure, List<ReponsePharmacieEntity>>> call(
    GetReponsesForCommandeParams params,
  ) async {
    return await repository.getReponsesForCommande(params.commandeId);
  }
}

class GetReponsesForCommandeParams {
  final int commandeId;

  const GetReponsesForCommandeParams({required this.commandeId});
}
