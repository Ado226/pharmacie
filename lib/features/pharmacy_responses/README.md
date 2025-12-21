# Feature: Pharmacy Responses (Clean Architecture)

## Guide de démarrage rapide

### 1. Initialisation

Dans votre fichier `main.dart`, initialisez les dépendances:

```dart
import 'features/pharmacy_responses/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les dépendances de la feature
  await initPharmacyResponsesDependencies();

  runApp(MyApp());
}
```

### 2. Navigation vers la page

```dart
import 'package:pharmacie/features/pharmacy_responses/presentation/pages/pharmacy_responses_page.dart';

// Dans votre code de navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PharmacyResponsesPage(
      commandeId: commandeId, // ID de la commande
    ),
  ),
);
```

### 3. C'est tout!

Le BLoC gère automatiquement:
- ✅ Le chargement des données
- ✅ La gestion des erreurs
- ✅ Les états de l'UI
- ✅ Le rafraîchissement

---

## Structure du Code

```
pharmacy_responses/
├── domain/              # Logique métier pure
│   ├── entities/        # Objets métier
│   ├── repositories/    # Contrats
│   └── usecases/        # Actions métier
├── data/                # Implémentation
│   ├── models/          # JSON ↔ Entities
│   ├── datasources/     # API Calls
│   └── repositories/    # Implémentation
├── presentation/        # UI
│   ├── bloc/            # State management
│   ├── pages/           # Screens
│   └── widgets/         # UI Components
└── injection_container.dart  # DI
```

---

## Exemple d'utilisation avancée

### Accéder au BLoC depuis la page

```dart
// Rafraîchir manuellement
context.read<PharmacyResponsesCubit>().refreshCommandeDetails(commandeId);

// Sélectionner une pharmacie
context.read<PharmacyResponsesCubit>().selectResponse(reponse);

// Désélectionner
context.read<PharmacyResponsesCubit>().clearSelection();
```

### Écouter les changements d'état

```dart
BlocListener<PharmacyResponsesCubit, PharmacyResponsesState>(
  listener: (context, state) {
    if (state is PharmacyResponsesError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: YourWidget(),
)
```

---

## Tests

### Tester un Use Case

```dart
void main() {
  late GetCommandeDetails usecase;
  late MockPharmacyResponseRepository mockRepository;

  setUp(() {
    mockRepository = MockPharmacyResponseRepository();
    usecase = GetCommandeDetails(mockRepository);
  });

  test('should get commande details from repository', () async {
    // Arrange
    when(mockRepository.getCommandeDetails(1))
        .thenAnswer((_) async => Right(tCommandeDetail));

    // Act
    final result = await usecase(GetCommandeDetailsParams(commandeId: 1));

    // Assert
    expect(result, Right(tCommandeDetail));
    verify(mockRepository.getCommandeDetails(1));
    verifyNoMoreInteractions(mockRepository);
  });
}
```

### Tester le BLoC

```dart
void main() {
  late PharmacyResponsesCubit cubit;
  late MockGetCommandeDetails mockGetCommandeDetails;

  setUp(() {
    mockGetCommandeDetails = MockGetCommandeDetails();
    cubit = PharmacyResponsesCubit(
      getCommandeDetails: mockGetCommandeDetails,
      // ...autres dépendances
    );
  });

  blocTest<PharmacyResponsesCubit, PharmacyResponsesState>(
    'emits [Loading, Loaded] when loadCommandeDetails is successful',
    build: () {
      when(mockGetCommandeDetails(any))
          .thenAnswer((_) async => Right(tCommandeDetail));
      return cubit;
    },
    act: (cubit) => cubit.loadCommandeDetails(1),
    expect: () => [
      PharmacyResponsesLoading(),
      PharmacyResponsesLoaded(commandeDetail: tCommandeDetail),
    ],
  );
}
```

---

## Troubleshooting

### Problème: "No provider found for PharmacyResponsesCubit"

**Solution:** Assurez-vous d'avoir initialisé les dépendances dans `main.dart`:
```dart
await initPharmacyResponsesDependencies();
```

### Problème: "Token non trouvé"

**Solution:** L'utilisateur doit se connecter d'abord pour obtenir le JWT token.

### Problème: "Erreur réseau"

**Solutions:**
1. Vérifier que le backend est démarré
2. Vérifier l'URL dans `ApiConfig.baseUrl`
3. Vérifier la connexion Internet

---

## Modification de l'API Base URL

Dans `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseHost = '192.168.11.101';  // Votre IP
  static const String basePort = '5000';
  static const String baseUrl = 'http://$baseHost:$basePort/api';
}
```

---

## Ajout d'une nouvelle fonctionnalité

Pour ajouter une nouvelle action (ex: "Marquer comme favori"):

1. **Domain:** Créer le use case
```dart
class MarkPharmacyAsFavorite extends UseCase<void, MarkAsFavoriteParams> {
  // ...
}
```

2. **Data:** Ajouter la méthode au data source
```dart
Future<void> markAsFavorite(int pharmacieId) async {
  // HTTP call
}
```

3. **Presentation:** Ajouter la méthode au Cubit
```dart
Future<void> markAsFavorite(int pharmacieId) async {
  // Appeler le use case
}
```

4. **UI:** Ajouter le bouton
```dart
IconButton(
  icon: Icon(Icons.favorite),
  onPressed: () => context.read<PharmacyResponsesCubit>().markAsFavorite(id),
)
```

---

## Dépendances requises

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  dartz: ^0.10.1
  get_it: ^7.6.4
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

---

## Documentation complète

Pour plus de détails sur l'architecture, consultez:
- `CLEAN_ARCHITECTURE_PHARMACY_RESPONSES.md` (Architecture détaillée)
- `INTEGRATION_COMPLETE.md` (Historique de l'intégration)

---

**Version:** 2.0.0 (Clean Architecture)
**Dernière mise à jour:** 2025-01-18
