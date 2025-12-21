// Fichier: lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Classe abstraite pour tous les UseCases
/// [Type] est le type de retour du UseCase
/// [Params] est le type des paramètres du UseCase
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Classe pour les UseCases sans paramètres
class NoParams {
  const NoParams();
}
