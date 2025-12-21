// Fichier: lib/features/prescription/presentation/bloc/prescription_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_all_prescriptions.dart';
import '../../domain/usecases/get_prescription_by_id.dart';
import '../../domain/usecases/create_prescription.dart' as usecase;
import 'prescription_event.dart';
import 'prescription_state.dart';

/// Bloc Prescription - Gère la logique de présentation
class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final GetAllPrescriptions getAllPrescriptions;
  final GetPrescriptionById getPrescriptionById;
  final usecase.CreatePrescription createPrescription;

  PrescriptionBloc({
    required this.getAllPrescriptions,
    required this.getPrescriptionById,
    required this.createPrescription,
  }) : super(const PrescriptionInitial()) {
    // Enregistrer les handlers pour chaque événement
    on<LoadAllPrescriptions>(_onLoadAllPrescriptions);
    on<LoadPrescriptionById>(_onLoadPrescriptionById);
    on<CreatePrescriptionEvent>(_onCreatePrescription);
  }

  /// Handler pour charger toutes les prescriptions
  Future<void> _onLoadAllPrescriptions(
    LoadAllPrescriptions event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(const PrescriptionLoading());

    final result = await getAllPrescriptions(const NoParams());

    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (prescriptions) => emit(PrescriptionsLoaded(prescriptions)),
    );
  }

  /// Handler pour charger une prescription par ID
  Future<void> _onLoadPrescriptionById(
    LoadPrescriptionById event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(const PrescriptionLoading());

    final result = await getPrescriptionById(GetPrescriptionParams(event.id));

    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (prescription) => emit(PrescriptionLoaded(prescription)),
    );
  }

  /// Handler pour créer une prescription
  Future<void> _onCreatePrescription(
    CreatePrescriptionEvent event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(const PrescriptionLoading());

    final result = await createPrescription(usecase.CreatePrescriptionParams(event.prescription));

    result.fold(
      (failure) => emit(PrescriptionError(failure.message)),
      (prescriptionId) => emit(PrescriptionCreated(prescriptionId)),
    );
  }
}
