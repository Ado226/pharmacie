// Fichier: lib/features/prescription/domain/entities/medication.dart
import 'package:equatable/equatable.dart';

/// Entity Medication (pure business object)
class Medication extends Equatable {
  final String id;
  final String name;
  final String description;
  final String form;
  final String dosage;
  final String usage;
  final String contraindications;
  final String imageUrl;

  const Medication({
    required this.id,
    required this.name,
    required this.description,
    required this.form,
    required this.dosage,
    required this.usage,
    required this.contraindications,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        form,
        dosage,
        usage,
        contraindications,
        imageUrl,
      ];
}
