# Clean Architecture - Feature Pharmacy Responses

## Architecture Complète et Refactorisée

---

## Vue d'ensemble

Cette feature a été **entièrement refactorisée** selon les principes de **Clean Architecture** proposés par Robert C. Martin (Uncle Bob). L'architecture garantit:

- **Séparation des responsabilités** (Separation of Concerns)
- **Indépendance du framework** (Framework Independence)
- **Testabilité** (Testability)
- **Indépendance de l'UI** (UI Independence)
- **Indépendance de la base de données** (Database Independence)

---

## Structure des Dossiers

```
lib/features/pharmacy_responses/
├── domain/                          # DOMAIN LAYER (Logique métier pure)
│   ├── entities/                    # Entités métier
│   │   ├── commande_entity.dart
│   │   ├── commande_detail_entity.dart
│   │   ├── pharmacie_entity.dart
│   │   └── reponse_pharmacie_entity.dart
│   ├── repositories/                # Interfaces des repositories
│   │   └── pharmacy_response_repository.dart
│   └── usecases/                    # Cas d'utilisation
│       ├── get_commande_details.dart
│       ├── get_reponses_for_commande.dart
│       ├── create_reponse_pharmacie.dart
│       └── delete_reponse_pharmacie.dart
│
├── data/                            # DATA LAYER (Implémentation des données)
│   ├── models/                      # Modèles (Entity + JSON mapping)
│   │   ├── commande_model.dart
│   │   ├── commande_detail_model.dart
│   │   ├── pharmacie_model.dart
│   │   └── reponse_pharmacie_model.dart
│   ├── datasources/                 # Sources de données
│   │   └── pharmacy_response_remote_datasource.dart
│   └── repositories/                # Implémentation des repositories
│       └── pharmacy_response_repository_impl.dart
│
├── presentation/                    # PRESENTATION LAYER (UI + État)
│   ├── bloc/                        # BLoC/Cubit (State management)
│   │   ├── pharmacy_responses_cubit.dart
│   │   └── pharmacy_responses_state.dart
│   ├── pages/                       # Pages/Screens
│   │   └── pharmacy_responses_page.dart
│   └── widgets/                     # Widgets réutilisables
│       ├── pharmacy_response_card.dart
│       ├── pharmacy_details_bottom_sheet.dart
│       ├── loading_widget.dart
│       ├── error_widget.dart
│       └── empty_state_widget.dart
│
└── injection_container.dart         # Injection de dépendances (GetIt)
```

---

## Les 3 Couches (Layers)

### 1. Domain Layer (Couche Domaine)

**Rôle:** Contient la logique métier pure, sans dépendances externes.

#### Entités (Entities)

Les entités représentent les objets métier avec leur logique métier.

**Exemple:** `ReponsePharmacieEntity`
```dart
class ReponsePharmacieEntity extends Equatable {
  final int id;
  final double montantTotalPharmacie;
  final List<ProduitDisponibleEntity> produitsDisponibles;

  // Logique métier
  int get nombreProduitsDisponibles {
    return produitsDisponibles.where((p) => p.disponible).length;
  }

  double get pourcentageDisponibilite {
    if (nombreTotalProduits == 0) return 0.0;
    return (nombreProduitsDisponibles / nombreTotalProduits) * 100;
  }
}
```

#### Repositories (Interfaces)

Définissent les **contrats** que la couche Data doit respecter.

```dart
abstract class PharmacyResponseRepository {
  Future<Either<Failure, CommandeDetailEntity>> getCommandeDetails(int commandeId);
  Future<Either<Failure, List<ReponsePharmacieEntity>>> getReponsesForCommande(int commandeId);
}
```

#### Use Cases (Cas d'utilisation)

Chaque use case représente **une action métier**.

```dart
class GetCommandeDetails extends UseCase<CommandeDetailEntity, GetCommandeDetailsParams> {
  final PharmacyResponseRepository repository;

  Future<Either<Failure, CommandeDetailEntity>> call(GetCommandeDetailsParams params) {
    return repository.getCommandeDetails(params.commandeId);
  }
}
```

