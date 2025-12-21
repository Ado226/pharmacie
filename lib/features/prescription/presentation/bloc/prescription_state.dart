// Fichier: lib/features/prescription/presentation/bloc/prescription_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/prescription.dart';

/// États du Bloc Prescription
abstract class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => [];
}

/// État initial
class PrescriptionInitial extends PrescriptionState {
  const PrescriptionInitial();
}

/// Chargement en cours
class PrescriptionLoading extends PrescriptionState {
  const PrescriptionLoading();
}

/// Liste chargée avec succès
class PrescriptionsLoaded extends PrescriptionState {
  final List<Prescription> prescriptions;

  const PrescriptionsLoaded(this.prescriptions);

  @override
  List<Object?> get props => [prescriptions];
}

/// Une prescription chargée avec succès
class PrescriptionLoaded extends PrescriptionState {
  final Prescription prescription;

  const PrescriptionLoaded(this.prescription);

  @override
  List<Object?> get props => [prescription];
}

/// Prescription créée avec succès
class PrescriptionCreated extends PrescriptionState {
  final String prescriptionId;

  const PrescriptionCreated(this.prescriptionId);

  @override
  List<Object?> get props => [prescriptionId];
}

/// Prescription mise à jour avec succès
class PrescriptionUpdated extends PrescriptionState {
  const PrescriptionUpdated();
}

/// Prescription supprimée avec succès
class PrescriptionDeleted extends PrescriptionState {
  const PrescriptionDeleted();
}

/// Erreur
class PrescriptionError extends PrescriptionState {
  final String message;

  const PrescriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
