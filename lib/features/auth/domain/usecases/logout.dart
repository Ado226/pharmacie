// Fichier: lib/features/auth/domain/usecases/logout.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use Case : Déconnexion
class Logout implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  Logout(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.logout();
  }
}