**Principe:** Un use case = Une responsabilité (Single Responsibility Principle)

---

### 2. Data Layer (Couche Données)

**Rôle:** Implémente les repositories et gère les sources de données.

#### Models

Étendent les entités et ajoutent la sérialisation JSON.

```dart
class ReponsePharmacieModel extends ReponsePharmacieEntity {
  factory ReponsePharmacieModel.fromJson(Map<String, dynamic> json) {
    return ReponsePharmacieModel(
      id: json['id'],
      montantTotalPharmacie: json['montant_total_pharmacie'],
      // ...
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'montant_total_pharmacie': montantTotalPharmacie,
      // ...
    };
  }
}
```

#### Data Sources

Gèrent les appels HTTP, cache, etc.

```dart
class PharmacyResponseRemoteDataSourceImpl {
  final http.Client client;

  Future<CommandeDetailModel> getCommandeDetails(int commandeId) async {
    final response = await client.get(url, headers: _getHeaders());
    if (response.statusCode == 200) {
      return CommandeDetailModel.fromJson(json.decode(response.body));
    }
    throw ServerException();
  }
}
```

#### Repository Implementation

Implémente l'interface du domaine et gère les erreurs.

```dart
class PharmacyResponseRepositoryImpl implements PharmacyResponseRepository {
  final PharmacyResponseRemoteDataSource remoteDataSource;

  Future<Either<Failure, CommandeDetailEntity>> getCommandeDetails(int id) async {
    try {
      final result = await remoteDataSource.getCommandeDetails(id);
      return Right(result);
    } on SocketException {
      return Left(NetworkFailure('Pas de connexion Internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

---

### 3. Presentation Layer (Couche Présentation)

**Rôle:** Gère l'interface utilisateur et l'état de l'application.

#### BLoC/Cubit (State Management)

Gère les états de l'UI et appelle les use cases.

```dart
class PharmacyResponsesCubit extends Cubit<PharmacyResponsesState> {
  final GetCommandeDetails getCommandeDetails;

  Future<void> loadCommandeDetails(int commandeId) async {
    emit(PharmacyResponsesLoading());

    final result = await getCommandeDetails(
      GetCommandeDetailsParams(commandeId: commandeId),
    );

    result.fold(
      (failure) => emit(PharmacyResponsesError(failure.message)),
      (data) => emit(PharmacyResponsesLoaded(commandeDetail: data)),
    );
  }
}
```

#### States

Représentent tous les états possibles de l'UI.

```dart
abstract class PharmacyResponsesState extends Equatable {}

class PharmacyResponsesInitial extends PharmacyResponsesState {}
class PharmacyResponsesLoading extends PharmacyResponsesState {}
class PharmacyResponsesLoaded extends PharmacyResponsesState {
  final CommandeDetailEntity commandeDetail;
}
class PharmacyResponsesError extends PharmacyResponsesState {
  final String message;
}
class PharmacyResponsesEmpty extends PharmacyResponsesState {}
```

#### Pages & Widgets

L'UI qui observe les états du BLoC.

```dart
class PharmacyResponsesPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PharmacyResponsesCubit>()..loadCommandeDetails(commandeId),
      child: BlocBuilder<PharmacyResponsesCubit, PharmacyResponsesState>(
        builder: (context, state) {
          if (state is PharmacyResponsesLoading) return LoadingWidget();
          if (state is PharmacyResponsesError) return ErrorWidget();
          if (state is PharmacyResponsesLoaded) return DataWidget(state.data);
          return SizedBox();
        },
      ),
    );
  }
}
```

---

## Injection de Dépendances (GetIt)

Tous les composants sont enregistrés dans `injection_container.dart`.

```dart
final sl = GetIt.instance;

