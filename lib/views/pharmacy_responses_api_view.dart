// Fichier: lib/views/pharmacy_responses_api_view.dart
import 'package:flutter/material.dart';
import '../services/pharmacy_response_service.dart';
import '../models/pharmacy_response_api_model.dart';
import 'payment_view.dart';
import 'pharmacy_response_detail_view.dart';

class PharmacyResponsesApiView extends StatefulWidget {
  final int commandeId;

  const PharmacyResponsesApiView({
    Key? key,
    required this.commandeId,
  }) : super(key: key);

  @override
  State<PharmacyResponsesApiView> createState() => _PharmacyResponsesApiViewState();
}

class _PharmacyResponsesApiViewState extends State<PharmacyResponsesApiView>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  // Palette de couleurs uniforme - même que login
  static const Color _primaryTeal = Color(0xFF0D9488);
  static const Color _lightTeal = Color(0xFF5EEAD4);
  static const Color _teal700 = Color(0xFF0F766E);
  static const Color _background = Color(0xFFE0F2F1);
  static const Color _cardBackground = Colors.white;
  static const Color _shadowColor = Color(0x1A000000);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _warningColor = Color(0xFFFFA726);
  static const Color _errorColor = Color(0xFFEF5350);

  bool _isLoading = true;
  String? _errorMessage;
  CommandeDetailResponse? _commandeDetails;
  ReponsePharmacieApi? _selectedResponse;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCommandeDetails();
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
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadCommandeDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await PharmacyResponseService.getCommandeDetails(widget.commandeId);
      setState(() {
        _commandeDetails = details;
        _isLoading = false;
        // Sélectionner automatiquement la première réponse si disponible
        if (details.reponsesExistantes.isNotEmpty) {
          _selectedResponse = details.reponsesExistantes.first;
        }
        // Animation pulse si en attente
        if (details.reponsesExistantes.isEmpty) {
          _pulseAnimationController.repeat(reverse: true);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryTeal),
              ),
              SizedBox(height: 16),
              Text(
                'Chargement des réponses...',
                style: TextStyle(
                  color: _teal700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: _errorColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _teal700,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  height: 56,
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
                  child: ElevatedButton.icon(
                    onPressed: _loadCommandeDetails,
                    icon: Icon(Icons.refresh),
                    label: Text('Réessayer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                        const SizedBox(height: 20),
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
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _cardBackground,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(context);
            },
            child: Image.asset(
              'assets/icone/en-arriere.png',
              width: 24,
              height: 24,
              color: _primaryTeal,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_primaryTeal, _lightTeal],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Réponses Pharmacies',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardBackground, Color(0xFFF8FFFE)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _lightTeal.withOpacity(0.1),
                        _lightTeal.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    if (_commandeDetails == null) return SizedBox.shrink();

    final commande = _commandeDetails!.commande;

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
                  color: _primaryTeal.withOpacity(0.1),
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
                        colors: [_primaryTeal, _lightTeal],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
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
                        const SizedBox(height: 24),
                        _buildMedicationsList(),
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
    if (_commandeDetails == null) return SizedBox.shrink();

    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool shouldPulse = false;

    if (_commandeDetails!.reponsesExistantes.isEmpty) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule_rounded;
      statusText = 'En attente de réponses';
      shouldPulse = true;
    } else {
      statusColor = _primaryTeal;
      statusIcon = Icons.local_pharmacy_rounded;
      statusText = 'Réponses disponibles';
    }

    Widget statusWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
    if (_commandeDetails == null) return SizedBox.shrink();
    final commande = _commandeDetails!.commande;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryTeal, _lightTeal],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryTeal.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
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
                    'Commande #${commande.id}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Client #${commande.clientId}',
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
        const SizedBox(height: 15),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.06,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryTeal, _lightTeal],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: _primaryTeal.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${commande.commandeProduits.length} médicaments',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsList() {
    if (_commandeDetails == null) return SizedBox.shrink();
    final produits = _commandeDetails!.commande.commandeProduits;

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
                  colors: [_primaryTeal, _lightTeal],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Médicaments demandés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...produits.asMap().entries.map((entry) {
          int index = entry.key;
          CommandeProduitApi product = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 150)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildMedicationItem(product, index),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMedicationItem(CommandeProduitApi product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _background.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryTeal.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryTeal, _lightTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _primaryTeal.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.medication_liquid_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nomProduit,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quantité: ${product.quantite}',
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildPharmaciesSection() {
    if (_commandeDetails == null) return SizedBox.shrink();

    if (_commandeDetails!.reponsesExistantes.isEmpty) {
      return _buildNoResponsesSection();
    } else {
      return _buildMultipleResponsesSection();
    }
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
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_primaryTeal, _lightTeal],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: const Text(
                  'Aucune réponse pour le moment',
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
              const SizedBox(height: 32),
              _buildPharmaciesContactedInfo(),
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
                  colors: [_primaryTeal, _lightTeal],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPharmaciesContactedInfo() {
    if (_commandeDetails == null) return SizedBox.shrink();
    final pharmaciesProches = _commandeDetails!.pharmaciesProximite;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_pharmacy, color: _primaryTeal, size: 28),
              SizedBox(width: 12),
              Text(
                'Pharmacies contactées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _teal700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...pharmaciesProches.take(3).map((pharmacie) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _primaryTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacie.nom,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(pharmacie.distanceMetres / 1000).toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildMultipleResponsesSection() {
    final responses = _commandeDetails!.reponsesExistantes;

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
                    colors: [_primaryTeal, _lightTeal],
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
                  '${responses.length}',
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
          itemCount: responses.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 500 + (index * 200)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildModernPharmacyCard(responses[index], index),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildModernPharmacyCard(ReponsePharmacieApi response, int index) {
    final isSelected = _selectedResponse?.id == response.id;
    final isRecommended = index == 0; // Premier = recommandé
    final availabilityRatio = response.pourcentageDisponibilite / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          if (isRecommended)
            BoxShadow(
              color: _lightTeal.withOpacity(0.2),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
        ],
      ),
      child: Stack(
        children: [
          if (isRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryTeal, _lightTeal],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'RECOMMANDÉ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryTeal, _lightTeal],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryTeal.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
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
                                response.pharmacie?.nom ?? 'Pharmacie',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
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
                                  Expanded(
                                    child: Text(
                                      response.pharmacie?.quartier ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildPharmacyMetrics(response),
                    const SizedBox(height: 20),
                    _buildPharmacyPrice(response, isRecommended),
                  ],
                ),
              ),
              _buildPharmacyActionButton(response, isRecommended, index),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyMetrics(ReponsePharmacieApi response) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _background.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryTeal.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          _buildAvailabilityBar(response),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBar(ReponsePharmacieApi response) {
    final disponibles = response.nombreProduitsDisponibles;
    final total = response.nombreTotalProduits;
    final ratio = response.pourcentageDisponibilite / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Disponibilité des médicaments',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$disponibles/$total produits',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ratio == 1.0 ? _successColor : Colors.orange[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.0, end: ratio),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ratio == 1.0
                          ? [_successColor, Color(0xFF66BB6A)]
                          : [Colors.orange, Colors.orangeAccent],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPharmacyPrice(ReponsePharmacieApi response, bool isRecommended) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryTeal.withOpacity(0.05), _lightTeal.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryTeal.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryTeal, _lightTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _primaryTeal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix total',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_primaryTeal, _lightTeal],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    '${response.montantTotalPharmacie.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_successColor, Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'MEILLEUR PRIX',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPharmacyActionButton(
    ReponsePharmacieApi response,
    bool isRecommended,
    int index,
  ) {
    return Row(
      children: [
        // Bouton "Voir Détail"
        Expanded(
          flex: 1,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_teal700, _primaryTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: _teal700.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                ),
                onTap: () => _showResponseDetails(response),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'VOIR DÉTAIL',
                        style: TextStyle(
                          fontSize: 13,
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
        ),
        // Bouton "Sélectionner"
        Expanded(
          flex: 1,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryTeal, _lightTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryTeal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
                onTap: () => _selectPharmacy(response, index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRecommended ? 'CHOISIR' : 'SÉLECTIONNER',
                        style: const TextStyle(
                          fontSize: 13,
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
        ),
      ],
    );
  }


  void _showResponseDetails(ReponsePharmacieApi response) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyResponseDetailView(
          response: response,
          commande: _commandeDetails!.commande,
        ),
      ),
    );
  }

  void _selectPharmacy(ReponsePharmacieApi response, int index) {
    setState(() {
      _selectedResponse = response;
    });

    // Animation de sélection
    _cardAnimationController.reset();
    _cardAnimationController.forward();

    // Navigation vers le paiement
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentView(
          pharmacyName: response.pharmacie?.nom ?? 'Pharmacie',
          totalPrice: '${response.montantTotalPharmacie.toStringAsFixed(0)} FCFA',
          patientName: 'Client #${_commandeDetails!.commande.clientId}',
          productsList: _commandeDetails!.commande.commandeProduits
              .map((p) => {
                    'name': p.nomProduit,
                    'quantity': p.quantite.toString(),
                    'price': '${(response.produitsDisponibles
                                .firstWhere(
                                  (prod) => prod.produitId == p.produitId,
                                  orElse: () => ProduitDisponible(
                                      produitId: 0, disponible: false),
                                )
                                .prixUnitaire ??
                            0) * p.quantite} FCFA',
                  })
              .toList(),
        ),
      ),
    );
  }
}
