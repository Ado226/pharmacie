// Fichier: lib/features/prescription/presentation/bloc/prescription_event.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/prescription.dart';

/// Événements du Bloc Prescription
abstract class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Charger toutes les prescriptions
class LoadAllPrescriptions extends PrescriptionEvent {
  const LoadAllPrescriptions();
}

/// Charger une prescription par ID
class LoadPrescriptionById extends PrescriptionEvent {
  final String id;

  const LoadPrescriptionById(this.id);

  @override
  List<Object?> get props => [id];
}

/// Créer une prescription
class CreatePrescriptionEvent extends PrescriptionEvent {
  final Prescription prescription;

  const CreatePrescriptionEvent(this.prescription);

  @override
  List<Object?> get props => [prescription];
}

/// Mettre à jour une prescription
class UpdatePrescriptionEvent extends PrescriptionEvent {
  final Prescription prescription;

  const UpdatePrescriptionEvent(this.prescription);

  @override
  List<Object?> get props => [prescription];
}

/// Supprimer une prescription
class DeletePrescriptionEvent extends PrescriptionEvent {
  final String id;

  const DeletePrescriptionEvent(this.id);

  @override
  List<Object?> get props => [id];
}
