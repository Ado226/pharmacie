// Fichier: lib/views/prescription_list_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../views/manual_prescription_view.dart';
import '../views/prescription_details_view_new.dart';
import '../core/config/api_config.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../services/unread_responses_service.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'home_view.dart';
import 'pharmacy_responses_list_view.dart';
import 'notifications_view.dart';

class PrescriptionWithStatus {
  final String id;
  final String patientName;
  final DateTime date;
  final String statut; // Statut backend (String)
  final List products;
  final String? photoUrl;

  PrescriptionWithStatus({
    required this.id,
    required this.patientName,
    required this.date,
    required this.statut,
    required this.products,
    this.photoUrl,
  });
}

class PrescriptionListView extends StatefulWidget {
  final PrescriptionWithStatus? paidPrescription;

  const PrescriptionListView({
    Key? key,
    this.paidPrescription,
  }) : super(key: key);

  @override
  State<PrescriptionListView> createState() => _PrescriptionListViewState();
}

class _PrescriptionListViewState extends State<PrescriptionListView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PrescriptionWithStatus> _commandes = [];

  // Compteur de réponses non lues pour le badge
  int _unreadResponsesCount = 0;

  // Compteur de notifications non lues
  int _notificationCount = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadCommandes();
    _loadUnreadCount();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    // Écouter les changements de compteur en temps réel
    _notificationSubscription = NotificationService.onUnreadCountChanged.listen((count) {
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    });

    // Charger le compteur initial
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationService.refreshUnreadCount();
    if (mounted) {
      setState(() {
        _notificationCount = count;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await UnreadResponsesService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadResponsesCount = count;
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Charge les commandes depuis l'API Node.js
  Future<void> _loadCommandes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        setState(() {
          _errorMessage = 'Vous n\'êtes pas connecté';
          _isLoading = false;
        });
        return;
      }

      print('🔄 Chargement des commandes depuis l\'API Node.js...');

      final response = await http.get(
        Uri.parse(ApiConfig.commandesUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Statut réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ ${data.length} commandes récupérées');

        final commandes = data.map((item) {
          // Récupérer les produits
          final produitsList = item['produits'] as List? ?? [];
          final products = produitsList.map((p) {
            final produit = p['produit'];
            String nomProduit;
            if (p['nom_produit_personnalise'] != null && p['nom_produit_personnalise'].toString().isNotEmpty) {
              nomProduit = p['nom_produit_personnalise'];
            } else if (produit != null && produit['nom'] != null) {
              nomProduit = produit['nom'];
            } else {
              nomProduit = 'Produit #${p['produit_id']}';
            }
            return {
              'name': nomProduit,
              'quantite': p['quantite'],
            };
          }).toList();

          return PrescriptionWithStatus(
            id: item['id'].toString(), // ID entier converti en String
            patientName: item['nom_patient'] ?? 'Patient inconnu',
            date: DateTime.parse(item['created_at'] ?? DateTime.now().toIso8601String()),
            statut: item['statut'] ?? 'en_attente',
            products: products,
            photoUrl: item['ordonnance_photo_url'],
          );
        }).toList();

        // Trier par date décroissante (plus récent en premier)
        commandes.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          _commandes = commandes;
          _isLoading = false;
        });
      } else {
        print('❌ Erreur API: ${response.body}');
        setState(() {
          _errorMessage = 'Erreur lors du chargement des commandes';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() {
        _errorMessage = 'Erreur de connexion: $e';
        _isLoading = false;
      });
    }
  }

  void _createNewPrescription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManualPrescriptionView(),
      ),
    );

    // Si une nouvelle ordonnance a été créée, recharger les données
    if (result == true) {
      _loadCommandes();
    }
  }

  /// Méthode pour obtenir la couleur d'un statut backend (String)
  /// NOUVEAU FLUX SIMPLIFIÉ (6 statuts) avec compatibilité rétroactive
  Color _getStatusColorFromString(String statut) {
    switch (statut.toLowerCase().trim()) {
      case 'en_attente':
        return Colors.orange;
      case 'en_cours':
      case 'validee': // Compatibilité rétroactive
        return const Color(0xFF2196F3); // Bleu - Réponses disponibles
      case 'en_preparation':
        return const Color(0xFF9C27B0); // Violet
      case 'livree':
      case 'prete': // Compatibilité rétroactive
        return const Color(0xFF4CAF50); // Vert
      case 'payee':
        return const Color(0xFF009688); // Teal
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Méthode pour obtenir le label d'un statut backend (String)
  /// NOUVEAU FLUX SIMPLIFIÉ (6 statuts) avec compatibilité rétroactive
  String _getStatusLabelFromString(String statut) {
    switch (statut.toLowerCase().trim()) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
      case 'validee': // Compatibilité rétroactive
        return 'Réponses disponibles';
      case 'en_preparation':
        return 'En préparation';
      case 'livree':
      case 'prete': // Compatibilité rétroactive
        return 'Livrée';
      case 'payee':
        return 'Payée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: const Color(0xFF0D9488),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes Ordonnances',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF0D9488),
          ),
        ),
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
        actions: [
          // Icône de notification avec badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0D9488)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsView()),
                  );
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      _notificationCount > 99 ? '99+' : '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0D9488)),
            onPressed: _loadCommandes,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Bouton pour créer une nouvelle ordonnance
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _createNewPrescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Créer une nouvelle ordonnance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Titre de la liste
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Historique des ordonnances',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              ),

              // Contenu principal avec padding pour la NavBar
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          // Barre de navigation flottante
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF80DEEA).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 0, false),
            _buildNavItem(Icons.chat_bubble_outline_rounded, 1, false),
            _buildNavItem(Icons.description_outlined, 2, true), // Sélectionné
            _buildNavItem(Icons.person_outline_rounded, 3, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool isSelected) {
    return InkWell(
      onTap: () {
        if (index == 0) {
          // Bouton accueil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
          );
        } else if (index == 1) {
          // Bouton message (réponses pharmacies)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PharmacyResponsesListView()),
          );
        } else if (index == 3) {
          // Bouton profil
          final authState = context.read<AuthBloc>().state;
          if (authState is LoginSuccess || authState is RegisterSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
        // index == 2 est la page actuelle, on ne fait rien
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Colors.teal.withOpacity(0.2),
                    const Color(0xFF00BCD4).withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: Colors.teal.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: Colors.teal.shade700,
              size: 26,
            ),
            // Badge pour l'icône message (index 1)
            if (index == 1 && _unreadResponsesCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      _unreadResponsesCount > 9 ? '9+' : '$_unreadResponsesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // État de chargement
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des ordonnances...'),
          ],
        ),
      );
    }

    // État d'erreur
    if (_errorMessage != null) {
      // Vérifier si c'est un message de non-connexion
      final isNotConnected = _errorMessage == 'Vous n\'êtes pas connecté';

      // Affichage pour non-connexion : icône petite, texte cliquable, centré en haut
      if (isNotConnected) {
        return Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.teal.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Vous n\'êtes pas connecté',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    ).then((_) => _loadCommandes());
                  },
                  child: Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D9488),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF0D9488),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Affichage pour erreur normale
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loadCommandes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Réessayer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Ajouter l'ordonnance payée si elle existe
    final prescriptions = List<PrescriptionWithStatus>.from(_commandes);
    if (widget.paidPrescription != null) {
      prescriptions.insert(0, widget.paidPrescription!);
    }

    // Liste vide
    if (prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Aucune ordonnance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première ordonnance',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Liste des ordonnances
    return RefreshIndicator(
      onRefresh: _loadCommandes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return InkWell(
            onTap: () async {
              // Navigation vers la page de détails
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrescriptionDetailsViewNew(
                    id: prescription.id, // ID entier (compatible avec l'API)
                  ),
                ),
              );
              // Recharger après retour (le statut peut avoir changé)
              _loadCommandes();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  left: BorderSide(
                    color: _getStatusColorFromString(prescription.statut),
                    width: 4,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône à gauche
                    Icon(
                      Icons.description_outlined,
                      color: const Color(0xFF0D9488),
                      size: 24,
                    ),
                    const SizedBox(width: 16),

                    // Contenu principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prescription.patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Date: ${prescription.date.day}/${prescription.date.month}/${prescription.date.year}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Flèche à droite
                        Icon(
                          Icons.arrow_forward_ios,
                          color: const Color(0xFF0D9488),
                          size: 16,
                        ),
                        const SizedBox(height: 14),
                        // Badge de statut
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColorFromString(prescription.statut).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabelFromString(prescription.statut),
                            style: TextStyle(
                              color: _getStatusColorFromString(prescription.statut),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
