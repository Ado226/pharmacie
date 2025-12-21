// Presentation Layer - Cubit
// Gère la logique métier et les états de l'UI

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reponse_pharmacie_entity.dart';
import '../../domain/usecases/get_commande_details.dart';
import '../../domain/usecases/get_reponses_for_commande.dart';
import '../../domain/usecases/create_reponse_pharmacie.dart';
import '../../domain/usecases/delete_reponse_pharmacie.dart';
import 'pharmacy_responses_state.dart';

class PharmacyResponsesCubit extends Cubit<PharmacyResponsesState> {
  final GetCommandeDetails getCommandeDetails;
  final GetReponsesForCommande getReponsesForCommande;
  final CreateReponsePharmacie createReponsePharmacie;
  final DeleteReponsePharmacie deleteReponsePharmacie;

  PharmacyResponsesCubit({
    required this.getCommandeDetails,
    required this.getReponsesForCommande,
    required this.createReponsePharmacie,
    required this.deleteReponsePharmacie,
  }) : super(const PharmacyResponsesInitial());

  /// Charger les détails d'une commande
  Future<void> loadCommandeDetails(int commandeId) async {
    emit(const PharmacyResponsesLoading());

    final result = await getCommandeDetails(
      GetCommandeDetailsParams(commandeId: commandeId),
    );

    result.fold(
      (failure) => emit(PharmacyResponsesError(failure.message)),
      (commandeDetail) {
        if (commandeDetail.reponsesExistantes.isEmpty) {
          emit(PharmacyResponsesEmpty(commandeDetail));
        } else {
          emit(PharmacyResponsesLoaded(commandeDetail: commandeDetail));
        }
      },
    );
  }

  /// Rafraîchir les données
  Future<void> refreshCommandeDetails(int commandeId) async {
    // Ne pas afficher le loading si on a déjà des données
    final currentState = state;
    if (currentState is! PharmacyResponsesLoaded) {
      emit(const PharmacyResponsesLoading());
    }

    final result = await getCommandeDetails(
      GetCommandeDetailsParams(commandeId: commandeId),
    );

    result.fold(
      (failure) => emit(PharmacyResponsesError(failure.message)),
      (commandeDetail) {
        if (commandeDetail.reponsesExistantes.isEmpty) {
          emit(PharmacyResponsesEmpty(commandeDetail));
        } else {
          emit(PharmacyResponsesLoaded(commandeDetail: commandeDetail));
        }
      },
    );
  }

  /// Sélectionner une réponse pharmacie
  void selectResponse(ReponsePharmacieEntity response) {
    final currentState = state;
    if (currentState is PharmacyResponsesLoaded) {
      emit(currentState.copyWith(selectedResponse: response));
    }
  }

  /// Désélectionner la réponse
  void clearSelection() {
    final currentState = state;
    if (currentState is PharmacyResponsesLoaded) {
      emit(currentState.copyWith(clearSelection: true));
    }
  }

  /// Créer une nouvelle réponse pharmacie
  Future<void> createResponse({
    required int commandeId,
    required int pharmacieId,
    required List<Map<String, dynamic>> produitsDisponibles,
    String? commentairePharmacie,
  }) async {
    final result = await createReponsePharmacie(
      CreateReponsePharmacieParams(
        commandeId: commandeId,
        pharmacieId: pharmacieId,
        produitsDisponibles: produitsDisponibles,
        commentairePharmacie: commentairePharmacie,
      ),
    );

    result.fold(
      (failure) => emit(PharmacyResponsesError(failure.message)),
      (reponse) {
        // Recharger les données après création
        loadCommandeDetails(commandeId);
      },
    );
  }

  /// Supprimer une réponse pharmacie
  Future<void> deleteResponse(int reponseId, int commandeId) async {
    final result = await deleteReponsePharmacie(
      DeleteReponsePharmacieParams(reponseId: reponseId),
    );

    result.fold(
      (failure) => emit(PharmacyResponsesError(failure.message)),
      (_) {
        // Recharger les données après suppression
        loadCommandeDetails(commandeId);
      },
    );
  }
}
