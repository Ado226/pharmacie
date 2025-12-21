// Domain Layer - Repository Interface
// Définit le contrat que la Data Layer doit implémenter

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/commande_detail_entity.dart';
import '../entities/reponse_pharmacie_entity.dart';

abstract class PharmacyResponseRepository {
  /// Récupérer les détails complets d'une commande
  /// Retourne CommandeDetailEntity avec commande, pharmacies proches et réponses
  Future<Either<Failure, CommandeDetailEntity>> getCommandeDetails(
    int commandeId,
  );

  /// Récupérer uniquement les réponses pour une commande
  Future<Either<Failure, List<ReponsePharmacieEntity>>> getReponsesForCommande(
    int commandeId,
  );

  /// Créer une nouvelle réponse pharmacie
  Future<Either<Failure, ReponsePharmacieEntity>> createReponsePharmacieForCommande({
    required int commandeId,
    required int pharmacieId,
    required List<Map<String, dynamic>> produitsDisponibles,
    String? commentairePharmacie,
  });

  /// Supprimer une réponse pharmacie
  Future<Either<Failure, void>> deleteReponsePharmacie(int reponseId);
}
