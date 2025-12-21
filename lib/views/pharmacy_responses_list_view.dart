// Fichier: lib/views/pharmacy_responses_list_view.dart
// Page qui affiche la liste des commandes pour consulter les réponses des pharmacies
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../services/pharmacy_response_service.dart';
import '../services/unread_responses_service.dart';
import '../services/notification_service.dart';
import '../models/prescription_status.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'pharmacy_responses_view.dart';
import 'home_view.dart';
import 'ordonnance_views.dart';
import 'prescription_list_view.dart';
import 'manual_prescription_view.dart';
import 'notifications_view.dart';

class PharmacyResponsesListView extends StatefulWidget {
  const PharmacyResponsesListView({Key? key}) : super(key: key);

  @override
  State<PharmacyResponsesListView> createState() => _PharmacyResponsesListViewState();
}

class _PharmacyResponsesListViewState extends State<PharmacyResponsesListView>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;

  // Palette de couleurs moderne
  static const Color primary = Color(0xFF009688);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF80DEEA);
  static const Color background = Color(0xFFF0FDFF);
  static const Color cardBackground = Colors.white;
  static const Color gradient1 = Color(0xFF00BCD4);
  static const Color gradient2 = Color(0xFF4DB6AC);
  static const Color gradient3 = Color(0xFF81C784);
  static const Color shadowColor = Color(0x1A000000);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _commandes = [];

  // Compteur de notifications non lues
  int _notificationCount = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();

    // Écouter les notifications en temps réel
    _setupNotificationListener();

    // Initialiser les animations
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic),
    );

    // Démarrer les animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fabAnimationController.forward();
    });

    _loadCommandes();
  }

  void _setupNotificationListener() {
    _notificationSubscription = NotificationService.onUnreadCountChanged.listen((count) {
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    });
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

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCommandes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final commandes = await PharmacyResponseService.getMesCommandes();
      setState(() {
        _commandes = commandes;
        _isLoading = false;
      });

      _listAnimationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.teal[700]!,
                    Colors.teal[400]!,
                    Colors.teal[100]!,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Bouton retour simple comme PrescriptionListView
                          IconButton(
                            icon: Image.asset(
                              'assets/icone/en-arriere.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Réponses des',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(right: 40),
                                  child: const Text(
                                    'Pharmacies',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Icône de notification avec badge
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
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
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPharmacyIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.teal[600]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Consultez les réponses et prix des pharmacies',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToPharmacyResponses(Map<String, dynamic> commande) async {
    final commandeId = commande['id'];
    print('🚀 DÉBUT _navigateToPharmacyResponses - Commande #$commandeId');

    // Afficher un loader transparent pendant le chargement des détails
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 4,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des détails...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      print('⏳ Appel API PharmacyResponseService.getCommandeDetails($commandeId)...');
      // Récupérer les détails COMPLETS de la commande depuis l'API
      final commandeDetails = await PharmacyResponseService.getCommandeDetails(commandeId);
      print('✅ Réponse API reçue!');
      print('   - commandeDetails.reponsesExistantes.length: ${commandeDetails.reponsesExistantes.length}');
      print('   - commandeDetails.pharmaciesProximite.length: ${commandeDetails.pharmaciesProximite.length}');
      print('   - commandeDetails.commande.statut: ${commandeDetails.commande.statut}');

      // Fermer le loader
      if (mounted) Navigator.of(context).pop();

      // Extraire le nom du patient
      String patientName = 'Patient';
      if (commande['nom_patient'] != null && commande['nom_patient'].toString().isNotEmpty) {
        patientName = commande['nom_patient'];
      } else if (commande['Client'] != null) {
        final client = commande['Client'] as Map<String, dynamic>;
        final numero = client['numero'] ?? '';
        if (numero.isNotEmpty) {
          patientName = numero;
        } else {
          final nom = client['nom'] ?? '';
          final prenom = client['prenom'] ?? '';
          if (nom.isNotEmpty || prenom.isNotEmpty) {
            patientName = '$prenom $nom'.trim();
          }
        }
      }

      final ordonnancePhotoUrl = commandeDetails.commande.ordonnancePhotoUrl;
      final produits = commandeDetails.commande.commandeProduits;

      // DEBUG: Afficher les produits récupérés
      print('🔍 DEBUG Navigation - Commande #${commandeId}:');
      print('   - Type commande: ${commandeDetails.commande.typeCommande}');
      print('   - Nombre de produits: ${produits.length}');
      print('   - Produits: ${produits.map((p) => '${p.nomProduit} x${p.quantite}').join(', ')}');

      // Préparer la liste des produits
      List<Map<String, dynamic>> productsList = [];

      // Afficher les vrais produits de la commande (qu'il y ait photo ou saisie manuelle)
      for (var produit in produits) {
        productsList.add({
          'produit_id': produit.produitId, // IMPORTANT: Ajouter l'ID pour la correspondance
          'name': produit.nomProduit,
          'description': 'Quantité: ${produit.quantite}',
          'patientType': produit.ageCible,
          'quantite': produit.quantite,
        });
      }

      // Ne PAS ajouter de produit générique si la liste est vide
      // car on veut que les ordonnances photo seules (sans produits prédéfinis)
      // n'affichent pas la section "médicaments demandés"

      // Récupérer les réponses des pharmacies depuis l'API
      final reponses = commandeDetails.reponsesExistantes;

      // DEBUG: Afficher toutes les infos de commandeDetails
      print('🔍 DEBUG commandeDetails:');
      print('   - reponsesExistantes.length: ${reponses.length}');
      print('   - pharmaciesProximite.length: ${commandeDetails.pharmaciesProximite.length}');
      print('   - commande.statut: ${commandeDetails.commande.statut}');
      if (reponses.isNotEmpty) {
        print('   - Première réponse:');
        print('     - pharmacie_id: ${reponses[0].pharmacieId}');
        print('     - montant_total: ${reponses[0].montantTotalPharmacie}');
        print('     - produits.length: ${reponses[0].produitsDisponibles.length}');
        print('     - pharmacie nom: ${reponses[0].pharmacie?.nom ?? "null"}');
      }

      // Utiliser le VRAI statut du backend (pas calculé localement!)
      final backendStatut = commandeDetails.commande.statut;
      final status = PrescriptionStatusExtension.fromBackendString(backendStatut);

      print('🔍 DEBUG Status - Statut backend: $backendStatut, PrescriptionStatus: $status');

      // Marquer cette commande comme vue (pour le badge)
      await UnreadResponsesService.markAsViewed(commandeId);

      // Naviguer vers la vue avec les vraies réponses des pharmacies
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PharmacyResponsesView(
                  patientName: patientName,
                  productsList: productsList,
                  status: status,
                  commandeId: commandeId,
                  pharmacyResponses: reponses,
                  ordonnancePhotoUrl: ordonnancePhotoUrl,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ).then((_) {
          _loadCommandes();
        });
      }
    } catch (e) {
      // Fermer le loader
      if (mounted) Navigator.of(context).pop();

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary.withOpacity(0.1), primaryLight.withOpacity(0.1)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.local_pharmacy_outlined,
                    size: 80,
                    color: primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Aucune commande',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Créez votre première prescription\npour commencer à recevoir des réponses',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: primary.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: CircularProgressIndicator(
              color: primary,
              strokeWidth: 4,
              backgroundColor: primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Chargement des commandes...',
            style: TextStyle(
              color: textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildModernLoadingState()
                    : _errorMessage != null
                    ? _buildErrorCard()
                    : _commandes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
                  itemCount: _commandes.length,
                  itemBuilder: (context, index) {
                    return _buildCommandeCard(_commandes[index], index);
                  },
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: AnimatedBuilder(
          animation: _fabAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabAnimation.value,
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManualPrescriptionView(),
                        ),
                      ).then((_) => _loadCommandes());
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Nouveau',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    // Vérifier si c'est une erreur de non-connexion (token)
    final isNotConnected = _errorMessage != null &&
        (_errorMessage!.toLowerCase().contains('token') ||
         _errorMessage!.toLowerCase().contains('non connecté') ||
         _errorMessage!.toLowerCase().contains('authentification'));

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

    // Erreur normale
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: errorColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: errorColor, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
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
              child: ElevatedButton.icon(
                onPressed: _loadCommandes,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandeCard(Map<String, dynamic> commande, int index) {
    // L'API /client/commandes ne retourne que les infos basiques de la commande
    // Les détails complets (produits, client) seront chargés au clic
    final int commandeId = commande['id'];
    final String typeCommande = commande['type_commande'] ?? 'saisie_manuelle';
    final statut = commande['statut'] ?? commande['status'] ?? 'En attente';
    final dateCreation = commande['created_at'] ?? commande['date_creation'] ?? '';
    final String? nomPatient = commande['nom_patient'];

    // Formater la date
    String dateFormatted = 'N/A';
    if (dateCreation.isNotEmpty) {
      try {
        final date = DateTime.parse(dateCreation);
        dateFormatted = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        dateFormatted = dateCreation.split('T')[0];
      }
    }

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 60 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToPharmacyResponses(commande),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: primary.withOpacity(0.05),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                      border: Border.all(
                        color: primary.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(commandeId, typeCommande, statut, nomPatient),
                        const SizedBox(height: 12),
                        _buildCardContent(dateFormatted),
                        const SizedBox(height: 10),
                        _buildCardFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(int commandeId, String typeCommande, String statut, String? nomPatient) {
    // Nom du patient avec fallback pour les anciennes commandes
    final String displayPatientName = (nomPatient != null && nomPatient.isNotEmpty)
        ? nomPatient
        : 'Patient non renseigné';

    // Icône selon le type de commande
    IconData icon = typeCommande == 'ordonnance_photo'
        ? Icons.camera_alt_rounded
        : Icons.edit_note_rounded;

    String typeLabel = typeCommande == 'ordonnance_photo'
        ? 'Photo ordonnance'
        : 'Saisie manuelle';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.1), primaryLight.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayPatientName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusBadge(statut),
      ],
    );
  }

  Widget _buildStatusBadge(String statut) {
    // Définir les couleurs et labels pour chaque statut
    final statusConfig = _getStatusConfig(statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusConfig['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        statusConfig['label'],
        style: TextStyle(
          color: statusConfig['color'],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  /// Retourne la configuration (couleur et label) pour chaque statut
  /// NOUVEAU FLUX SIMPLIFIÉ (6 statuts):
  /// en_attente → en_cours → payee → en_preparation → livree | annulee
  Map<String, dynamic> _getStatusConfig(String statut) {
    // Normaliser le statut (minuscule, sans espaces)
    final normalizedStatut = statut.toLowerCase().trim();

    switch (normalizedStatut) {
      case 'en_attente':
        return {
          'color': warningColor, // Orange
          'label': 'En attente',
        };
      case 'en_cours':
        return {
          'color': accent, // Cyan
          'label': 'Réponses disponibles',
        };
      case 'en_preparation':
        return {
          'color': const Color(0xFF9C27B0), // Violet
          'label': 'En préparation',
        };
      case 'livree':
        return {
          'color': const Color(0xFF4CAF50), // Vert
          'label': 'Livrée',
        };
      case 'payee':
        return {
          'color': const Color(0xFF009688), // Teal
          'label': 'Payée',
        };
      case 'annulee':
        return {
          'color': errorColor, // Rouge
          'label': 'Annulée',
        };
      // Compatibilité avec anciens statuts (mapping vers nouveaux)
      case 'validee':
        return {
          'color': accent, // Cyan - même que en_cours
          'label': 'Réponses disponibles',
        };
      case 'prete':
        return {
          'color': const Color(0xFF4CAF50), // Vert - même que livree
          'label': 'Livrée',
        };
      default:
        return {
          'color': textSecondary, // Gris par défaut
          'label': statut,
        };
    }
  }

  Widget _buildCardContent(String dateFormatted) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date de prescription',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Appuyez pour voir les réponses',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.1), accentLight.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: accent,
            size: 16,
          ),
        ),
      ],
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
            accentLight.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.2),
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
            _buildNavItem(Icons.chat_bubble_outline_rounded, 1, true),
            _buildNavItem(Icons.description_outlined, 2, false),
            _buildNavItem(Icons.person_outline_rounded, 3, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool isSelected) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: InkWell(
            onTap: () {
              // Navigation basée sur l'index
              if (index == 0) {
                // Bouton accueil
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
              } else if (index == 2) {
                // Bouton ordonnances (mes ordonnances - historique)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PrescriptionListView()),
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
              // index == 1 est la page actuelle, on ne fait rien
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [
                    primary.withOpacity(0.2),
                    accent.withOpacity(0.1),
                  ],
                )
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                  color: primary.withOpacity(0.3),
                  width: 1,
                )
                    : null,
              ),
              child: Icon(
                icon,
                color: Colors.teal.shade700,
                size: 26,
              ),
            ),
          ),
        );
      },
    );
  }
}
