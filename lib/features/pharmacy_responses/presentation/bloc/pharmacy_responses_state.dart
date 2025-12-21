// Presentation Layer - States
// Représente les différents états de l'UI

import 'package:equatable/equatable.dart';
import '../../domain/entities/commande_detail_entity.dart';
import '../../domain/entities/reponse_pharmacie_entity.dart';

abstract class PharmacyResponsesState extends Equatable {
  const PharmacyResponsesState();

  @override
  List<Object?> get props => [];
}

/// État initial
class PharmacyResponsesInitial extends PharmacyResponsesState {
  const PharmacyResponsesInitial();
}

/// État de chargement
class PharmacyResponsesLoading extends PharmacyResponsesState {
  const PharmacyResponsesLoading();
}

/// État de succès avec données chargées
class PharmacyResponsesLoaded extends PharmacyResponsesState {
  final CommandeDetailEntity commandeDetail;
  final ReponsePharmacieEntity? selectedResponse;

  const PharmacyResponsesLoaded({
    required this.commandeDetail,
    this.selectedResponse,
  });

  @override
  List<Object?> get props => [commandeDetail, selectedResponse];

  /// Créer une nouvelle instance avec des modifications
  PharmacyResponsesLoaded copyWith({
    CommandeDetailEntity? commandeDetail,
    ReponsePharmacieEntity? selectedResponse,
    bool clearSelection = false,
  }) {
    return PharmacyResponsesLoaded(
      commandeDetail: commandeDetail ?? this.commandeDetail,
      selectedResponse: clearSelection ? null : (selectedResponse ?? this.selectedResponse),
    );
  }
}

/// État d'erreur
class PharmacyResponsesError extends PharmacyResponsesState {
  final String message;

  const PharmacyResponsesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// État vide (pas de réponses)
class PharmacyResponsesEmpty extends PharmacyResponsesState {
  final CommandeDetailEntity commandeDetail;

  const PharmacyResponsesEmpty(this.commandeDetail);

  @override
  List<Object?> get props => [commandeDetail];
}
