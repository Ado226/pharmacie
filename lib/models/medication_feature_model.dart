// Fichier: lib/models/medication_feature_model.dart
import 'package:flutter/material.dart';

class MedicationFeatureModel {
  final String title;
  final Widget Function() routeBuilder;
  final String iconAsset;

  MedicationFeatureModel({
    required this.title,
    required this.routeBuilder,
    required this.iconAsset
  });
}