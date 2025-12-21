// Domain Layer - Use Case: Create Réponse Pharmacie
// Crée une nouvelle réponse pharmacie

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reponse_pharmacie_entity.dart';
import '../repositories/pharmacy_response_repository.dart';

class CreateReponsePharmacie extends UseCase<ReponsePharmacieEntity, CreateReponsePharmacieParams> {
  final PharmacyResponseRepository repository;

  CreateReponsePharmacie(this.repository);

  @override
  Future<Either<Failure, ReponsePharmacieEntity>> call(
    CreateReponsePharmacieParams params,
  ) async {
    return await repository.createReponsePharmacieForCommande(
      commandeId: params.commandeId,
      pharmacieId: params.pharmacieId,
      produitsDisponibles: params.produitsDisponibles,
      commentairePharmacie: params.commentairePharmacie,
    );
  }
}

class CreateReponsePharmacieParams {
  final int commandeId;
  final int pharmacieId;
  final List<Map<String, dynamic>> produitsDisponibles;
  final String? commentairePharmacie;

  const CreateReponsePharmacieParams({
    required this.commandeId,
    required this.pharmacieId,
    required this.produitsDisponibles,
    this.commentairePharmacie,
  });
}
