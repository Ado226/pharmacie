// Fichier: lib/injection_container.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'core/network/network_info.dart';
import 'core/config/api_config.dart';

// Prescription Feature
import 'features/prescription/data/datasources/prescription_local_datasource.dart';
import 'features/prescription/data/datasources/prescription_api_datasource.dart';
import 'features/prescription/data/repositories/prescription_api_repository_impl.dart';
import 'features/prescription/domain/repositories/prescription_repository.dart';
import 'features/prescription/domain/usecases/get_all_prescriptions.dart';
import 'features/prescription/domain/usecases/get_prescription_by_id.dart';
import 'features/prescription/domain/usecases/create_prescription.dart';
import 'features/prescription/presentation/bloc/prescription_bloc.dart';

// Auth Feature
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/register_client.dart';
import 'features/auth/domain/usecases/login_client.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

/// Service Locator global
final sl = GetIt.instance;

/// Initialiser toutes les dépendances
Future<void> initializeDependencies() async {
  // ========== FEATURES ==========

  // === Auth Feature ===

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      registerClient: sl(),
      loginClient: sl(),
      logout: sl(),
      authRepository: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => RegisterClient(sl()));
  sl.registerLazySingleton(() => LoginClient(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // DataSources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      httpClient: sl(),
      baseUrl: ApiConfig.baseUrl,
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // === Prescription Feature ===

  // Bloc
  sl.registerFactoryAsync(
    () async => PrescriptionBloc(
      getAllPrescriptions: await sl.getAsync<GetAllPrescriptions>(),
      getPrescriptionById: await sl.getAsync<GetPrescriptionById>(),
      createPrescription: await sl.getAsync<CreatePrescription>(),
    ),
  );

  // UseCases
  sl.registerLazySingletonAsync(() async {
    final repository = await sl.getAsync<PrescriptionRepository>();
    return GetAllPrescriptions(repository);
  });
  sl.registerLazySingletonAsync(() async {
    final repository = await sl.getAsync<PrescriptionRepository>();
    return GetPrescriptionById(repository);
  });
  sl.registerLazySingletonAsync(() async {
    final repository = await sl.getAsync<PrescriptionRepository>();
    return CreatePrescription(repository);
  });

  // Repository - UTILISE TON BACKEND NODE.JS
  sl.registerLazySingletonAsync<PrescriptionRepository>(() async {
    final localDataSource = await sl.getAsync<PrescriptionLocalDataSource>();
    return PrescriptionApiRepositoryImpl(
      apiDataSource: sl(),
      localDataSource: localDataSource,
      networkInfo: sl(),
      authRepository: sl(),
    );
  });

  // DataSources - BACKEND NODE.JS
  sl.registerLazySingleton<PrescriptionApiDataSource>(
    () => PrescriptionApiDataSourceImpl(
      httpClient: sl(),
      baseUrl: ApiConfig.baseUrl,
    ),
  );

  sl.registerLazySingletonAsync<PrescriptionLocalDataSource>(() async {
    final database = await sl.getAsync<Database>();
    return PrescriptionLocalDataSourceImpl(
      database: database,
    );
  });

  // ========== CORE ==========

  // Network Info
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // ========== EXTERNAL ==========

  // HTTP Client pour les appels API
  sl.registerLazySingleton(() => http.Client());

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // SQLite Database
  sl.registerLazySingletonAsync<Database>(() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'pharmacie.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Créer les tables
        await db.execute('''
          CREATE TABLE prescriptions (
            id TEXT PRIMARY KEY,
            patient_name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE medications (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            form TEXT NOT NULL,
            dosage TEXT NOT NULL,
            usage TEXT NOT NULL,
            contraindications TEXT,
            image_url TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE prescription_medications (
            prescription_id TEXT NOT NULL,
            medication_id TEXT NOT NULL,
            patient_type TEXT NOT NULL,
            PRIMARY KEY (prescription_id, medication_id),
            FOREIGN KEY (prescription_id) REFERENCES prescriptions(id),
            FOREIGN KEY (medication_id) REFERENCES medications(id)
          )
        ''');
      },
    );
  });

  // Connectivity
  sl.registerLazySingleton(() => Connectivity());

  // Attendre que toutes les dépendances asynchrones soient prêtes
  await sl.allReady();
}
