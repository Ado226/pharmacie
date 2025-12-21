// Fichier: lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/register_client.dart';
import '../../domain/usecases/login_client.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC pour l'authentification
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterClient registerClient;
  final LoginClient loginClient;
  final Logout logout;
  final AuthRepository authRepository;

  AuthBloc({
    required this.registerClient,
    required this.loginClient,
    required this.logout,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    // Handler pour RegisterClientEvent
    on<RegisterClientEvent>(_onRegisterClient);

    // Handler pour LoginClientEvent
    on<LoginClientEvent>(_onLoginClient);

    // Handler pour LogoutEvent
    on<LogoutEvent>(_onLogout);

    // Handler pour CheckAuthStatusEvent
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  /// Gérer l'inscription
  Future<void> _onRegisterClient(
    RegisterClientEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await registerClient(RegisterClientParams(
      numero: event.numero,
      password: event.password,
      nom: event.nom,
      prenom: event.prenom,
    ));

    result.fold(
      (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
      (authResult) => emit(RegisterSuccess(
        user: authResult.user,
        token: authResult.token,
      )),
    );
  }

  /// Gérer la connexion
  Future<void> _onLoginClient(
    LoginClientEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await loginClient(LoginClientParams(
      numero: event.numero,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
      (authResult) => emit(LoginSuccess(
        user: authResult.user,
        token: authResult.token,
      )),
    );
  }

  /// Gérer la déconnexion
  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await logout(NoParams());

    result.fold(
      (failure) => emit(AuthError(message: _mapFailureToMessage(failure))),
      (success) => emit(const LogoutSuccess()),
    );
  }

  /// Vérifier le statut d'authentification
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final isAuth = await authRepository.isAuthenticated();
    final token = await authRepository.getToken();
    final userMap = await authRepository.getCachedUser();

    if (isAuth && token != null && userMap != null) {
      // L'utilisateur est authentifié, restaurer la session
      // Convertir le Map en User
      final user = User.fromJson(userMap);
      emit(LoginSuccess(
        user: user,
        token: token,
      ));
    } else {
      emit(const Unauthenticated());
    }
  }

  /// Mapper les failures en messages
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message ?? 'Erreur serveur';
    } else if (failure is NetworkFailure) {
      return 'Pas de connexion internet';
    } else if (failure is AuthenticationFailure) {
      return failure.message ?? 'Identifiants incorrects';
    } else if (failure is CacheFailure) {
      return 'Erreur de cache';
    } else {
      return 'Erreur inattendue';
    }
  }
}
