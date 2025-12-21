// Fichier: lib/main.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'views/home_view.dart';
import 'views/pharmacy_responses_view.dart';
import 'views/notifications_view.dart';
import 'injection_container.dart' as di;
import 'features/prescription/presentation/bloc/prescription_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'core/services/socket_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/pharmacy_response_service.dart';
import 'features/pharmacy_responses/injection_container.dart';
import 'models/prescription_status.dart';
import 'models/pharmacy_response_api_model.dart';

// Clé globale pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser sqflite_ffi pour Windows/Linux/Mac desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialiser le service de notifications avec la clé de navigation
  try {
    await NotificationService.initialize(navKey: navigatorKey);
    print('✅ Service de notifications initialise');
  } catch (e) {
    print('⚠️ Notifications non disponibles: $e');
  }

  // Tester la connexion au backend Node.js
  try {
    final apiService = ApiService();
    final isConnected = await apiService.testConnection();
    if (isConnected) {
      print('✅ Backend Node.js connecté avec succès !');
    } else {
      print('⚠️ Impossible de se connecter au backend Node.js');
    }
  } catch (e) {
    print('❌ Erreur lors de la connexion au backend: $e');
  }

  // Initialiser les dépendances Clean Architecture
  await di.initializeDependencies();

  // Initialiser les dépendances Pharmacy Responses
  await initPharmacyResponsesDependencies();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PrescriptionBloc? _prescriptionBloc;
  AuthBloc? _authBloc;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initBlocs();
  }

  Future<void> _initBlocs() async {
    // Initialiser AuthBloc (synchrone)
    _authBloc = di.sl<AuthBloc>();

    // Écouter les changements d'état d'authentification pour initialiser Socket.io
    _authBloc!.stream.listen((state) {
      if (state is Authenticated) {
        // Initialiser Socket.io avec l'ID du client
        final clientId = int.tryParse(state.user.id) ?? 0;
        if (clientId > 0) {
          print('SocketService: Initialisation avec client ID $clientId');
          SocketService().init(clientId);
        }
      } else if (state is LoginSuccess) {
        // Après login réussi
        final clientId = int.tryParse(state.user.id) ?? 0;
        if (clientId > 0) {
          print('SocketService: Initialisation après login avec client ID $clientId');
          SocketService().init(clientId);
        }
      } else if (state is Unauthenticated || state is LogoutSuccess) {
        // Déconnecter Socket.io quand l'utilisateur se déconnecte
        SocketService().disconnect();
      }
    });

    // Vérifier le statut d'authentification
    _authBloc!.add(const CheckAuthStatusEvent());

    // Initialiser PrescriptionBloc (asynchrone)
    _prescriptionBloc = await di.sl.getAsync<PrescriptionBloc>();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _prescriptionBloc?.close();
    _authBloc?.close();
    SocketService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _prescriptionBloc == null || _authBloc == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return MultiBlocProvider(
      providers: [
        // Bloc Auth disponible globalement
        BlocProvider<AuthBloc>(
          create: (context) => _authBloc!,
        ),
        // Bloc Prescription disponible globalement
        BlocProvider<PrescriptionBloc>(
          create: (context) => _prescriptionBloc!,
        ),
        // Autres blocs seront ajoutés ici au fur et à mesure
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Pharmacie App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Roboto',
        ),
        home: const HomeView(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          // Route pour les détails des réponses pharmacie
          if (settings.name == '/pharmacy-responses-detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            final commandeId = args?['commande_id'];

            if (commandeId != null) {
              return MaterialPageRoute(
                builder: (context) => FutureBuilder<CommandeDetailResponse>(
                  future: PharmacyResponseService.getCommandeDetails(
                    commandeId is int ? commandeId : int.parse(commandeId.toString()),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Erreur')),
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Impossible de charger la commande #$commandeId'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Retour'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final details = snapshot.data!;
                    // Convertir le statut string en enum
                    PrescriptionStatus status = PrescriptionStatus.enAttente;
                    final statutStr = details.commande.statut.toLowerCase();
                    switch (statutStr) {
                      case 'en_cours':
                        status = PrescriptionStatus.enCours;
                        break;
                      case 'payee':
                      case 'paye':
                        status = PrescriptionStatus.paye;
                        break;
                      case 'en_preparation':
                        status = PrescriptionStatus.enPreparation;
                        break;
                      case 'livree':
                        status = PrescriptionStatus.livree;
                        break;
                      case 'annulee':
                        status = PrescriptionStatus.annulee;
                        break;
                      default:
                        status = PrescriptionStatus.enAttente;
                    }

                    // Construire la liste des produits
                    final productsList = details.commande.produits.map((p) => {
                      'produit_id': p.produitId,
                      'id': p.produitId,
                      'name': p.nomProduit,
                      'nom': p.nomProduit,
                      'quantite': p.quantite,
                    }).toList();

                    return PharmacyResponsesView(
                      patientName: details.commande.nomPatient ?? 'Patient',
                      productsList: productsList,
                      status: status,
                      commandeId: commandeId is int ? commandeId : int.parse(commandeId.toString()),
                      pharmacyResponses: details.reponsesExistantes,
                      ordonnancePhotoUrl: details.commande.ordonnancePhotoUrl,
                    );
                  },
                ),
              );
            }
          }

          // Route pour les notifications
          if (settings.name == '/notifications') {
            return MaterialPageRoute(
              builder: (context) => const NotificationsView(),
            );
          }

          return null;
        },
      ),
    );
  }
}