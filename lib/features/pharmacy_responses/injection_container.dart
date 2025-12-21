// Injection de dépendances pour la feature Pharmacy Responses
// Utilise get_it pour l'injection de dépendances

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Domain Layer
import 'domain/repositories/pharmacy_response_repository.dart';
import 'domain/usecases/get_commande_details.dart';
import 'domain/usecases/get_reponses_for_commande.dart';
import 'domain/usecases/create_reponse_pharmacie.dart';
import 'domain/usecases/delete_reponse_pharmacie.dart';

// Data Layer
import 'data/datasources/pharmacy_response_remote_datasource.dart';
import 'data/repositories/pharmacy_response_repository_impl.dart';

// Presentation Layer
import 'presentation/bloc/pharmacy_responses_cubit.dart';

final sl = GetIt.instance;

/// Initialiser toutes les dépendances pour la feature Pharmacy Responses
Future<void> initPharmacyResponsesDependencies() async {
  // ===========================
  // Presentation Layer - BLoC
  // ===========================

  // Factory: Nouvelle instance à chaque appel
  sl.registerFactory(
    () => PharmacyResponsesCubit(
      getCommandeDetails: sl(),
      getReponsesForCommande: sl(),
      createReponsePharmacie: sl(),
      deleteReponsePharmacie: sl(),
    ),
  );

  // ===========================
  // Domain Layer - Use Cases
  // ===========================

  sl.registerLazySingleton(() => GetCommandeDetails(sl()));
  sl.registerLazySingleton(() => GetReponsesForCommande(sl()));
  sl.registerLazySingleton(() => CreateReponsePharmacie(sl()));
  sl.registerLazySingleton(() => DeleteReponsePharmacie(sl()));

  // ===========================
  // Domain Layer - Repository
  // ===========================

  sl.registerLazySingleton<PharmacyResponseRepository>(
    () => PharmacyResponseRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // ===========================
  // Data Layer - Data Sources
  // ===========================

  sl.registerLazySingleton<PharmacyResponseRemoteDataSource>(
    () => PharmacyResponseRemoteDataSourceImpl(
      client: sl(),
      sharedPreferences: sl(),
    ),
  );

  // ===========================
  // External - Core
  // ===========================

  // HTTP Client - Singleton
  if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton(() => http.Client());
  }

  // SharedPreferences - Singleton
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => sharedPreferences);
  }
}