Future<void> initPharmacyResponsesDependencies() async {
  // BLoC - Factory (nouvelle instance à chaque fois)
  sl.registerFactory(() => PharmacyResponsesCubit(
    getCommandeDetails: sl(),
    getReponsesForCommande: sl(),
  ));

  // Use Cases - Lazy Singleton
  sl.registerLazySingleton(() => GetCommandeDetails(sl()));
  sl.registerLazySingleton(() => GetReponsesForCommande(sl()));

  // Repository - Lazy Singleton
  sl.registerLazySingleton<PharmacyResponseRepository>(
    () => PharmacyResponseRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source - Lazy Singleton
  sl.registerLazySingleton<PharmacyResponseRemoteDataSource>(
    () => PharmacyResponseRemoteDataSourceImpl(client: sl(), sharedPreferences: sl()),
  );

  // External - Singleton
  sl.registerLazySingleton(() => http.Client());
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
}
```

---

## Flux de Données

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERACTION                         │
│                  (Bouton, Swipe, etc.)                       │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              PRESENTATION LAYER                              │
│                                                              │
│  PharmacyResponsesPage (BlocProvider)                       │
│         │                                                    │
│         ▼                                                    │
│  PharmacyResponsesCubit.loadCommandeDetails()               │
│         │                                                    │
│         │ emit(PharmacyResponsesLoading())                  │
│         │                                                    │
└─────────┼──────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                  DOMAIN LAYER                                │
│                                                              │
│  GetCommandeDetails.call(params)                            │
│         │                                                    │
│         ▼                                                    │
│  PharmacyResponseRepository.getCommandeDetails()            │
│         │                                                    │
└─────────┼──────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                   DATA LAYER                                 │
│                                                              │
│  PharmacyResponseRepositoryImpl                             │
│         │                                                    │
│         ▼                                                    │
│  PharmacyResponseRemoteDataSource                           │
│         │                                                    │
│         ▼                                                    │
│  HTTP GET /api/admin/commandes/:id/detail                   │
│         │                                                    │
└─────────┼──────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                  BACKEND API                                 │
│              (Node.js + PostgreSQL)                         │
└─────────────────────────────────────────────────────────────┘
          │
          │ Response JSON
          ▼
┌─────────────────────────────────────────────────────────────┐
│  CommandeDetailModel.fromJson(json)                         │
│         │                                                    │
│         ▼                                                    │
│  Either<Failure, CommandeDetailEntity>                      │
│         │                                                    │
└─────────┼──────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│  PharmacyResponsesCubit                                     │
│         │                                                    │
│         ├─ Success → emit(PharmacyResponsesLoaded(data))    │
│         └─ Failure → emit(PharmacyResponsesError(msg))      │
│                                                              │
└─────────┼──────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│  BlocBuilder rebuilds UI                                    │
│         │                                                    │
│         ├─ Loading → CircularProgressIndicator              │
│         ├─ Error → ErrorWidget                              │
│         ├─ Loaded → ListView with PharmacyResponseCards     │
│         └─ Empty → EmptyStateWidget                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Avantages de Clean Architecture

### 1. Testabilité

Chaque couche peut être testée indépendamment:

```dart
// Test du use case
test('GetCommandeDetails should return CommandeDetailEntity', () async {
  // Arrange
  when(mockRepository.getCommandeDetails(1))
      .thenAnswer((_) async => Right(tCommandeDetail));

  // Act
  final result = await getCommandeDetails(GetCommandeDetailsParams(commandeId: 1));

  // Assert
  expect(result, Right(tCommandeDetail));
  verify(mockRepository.getCommandeDetails(1));
});
```

### 2. Indépendance du Framework

La logique métier (Domain Layer) ne dépend **ni de Flutter ni de BLoC**. Elle peut être réutilisée dans:
- Une app Web
- Une app Desktop
- Un backend CLI
- Etc.

### 3. Maintenabilité

- **Séparation claire** des responsabilités
- **Facile à débugger**: chaque couche a son rôle
- **Facile à modifier**: changer l'UI n'affecte pas la logique métier

### 4. Scalabilité

L'ajout de nouvelles features suit le même pattern:
1. Créer les entités (Domain)
2. Créer le repository interface (Domain)
3. Créer les use cases (Domain)
4. Implémenter les models (Data)
5. Implémenter le data source (Data)
6. Implémenter le repository (Data)
7. Créer le BLoC (Presentation)
8. Créer l'UI (Presentation)

---

## Utilisation

### 1. Initialiser les dépendances

Dans `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les dépendances
  await initPharmacyResponsesDependencies();

  runApp(MyApp());
}
```

### 2. Naviguer vers la page

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PharmacyResponsesPage(
      commandeId: 8,
    ),
  ),
);
```

