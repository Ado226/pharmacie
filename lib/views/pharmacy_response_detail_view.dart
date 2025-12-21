// Fichier: lib/views/pharmacy_response_detail_view.dart
import 'package:flutter/material.dart';
import '../models/pharmacy_response_api_model.dart';
import '../models/prescription_status.dart';
import 'prescription_details_view_new.dart';

class PharmacyResponseDetailView extends StatefulWidget {
  final ReponsePharmacieApi response;
  final CommandeApi commande;
  final PrescriptionStatus? status; // Statut optionnel

  const PharmacyResponseDetailView({
    Key? key,
    required this.response,
    required this.commande,
    this.status,
  }) : super(key: key);

  @override
  State<PharmacyResponseDetailView> createState() => _PharmacyResponseDetailViewState();
}

class _PharmacyResponseDetailViewState extends State<PharmacyResponseDetailView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Palette de couleurs uniforme - même que login
  static const Color _primaryTeal = Color(0xFF0D9488);
  static const Color _lightTeal = Color(0xFF5EEAD4);
  static const Color _teal700 = Color(0xFF0F766E);
  static const Color _teal50 = Color(0xFFE0F2F1);
  static const Color _background = Color(0xFFE0F2F1);
  static const Color _cardBackground = Colors.white;
  static const Color _shadowColor = Color(0x1A000000);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _warningColor = Color(0xFFFFA726);
  static const Color _errorColor = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: _primaryTeal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Réponses des Pharmacies',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _primaryTeal,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Afficher le statut de la commande si disponible
                    if (widget.status != null) ...[
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                    ],
                    _buildPharmacyInfoCard(),
                    const SizedBox(height: 24),
                    _buildProductsListCard(),
                    const SizedBox(height: 24),
                    if (widget.response.commentairePharmacie != null &&
                        widget.response.commentairePharmacie!.isNotEmpty)
                      _buildCommentCard(),
                    const SizedBox(height: 24),
                    _buildTotalPriceCard(),
                    const SizedBox(height: 24),
                    // Bouton "Voir le reçu de paiement"
                    _buildViewReceiptButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Bouton pour voir le reçu de paiement - navigue vers PrescriptionDetailsViewNew
  /// Style identique au bouton de connexion de la page login
  Widget _buildViewReceiptButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryTeal, _lightTeal],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Naviguer vers PrescriptionDetailsViewNew avec l'ID de la commande
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionDetailsViewNew(
                id: widget.commande.id.toString(),
              ),
            ),
          );
        },
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
            Icon(Icons.receipt_long_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Voir le reçu de paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir la configuration du statut (couleur, icône, label)
  /// NOUVEAU FLUX SIMPLIFIÉ (6 statuts):
  /// en_attente → en_cours → payee → en_preparation → livree | annulee
  Map<String, dynamic> _getStatusConfig(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.enAttente:
        return {
          'color': _warningColor,
          'icon': Icons.schedule_rounded,
          'label': 'En attente',
          'description': 'Votre commande est en attente de réponses des pharmacies',
        };
      case PrescriptionStatus.enCours:
        return {
          'color': _primaryTeal,
          'icon': Icons.local_pharmacy_rounded,
          'label': 'Réponses disponibles',
          'description': 'Des pharmacies ont répondu, vous pouvez choisir',
        };
      case PrescriptionStatus.enPreparation:
        return {
          'color': const Color(0xFF9C27B0),
          'icon': Icons.inventory_2_rounded,
          'label': 'En préparation',
          'description': 'La pharmacie prépare votre commande',
        };
      case PrescriptionStatus.livree:
        return {
          'color': _successColor,
          'icon': Icons.check_circle_rounded,
          'label': 'Livrée',
          'description': 'Votre commande a été livrée',
        };
      case PrescriptionStatus.paye:
        return {
          'color': const Color(0xFF009688),
          'icon': Icons.paid_rounded,
          'label': 'Payée',
          'description': 'Commande payée - En attente de préparation',
        };
      case PrescriptionStatus.annulee:
        return {
          'color': _errorColor,
          'icon': Icons.cancel_rounded,
          'label': 'Annulée',
          'description': 'Cette commande a été annulée',
        };
    }
  }

  /// Widget pour afficher le statut de la commande
  Widget _buildStatusCard() {
    final status = widget.status!;
    final config = _getStatusConfig(status);
    final Color statusColor = config['color'];
    final IconData statusIcon = config['icon'];
    final String statusLabel = config['label'];
    final String statusDescription = config['description'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut: $statusLabel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
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

  Widget _buildPharmacyInfoCard() {
    final pharmacie = widget.response.pharmacie;
    if (pharmacie == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryTeal, _lightTeal],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacie.nom,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacie.quartier,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_rounded, pharmacie.adresse),
          if (pharmacie.numeroTelephone != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_rounded, pharmacie.numeroTelephone!),
          ],
          if (pharmacie.email != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email_rounded, pharmacie.email!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsListCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryTeal, _lightTeal],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Produits disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryTeal, _lightTeal],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.response.nombreProduitsDisponibles}/${widget.response.nombreTotalProduits}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...widget.response.produitsDisponibles.asMap().entries.map((entry) {
            int index = entry.key;
            ProduitDisponible produit = entry.value;
            // Trouver le produit correspondant dans la commande
            CommandeProduitApi? commandeProduit;
            try {
              commandeProduit = widget.commande.commandeProduits.firstWhere(
                (p) => p.produitId == produit.produitId,
              );
            } catch (e) {
              // Produit non trouvé
            }

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildProductItem(produit, commandeProduit),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProduitDisponible produit, CommandeProduitApi? commandeProduit) {
    final isAvailable = produit.disponible;
    final nomProduit = commandeProduit?.nomProduit ?? 'Produit #${produit.produitId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? _successColor.withOpacity(0.05)
            : _errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? _successColor.withOpacity(0.2)
              : _errorColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? _successColor.withOpacity(0.1)
                      : _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isAvailable ? _successColor : _errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomProduit,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable ? 'Disponible' : 'Non disponible',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? _successColor : _errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAvailable && produit.prixUnitaire != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _teal50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Quantité: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${produit.quantite ?? commandeProduit?.quantite ?? 0}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Prix unitaire: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${produit.prixUnitaire!.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (produit.prixTotal != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryTeal.withOpacity(0.15), _teal50],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sous-total:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${produit.prixTotal!.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_warningColor.withOpacity(0.05), _warningColor.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _warningColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.comment_rounded,
                  color: _warningColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Commentaire de la pharmacie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.response.commentairePharmacie!,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPriceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryTeal, _lightTeal],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONTANT TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.response.montantTotalPharmacie.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
