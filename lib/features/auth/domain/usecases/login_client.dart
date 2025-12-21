// Fichier: lib/features/auth/domain/usecases/login_client.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

/// Use Case : Connexion d'un client
class LoginClient implements UseCase<AuthResult, LoginClientParams> {
  final AuthRepository repository;

  LoginClient(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(LoginClientParams params) async {
    return await repository.loginClient(
      numero: params.numero,
      password: params.password,
    );
  }
}

/// Paramètres pour la connexion
class LoginClientParams extends Equatable {
  final String numero;
  final String password;

  const LoginClientParams({
    required this.numero,
    required this.password,
  });

  @override
  List<Object> get props => [numero, password];
}
