// Fichier: lib/viewmodels/manual_prescription_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../models/prescription_model.dart';
import 'dart:math';

class ManualPrescriptionViewModel extends ChangeNotifier {
  // État de l'ordonnance en cours
  PrescriptionModel? _currentPrescription;
  
  // Liste de médicaments (simulée pour l'instant)
  final List<MedicationModel> _allMedications = MedicationModel.getMockMedications();
  
  // Médicaments filtrés par la recherche
  List<MedicationModel> _filteredMedications = [];
  
  // Médicament sélectionné pour l'ajout
  MedicationModel? _selectedMedication;
  
  // Type de patient sélectionné (enfant ou adulte)
  PatientType _selectedPatientType = PatientType.adulte;
  
  // Contrôleur pour le champ de recherche
  final TextEditingController searchController = TextEditingController();
  
  // Contrôleur pour le nom de l'ordonnance
  final TextEditingController prescriptionNameController = TextEditingController();
  
  // Getters
  PrescriptionModel? get currentPrescription => _currentPrescription;
  List<MedicationModel> get filteredMedications => _filteredMedications;
  MedicationModel? get selectedMedication => _selectedMedication;
  PatientType get selectedPatientType => _selectedPatientType;
  bool get hasSelectedMedication => _selectedMedication != null;
  
  // Initialisation
  ManualPrescriptionViewModel() {
    _filteredMedications = List.from(_allMedications);
  }
  
  // Créer une nouvelle ordonnance
  void createNewPrescription(String name) {
    _currentPrescription = PrescriptionModel(
      id: '', // Laisser vide pour que Supabase génère l'UUID
      name: name,
      createdAt: DateTime.now(),
      medications: [],
    );
    notifyListeners();
  }
  
  // Rechercher des médicaments
  void searchMedications(String query) {
    if (query.isEmpty) {
      _filteredMedications = List.from(_allMedications);
    } else {
      _filteredMedications = _allMedications
          .where((med) => med.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
  
  // Sélectionner un médicament
  void selectMedication(MedicationModel medication) {
    _selectedMedication = medication;
    notifyListeners();
  }
  
  // Désélectionner un médicament
  void unselectMedication() {
    _selectedMedication = null;
    notifyListeners();
  }
  
  // Sélectionner un type de patient
  void selectPatientType(PatientType type) {
    _selectedPatientType = type;
    notifyListeners();
  }
  
  // Ajouter le médicament sélectionné à l'ordonnance
  void addMedicationToPrescription() {
    if (_currentPrescription != null && _selectedMedication != null) {
      _currentPrescription!.addMedication(_selectedMedication!, _selectedPatientType);
      _selectedMedication = null;
      notifyListeners();
    }
  }
  
  // Supprimer un médicament de l'ordonnance
  void removeMedicationFromPrescription(String medicationId) {
    if (_currentPrescription != null) {
      _currentPrescription!.removeMedication(medicationId);
      notifyListeners();
    }
  }
  
  // Réinitialiser la recherche
  void resetSearch() {
    searchController.clear();
    _filteredMedications = List.from(_allMedications);
    notifyListeners();
  }
  
  @override
  void dispose() {
    searchController.dispose();
    prescriptionNameController.dispose();
    super.dispose();
  }
}