### 3. Le BLoC gère tout automatiquement

Le `PharmacyResponsesCubit` va:
1. Charger les données via le use case
2. Émettre les états appropriés
3. L'UI se reconstruit automatiquement

---

## Comparaison Avant/Après

| Aspect | Avant (Code simple) | Après (Clean Architecture) |
|--------|---------------------|----------------------------|
| **Structure** | Tout dans un fichier | 3 couches séparées |
| **État** | setState() | BLoC/Cubit |
| **Logique métier** | Dans les widgets | Domain Layer (Entities + Use Cases) |
| **API Calls** | Directement dans les widgets | Data Sources + Repositories |
| **Testabilité** | Difficile | Facile (mocks, stubs) |
| **Dépendances** | Couplage fort | Injection de dépendances |
| **Scalabilité** | Difficile | Excellente |
| **Maintenabilité** | Moyenne | Excellente |

---

## Principes SOLID Respectés

### S - Single Responsibility Principle
Chaque classe a **une seule responsabilité**:
- `GetCommandeDetails` → Récupérer les détails
- `PharmacyResponsesCubit` → Gérer les états
- `PharmacyResponseCard` → Afficher une carte

### O - Open/Closed Principle
Les classes sont **ouvertes à l'extension, fermées à la modification**.
Exemple: Ajouter un nouveau data source (cache) sans modifier le repository.

### L - Liskov Substitution Principle
Les implémentations peuvent remplacer les interfaces.
Exemple: `PharmacyResponseRepositoryImpl` remplace `PharmacyResponseRepository`.

### I - Interface Segregation Principle
Les interfaces sont spécifiques, pas génériques.
Exemple: `PharmacyResponseRemoteDataSource` vs un `DataSource` générique.

### D - Dependency Inversion Principle
Les couches hautes ne dépendent pas des couches basses, mais d'abstractions.
Exemple: `GetCommandeDetails` dépend de `PharmacyResponseRepository` (interface), pas de l'implémentation.

---

## Prochaines Étapes

### Court terme
- [ ] Ajouter des tests unitaires pour les use cases
- [ ] Ajouter des tests de widgets
- [ ] Implémenter le cache local (Data Source)

### Moyen terme
- [ ] Ajouter un state management pour les filtres
- [ ] Implémenter la pagination
- [ ] Ajouter les animations de transition

### Long terme
- [ ] Intégrer Socket.io pour temps réel
- [ ] Mode offline complet
- [ ] CI/CD avec tests automatiques

---

## Ressources

- **Clean Architecture**: Robert C. Martin (Uncle Bob)
- **BLoC Pattern**: [bloclibrary.dev](https://bloclibrary.dev)
- **GetIt**: [pub.dev/packages/get_it](https://pub.dev/packages/get_it)
- **Dartz**: [pub.dev/packages/dartz](https://pub.dev/packages/dartz)

---

## Conclusion

L'architecture Clean Architecture garantit:
- ✅ Code **maintenable** et **scalable**
- ✅ **Testabilité** maximale
- ✅ **Séparation des responsabilités**
- ✅ **Indépendance** des frameworks
- ✅ Respect des principes **SOLID**

Cette refactorisation transforme le code en une **architecture professionnelle** prête pour la production et l'évolution future de l'application.

---

**Date:** 2025-01-18
**Version:** 2.0.0 (Clean Architecture)
**Statut:** ✅ **OPÉRATIONNEL ET PROFESSIONNEL**
