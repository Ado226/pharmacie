// Fichier: lib/features/auth/domain/usecases/register_client.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

/// Use Case : Inscription d'un client
class RegisterClient implements UseCase<AuthResult, RegisterClientParams> {
  final AuthRepository repository;

  RegisterClient(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(RegisterClientParams params) async {
    return await repository.registerClient(
      numero: params.numero,
      password: params.password,
      nom: params.nom,
      prenom: params.prenom,
    );
  }
}

/// Paramètres pour l'inscription
class RegisterClientParams extends Equatable {
  final String numero;
  final String password;
  final String? nom;
  final String? prenom;

  const RegisterClientParams({
    required this.numero,
    required this.password,
    this.nom,
    this.prenom,
  });

  @override
  List<Object?> get props => [numero, password, nom, prenom];
}
