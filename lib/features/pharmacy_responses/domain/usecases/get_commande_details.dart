// Domain Layer - Use Case: Get Commande Details
// Récupère les détails complets d'une commande

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/commande_detail_entity.dart';
import '../repositories/pharmacy_response_repository.dart';

class GetCommandeDetails extends UseCase<CommandeDetailEntity, GetCommandeDetailsParams> {
  final PharmacyResponseRepository repository;

  GetCommandeDetails(this.repository);

  @override
  Future<Either<Failure, CommandeDetailEntity>> call(
    GetCommandeDetailsParams params,
  ) async {
    return await repository.getCommandeDetails(params.commandeId);
  }
}

class GetCommandeDetailsParams {
  final int commandeId;

  const GetCommandeDetailsParams({required this.commandeId});
}
