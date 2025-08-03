// Fichier: lib/viewmodels/home_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/medication_feature_model.dart';
import '../views/Reponse_list_view.dart';
import '../views/ordonnance_views.dart';
import '../views/manual_prescription_view.dart';
import '../views/prescription_list_view.dart';

class HomeViewModel extends ChangeNotifier {
  final List<CategoryModel> categories = [
    CategoryModel(title: 'Laboratoire', iconAsset: 'assets/icons/lab.png'),
    CategoryModel(title: 'Pharmacie', iconAsset: 'assets/icons/pharmacy.png'),
    CategoryModel(title: 'Ambulance', iconAsset: 'assets/icons/ambulance.png'),
    CategoryModel(title: 'Hospital', iconAsset: 'assets/icons/hospital.png'),

  ];

  final List<MedicationFeatureModel> medicationFeatures = [
    MedicationFeatureModel(
      title: 'Envoyer une ordonnance',
      routeBuilder:  () => const OrdonnanceView(),
      iconAsset: 'assets/icone/appareil-photo-reflex-numerique.png',
    ),
    MedicationFeatureModel(
      title: 'Saisie Manuelle de produit',
      routeBuilder: () => const ManualPrescriptionView(),
      iconAsset: 'assets/icone/medicament.png',
    ),
    MedicationFeatureModel(
      title: 'Reponse',
      routeBuilder:  () => const ReponseListView(),
      iconAsset: 'assets/icone/medicament (1).png',
    ),
    MedicationFeatureModel(
      title: 'Mes Ordonnances',
      routeBuilder: () =>  PrescriptionListView(),
      iconAsset: 'assets/icone/ordonnance.png',
    ),
  ];


  String searchQuery = '';

  void updateSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }
}