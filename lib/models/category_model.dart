// Fichier: lib/models/category_model.dart
import 'package:flutter/material.dart';

class CategoryModel {
  final String title;
  final String? iconAsset;
  final IconData? icon;

  CategoryModel({
    required this.title,
    this.iconAsset,
    this.icon,
  });
}