import 'package:flutter/material.dart';
import '../models/prescription_status.dart';
import '../models/pharmacy_response_api_model.dart';
import '../services/pharmacy_response_service.dart';
import '../core/config/api_config.dart';
import 'payment_view.dart';
import 'prescription_details_view_new.dart';

class PharmacyResponsesView extends StatefulWidget {
  final String patientName;
  final List<Map<String, dynamic>> productsList;
  final PrescriptionStatus status;
  final bool isEditing;
  final String? prescriptionId;
  final int? commandeId;
  final List<ReponsePharmacieApi>? pharmacyResponses;
  final String? ordonnancePhotoUrl;

  const PharmacyResponsesView({
    Key? key,
    required this.patientName,
    required this.productsList,
    this.status = PrescriptionStatus.enAttente,
    this.isEditing = false,
    this.prescriptionId,
    this.commandeId,
    this.pharmacyResponses,
    this.ordonnancePhotoUrl,
  }) : super(key: key);

  @override
  State<PharmacyResponsesView> createState() => _PharmacyResponsesViewState();
}

class _PharmacyResponsesViewState extends State<PharmacyResponsesView>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  // Palette de couleurs - Teal 700, blanc et dégradés teal 700 à teal 100
  static const Color _primary = Color(0xFF00796B);       // Teal 700
  static const Color _primaryDark = Color(0xFF004D40);   // Teal 900
  static const Color _primaryLight = Color(0xFF26A69A);  // Teal 400
  static const Color _teal100 = Color(0xFFB2DFDB);       // Teal 100
  static const Color _teal200 = Color(0xFF80CBC4);       // Teal 200
  static const Color _teal300 = Color(0xFF4DB6AC);       // Teal 300
  static const Color _teal50 = Color(0xFFE0F2F1);        // Teal 50
  static const Color _background = Color(0xFFE0F2F1);    // Teal 50 pour l'arrière-plan
  static const Color _cardBackground = Colors.white;
  static const Color _gradient1 = Color(0xFF00796B);     // Teal 700 (début dégradé)
  static const Color _gradient2 = Color(0xFF26A69A);     // Teal 400 (milieu)
  static const Color _gradient3 = Color(0xFFB2DFDB);     // Teal 100 (fin dégradé)
  static const Color _shadowColor = Color(0x1A000000);
  static const Color _successColor = Color(0xFF00796B);  // Teal 700 pour succès

  List<Map<String, dynamic>> _pharmacies = [];
  bool _isMedicationsExpanded = false; // État pour dérouler/replier les médicaments

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPharmacyResponses();
  }

  void _loadPharmacyResponses() async {
    print('🔍 DEBUG _loadPharmacyResponses:');
    print('   - widget.commandeId: ${widget.commandeId}');
    print('   - widget.pharmacyResponses: ${widget.pharmacyResponses}');
    print('   - widget.pharmacyResponses?.length: ${widget.pharmacyResponses?.length}');
    print('   - widget.status: ${widget.status}');

    List<ReponsePharmacieApi> reponses = [];

    // Si les réponses ne sont pas fournies mais qu'on a un commandeId, charger depuis l'API
    if ((widget.pharmacyResponses == null || widget.pharmacyResponses!.isEmpty) && widget.commandeId != null) {
      print('   📡 Chargement des réponses depuis l\'API pour commande #${widget.commandeId}...');
      try {
        final commandeDetails = await PharmacyResponseService.getCommandeDetails(widget.commandeId!);
        reponses = commandeDetails.reponsesExistantes;
        print('   ✅ ${reponses.length} réponse(s) chargée(s) depuis l\'API');
      } catch (e) {
        print('   ❌ Erreur lors du chargement des réponses: $e');
        return;
      }
    } else if (widget.pharmacyResponses != null && widget.pharmacyResponses!.isNotEmpty) {
      print('   ✅ Utilisation des réponses fournies en paramètre');
      reponses = widget.pharmacyResponses!;
    } else {
      print('   ⚠️ Aucune réponse disponible et pas de commandeId');
      return;
    }

    // Convertir les réponses API en format pour l'affichage
    if (reponses.isNotEmpty) {
      print('   ✅ On a ${reponses.length} réponse(s), on les charge...');
      setState(() {
        _pharmacies = reponses.map((response) {
        final pharmacie = response.pharmacie;
        final nombreDisponibles = response.nombreProduitsDisponibles;
        final nombreTotal = response.nombreTotalProduits;
        final availabilityRatio = nombreTotal > 0 ? nombreDisponibles / nombreTotal : 0.0;

        // Préparer la liste détaillée des produits avec prix
        final produitsDetails = response.produitsDisponibles.map((produit) {
          // Trouver le nom du produit depuis widget.productsList en utilisant le produit_id
          String nomProduit = 'Produit #${produit.produitId}';
          int quantiteCommande = 1;

          for (var p in widget.productsList) {
            // Correspondance par produit_id
            final pId = p['produit_id'] ?? p['id'];
            if (pId != null && pId.toString() == produit.produitId.toString()) {
              nomProduit = p['name'] ?? p['nom'] ?? 'Produit #${produit.produitId}';
              quantiteCommande = p['quantite'] ?? 1;
              break;
            }
          }

          return {
            'produit_id': produit.produitId,
            'nom': nomProduit,
            'disponible': produit.disponible,
            'prix_unitaire': produit.prixUnitaire,
            'quantite': produit.quantite ?? quantiteCommande,
            'prix_total': produit.prixTotal ?? (produit.prixUnitaire != null ? produit.prixUnitaire! * (produit.quantite ?? quantiteCommande) : 0),
          };
        }).toList();

        return {
          'id': response.id,
          'pharmacieId': response.pharmacieId, // NOUVEAU: ID de la pharmacie pour le backend
          'name': pharmacie?.nom ?? 'Pharmacie',
          'distance': 'N/A', // La distance n'est pas dans la réponse
          'deliveryTime': '30-45 min', // Temps de livraison estimé par défaut
          'price': '${response.montantTotalPharmacie.toStringAsFixed(0)} FCFA',
          'priceValue': response.montantTotalPharmacie,
          'availability': '$nombreDisponibles/$nombreTotal produits',
          'availabilityRatio': availabilityRatio,
          'selected': false,
          'rating': 4.5, // Note par défaut
          'reviews': 0,
          'isRecommended': response.tousProduitsDiponibles,
          'contactee': response.contactee,
          'reponseObtenue': response.reponseObtenue,
          'commentaire': response.commentairePharmacie,
          'adresse': pharmacie?.adresse ?? '',
          'quartier': pharmacie?.quartier ?? '',
          'telephone': pharmacie?.numeroTelephone,
          'produits': produitsDetails, // NOUVEAU: Liste détaillée des produits
          'responseData': response, // Garder la réponse complète pour référence
        };
      }).toList();

        // Sélectionner automatiquement la première pharmacie si disponible
        if (_pharmacies.isNotEmpty) {
          _pharmacies[0]['selected'] = true;
        }
      });

      print('   ✅ ${_pharmacies.length} pharmacies chargées');
    } else {
      print('   ❌ Aucune réponse à charger');
    }

    print('   - _pharmacies.length final: ${_pharmacies.length}');
  }

  /// Calculer le nombre total de médicaments en tenant compte des quantités
  int _calculateTotalMedicaments() {
    int total = 0;
    for (var product in widget.productsList) {
      // Si la quantité existe, l'utiliser, sinon compter 1
      final quantite = product['quantite'] as int? ?? 1;
      total += quantite;
    }
    return total;
  }

  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _mainAnimationController.forward();
    _cardAnimationController.forward();

    if (widget.status == PrescriptionStatus.enAttente) {
      _pulseAnimationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _mainAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildPrescriptionCard(),
                        const SizedBox(height: 32),
                        _buildPharmaciesSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 56,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _teal50,
      toolbarHeight: 56,
      leading: IconButton(
        icon: Image.asset(
          'assets/icone/en-arriere.png',
          width: 24,
          height: 24,
          color: _primary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Réponses Pharmacies',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: _primary,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildPrescriptionCard() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_cardBackground, Color(0xFFFFFFFE)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: _primary.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_gradient1, _gradient2, _gradient3],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBanner(),
                        const SizedBox(height: 24),
                        _buildPrescriptionHeader(),
                        if (widget.ordonnancePhotoUrl != null && widget.ordonnancePhotoUrl!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildOrdonnancePhoto(),
                        ],
                        // Afficher la liste des médicaments uniquement si ce n'est PAS une ordonnance photo seule
                        // (c'est-à-dire s'il y a des produits prédéfinis dans la liste)
                        if (widget.productsList.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildMedicationsList(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool shouldPulse = false;

    // NOUVEAU FLUX SIMPLIFIÉ (6 statuts):
    // en_attente → en_cours → payee → en_preparation → livree | annulee
    switch (widget.status) {
      case PrescriptionStatus.enAttente:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule_rounded;
        statusText = 'En attente de réponses';
        shouldPulse = true;
        break;
      case PrescriptionStatus.enCours:
        statusColor = _primary;
        statusIcon = Icons.local_pharmacy_rounded;
        statusText = 'Réponses disponibles - Choisissez une pharmacie';
        break;
      case PrescriptionStatus.paye:
        statusColor = const Color(0xFF009688); // Teal
        statusIcon = Icons.paid_rounded;
        statusText = 'Commande payée - En attente de préparation';
        shouldPulse = true;
        break;
      case PrescriptionStatus.enPreparation:
        statusColor = const Color(0xFF9C27B0); // Violet
        statusIcon = Icons.inventory_2_rounded;
        statusText = 'En préparation';
        shouldPulse = true;
        break;
      case PrescriptionStatus.livree:
        statusColor = _successColor;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Commande livrée - Terminé';
        break;
      case PrescriptionStatus.annulee:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Commande annulée';
        break;
    }

    Widget statusWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (shouldPulse)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );

    return shouldPulse
        ? AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: statusWidget,
            );
          },
        )
        : statusWidget;
  }

  Widget _buildPrescriptionHeader() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ordonnance pour',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.patientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),

        // Afficher le badge de nombre de médicaments uniquement si ce n'est PAS une ordonnance photo seule
        // (c'est-à-dire s'il y a des produits prédéfinis dans la liste)
        if (widget.productsList.isNotEmpty) ...[
          const SizedBox(height: 15),
          Container(
            width: MediaQuery.of(context).size.width ,  // 40% de la largeur de l'écran
            height: MediaQuery.of(context).size.height * 0.06, // 6% de la hauteur de l'écran
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primary, _teal300]),
              borderRadius: BorderRadius.circular(25),
            ),
            alignment: Alignment.center,
            child: Text(
              '${_calculateTotalMedicaments()} médicament${_calculateTotalMedicaments() > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Afficher la photo de l'ordonnance
  Widget _buildOrdonnancePhoto() {
    // Construire l'URL complète de l'image en utilisant ApiConfig
    String? fullImageUrl = widget.ordonnancePhotoUrl;
    if (fullImageUrl != null && fullImageUrl.isNotEmpty) {
      // Utiliser la méthode buildImageUrl d'ApiConfig qui gère automatiquement
      // les URLs complètes et relatives
      fullImageUrl = ApiConfig.buildImageUrl(fullImageUrl);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradient1, _gradient2],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Photo de l\'ordonnance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: fullImageUrl != null
              ? Image.network(
                  fullImageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Image non disponible',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _primary,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Aucune photo disponible',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMedicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête cliquable avec flèche pour dérouler/replier
        GestureDetector(
          onTap: () {
            setState(() {
              _isMedicationsExpanded = !_isMedicationsExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withOpacity(0.15), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradient1, _gradient2],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Médicaments demandés',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                // Badge du nombre de médicaments
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.productsList.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Flèche d'expansion
                AnimatedRotation(
                  turns: _isMedicationsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Liste des médicaments (visible uniquement si déroulé)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 8),
              ...widget.productsList.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> product = entry.value;
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildMedicationItem(product, index),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ),
          crossFadeState: _isMedicationsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // Résumé concis des médicaments : "Paracétamol 1, Ibuprofène 1, ..."
  Widget _buildMedicationsSummary() {
    final medicationsSummary = widget.productsList.map((product) {
      final name = product['name'] ?? 'Médicament';
      final quantite = product['quantite'] ?? 1;
      return '$name $quantite';
    }).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.list_alt_rounded,
            color: _primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              medicationsSummary,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _background.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gradient1.withOpacity(0.8),
                  _gradient2.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication_liquid_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              product['name'] ?? 'Médicament sans nom',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Afficher la quantité compacte à droite
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Qté ${product['quantite'] ?? 1}',
              style: TextStyle(
                fontSize: 13,
                color: _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmaciesSection() {
    print('🔍 DEBUG _buildPharmaciesSection:');
    print('   - widget.status: ${widget.status}');
    print('   - _pharmacies.length: ${_pharmacies.length}');

    // PRIORITÉ 1: Si la commande est annulée, afficher le message d'annulation
    if (widget.status == PrescriptionStatus.annulee) {
      print('   ➡️ Affichage: _buildCancelledSection (Commande annulée)');
      return _buildCancelledSection();
    }

    // PRIORITÉ 2: S'il y a des réponses de pharmacies, les afficher
    // (peu importe le statut - même si en_attente, on affiche les réponses si elles existent)
    if (_pharmacies.isNotEmpty) {
      // Si le statut est avancé (préparation, livrée, payée),
      // c'est qu'une pharmacie a été sélectionnée
      if (widget.status == PrescriptionStatus.enPreparation ||
          widget.status == PrescriptionStatus.livree ||
          widget.status == PrescriptionStatus.paye) {
        print('   ➡️ Affichage: _buildSelectedPharmacySection (Pharmacie sélectionnée)');
        return _buildSelectedPharmacySection();
      }

      // Sinon, afficher les réponses multiples pour que le client puisse choisir
      print('   ➡️ Affichage: _buildMultipleResponsesSection (Réponses multiples - ${_pharmacies.length} réponse(s))');
      return _buildMultipleResponsesSection();
    }

    // PRIORITÉ 3: Pas de réponses - afficher le message d'attente selon le statut
    switch (widget.status) {
      case PrescriptionStatus.enAttente:
        print('   ➡️ Affichage: _buildNoResponsesSection (Analyse en cours)');
        return _buildNoResponsesSection();

      case PrescriptionStatus.enCours:
        // En cours mais pas encore de réponses des pharmacies
        print('   ➡️ Affichage: _buildNoResponsesSection (En attente de réponses)');
        return _buildNoResponsesSection();

      case PrescriptionStatus.enPreparation:
      case PrescriptionStatus.livree:
      case PrescriptionStatus.paye:
        // Statut avancé mais pas de pharmacies chargées - afficher section vide
        print('   ➡️ Affichage: _buildSelectedPharmacySection (Pharmacie - liste vide)');
        return _buildSelectedPharmacySection();

      case PrescriptionStatus.annulee:
        print('   ➡️ Affichage: _buildCancelledSection (Commande annulée)');
        return _buildCancelledSection();
    }
  }

  /// Section affichée quand la commande est annulée
  Widget _buildCancelledSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.cancel_rounded,
              size: 48,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Commande annulée',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cette commande a été annulée.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResponsesSection() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardBackground, Color(0xFFFFFFFE)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.orange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.hourglass_empty_rounded,
                    size: 48,
                    color: Colors.orange[600],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [_primary, _teal300],
                    ).createShader(bounds),
                child: const Text(
                  'Analyse en cours...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Les pharmacies analysent votre demande.\nVous recevrez une notification dès qu\'une réponse sera disponible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              _buildAnimatedProgressBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedProgressBar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 3),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradient1, _gradient2, _gradient3],
                ),
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultipleResponsesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gradient1, _gradient2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Offres disponibles',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_successColor, Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _successColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_pharmacies.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _pharmacies.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 500 + (index * 200)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildModernPharmacyCard(_pharmacies[index], index),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildModernPharmacyCard(Map<String, dynamic> pharmacy, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardBackground, Color(0xFFFFFFFE)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          if (pharmacy['isRecommended'])
            BoxShadow(
              color: _primary.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
        ],
      ),
      child: Stack(
        children: [
          if (pharmacy['isRecommended'])
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _teal300]),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: const Text(
                  'RECOMMANDÉ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pharmacy['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ...List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < pharmacy['rating'].floor()
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 14,
                                      color: Colors.amber,
                                    );
                                  }),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${pharmacy['rating']} (${pharmacy['reviews']})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildPharmacyMetrics(pharmacy),
                    const SizedBox(height: 10),
                    _buildProductsDetails(pharmacy),
                    const SizedBox(height: 10),
                    _buildPharmacyPrice(pharmacy),
                  ],
                ),
              ),
              _buildPharmacyActionButton(pharmacy, index),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyMetrics(Map<String, dynamic> pharmacy) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _background.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricItem(
                Icons.location_on_rounded,
                pharmacy['distance'],
                'Distance',
                _teal300,
              ),
              const SizedBox(width: 12),
              _buildMetricItem(
                Icons.access_time_rounded,
                pharmacy['deliveryTime'],
                'Livraison',
                _primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAvailabilityBar(pharmacy),
        ],
      ),
    );
  }

  /// Widget pour afficher les détails des produits avec prix
  Widget _buildProductsDetails(Map<String, dynamic> pharmacy) {
    final produits = pharmacy['produits'] as List<dynamic>?;

    if (produits == null || produits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Détails des produits',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _teal300.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${produits.length} produit${produits.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),

          // Liste des produits
          ...produits.asMap().entries.map((entry) {
            final index = entry.key;
            final produit = entry.value as Map<String, dynamic>;
            final bool disponible = produit['disponible'] ?? false;
            final double? prixUnitaire = produit['prix_unitaire'] as double?;
            final int quantite = produit['quantite'] ?? 1;
            final double prixTotal = produit['prix_total'] ?? 0.0;
            final String nom = produit['nom'] ?? 'Produit';

            return Column(
              children: [
                if (index > 0) const Divider(height: 10, thickness: 0.5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icône disponibilité compacte
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: disponible ? _successColor.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: disponible ? _successColor : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          disponible ? Icons.check_rounded : Icons.close_rounded,
                          size: 14,
                          color: disponible ? _successColor : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Détails produit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Prix et quantité en ligne compacte
                          if (disponible && prixUnitaire != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _background,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Qté: $quantite',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _teal100.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${prixUnitaire.toStringAsFixed(0)} F/u',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Prix total compact
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${prixTotal.toStringAsFixed(0)} F',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _successColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (!disponible) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Non disponible',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBar(Map<String, dynamic> pharmacy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Disponibilité',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              pharmacy['availability'],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color:
                    pharmacy['availabilityRatio'] == 1.0
                        ? _successColor
                        : Colors.orange[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.0, end: pharmacy['availabilityRatio']),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          pharmacy['availabilityRatio'] == 1.0
                              ? [_successColor, Color(0xFF66BB6A)]
                              : [Colors.orange, Colors.orangeAccent],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPharmacyPrice(Map<String, dynamic> pharmacy) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.05), _teal100.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primary, _primaryLight]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix total',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [_primary, _teal300],
                      ).createShader(bounds),
                  child: Text(
                    pharmacy['price'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (pharmacy['isRecommended'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_successColor, Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MEILLEUR',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPharmacyActionButton(Map<String, dynamic> pharmacy, int index) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              pharmacy['isRecommended']
                  ? [_primary, _teal300]
                  : [_primary, _primaryLight],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          onTap: () => _selectPharmacy(pharmacy, index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  pharmacy['isRecommended']
                      ? 'CHOISIR'
                      : 'SÉLECTIONNER',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPharmacySection() {
    // Si aucune pharmacie n'est chargée, afficher un message d'attente
    if (_pharmacies.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: _successColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Commande en cours de traitement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre commande est prise en charge par une pharmacie.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final selectedPharmacy = _pharmacies.firstWhere(
      (pharmacy) => pharmacy['selected'] == true,
      orElse: () => _pharmacies.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_successColor, Color(0xFF66BB6A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Commande confirmée',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_successColor, Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _successColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardBackground, Color(0xFFFFFFFE)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _successColor.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.shade700.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPharmacy['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              selectedPharmacy['distance'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              selectedPharmacy['deliveryTime'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal.shade700.withOpacity(0.1),
                      Colors.teal.shade100.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.teal.shade700.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prix total',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          selectedPharmacy['price'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade700.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _viewReceipt(selectedPharmacy),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'VOIR LE REÇU',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildDeliveryTracker(),
      ],
    );
  }

  Widget _buildDeliveryTracker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre simple
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Suivi de livraison',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timeline horizontale
          Row(
            children: [
              _buildHorizontalStep(Icons.check_circle, 'Confirmé', true, true),
              _buildStepLine(true),
              _buildHorizontalStep(Icons.inventory_2_rounded, 'Préparation', true, false),
              _buildStepLine(false),
              _buildHorizontalStep(Icons.delivery_dining_rounded, 'En route', false, false),
              _buildStepLine(false),
              _buildHorizontalStep(Icons.home_rounded, 'Livré', false, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStep(IconData icon, String label, bool isCompleted, bool isActive) {
    final color = isCompleted ? Colors.teal.shade600 : (isActive ? Colors.teal.shade400 : Colors.grey.shade300);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.teal.shade600 : (isActive ? Colors.teal.shade100 : Colors.grey.shade100),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted ? Colors.white : color,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCompleted || isActive ? FontWeight.w600 : FontWeight.w400,
              color: isCompleted ? Colors.teal.shade700 : (isActive ? Colors.teal.shade600 : Colors.grey.shade500),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.teal.shade600 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  void _selectPharmacy(Map<String, dynamic> pharmacy, int index) {
    setState(() {
      for (var p in _pharmacies) {
        p['selected'] = false;
      }
      pharmacy['selected'] = true;
    });

    // Animation de sélection
    _cardAnimationController.reset();
    _cardAnimationController.forward();

    // Navigation vers le paiement avec commandeId, pharmacieId et montantTotal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentView(
              pharmacyName: pharmacy['name'],
              totalPrice: pharmacy['price'],
              patientName: widget.patientName,
              productsList: widget.productsList,
              commandeId: widget.commandeId,
              pharmacieId: pharmacy['pharmacieId'] as int?,
              montantTotal: pharmacy['priceValue'] as double?,
            ),
      ),
    );
  }

  void _proceedToPayment(Map<String, dynamic> pharmacy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentView(
              pharmacyName: pharmacy['name'],
              totalPrice: pharmacy['price'],
              patientName: widget.patientName,
              productsList: widget.productsList,
              commandeId: widget.commandeId,
              pharmacieId: pharmacy['pharmacieId'] as int?,
              montantTotal: pharmacy['priceValue'] as double?,
            ),
      ),
    );
  }

  void _viewReceipt(Map<String, dynamic> pharmacy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionDetailsViewNew(
          id: widget.commandeId.toString(),
        ),
      ),
    );
  }
}
