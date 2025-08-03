// Fichier: lib/views/prescription_list_view.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/prescription_model.dart';
import '../models/prescription_status.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart';
import '../services/supabase_config.dart';
import '../views/manual_prescription_view.dart';
import '../views/pharmacy_responses_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionWithStatus {
  final String id;
  final String patientName;
  final DateTime date;
  final PrescriptionStatus status;
  final List products;

  PrescriptionWithStatus({
    required this.id,
    required this.patientName,
    required this.date,
    required this.status,
    required this.products,
  });
}

class ReponseListView extends StatefulWidget {
  final PrescriptionWithStatus? paidPrescription;

  const ReponseListView({
    Key? key,
    this.paidPrescription,
  }) : super(key: key);

  @override
  State<ReponseListView> createState() => _PrescriptionListViewState();
}

class _PrescriptionListViewState extends State<ReponseListView>
    with TickerProviderStateMixin {
  List<PrescriptionWithStatus> _prescriptions = [];
  bool _isLoading = true;
  late final SupabaseService _supabaseService;
  Timer? _refreshTimer;
  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;

  // Palette de couleurs moderne
  static const Color primary = Color(0xFF009688);
  static const Color primaryDark = Color(0xFF00695C);
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
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();

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

    _supabaseService = SupabaseService();
    _initializeSupabase();
    _loadPrescriptions();

    if (widget.paidPrescription != null) {
      _prescriptions.insert(0, widget.paidPrescription!);
    }

    // Démarrer les animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeSupabase() async {
    try {
      await _supabaseService.initialize();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          _loadPrescriptions();
        } else {
          timer.cancel();
        }
      });
      print('Rafraîchissement périodique des données configuré');
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
    }
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final localDbService = LocalDatabaseService();
      final localPrescriptions = await localDbService.getPrescriptions();

      List<PrescriptionWithStatus> prescriptionList = [];

      for (var prescription in localPrescriptions) {
        List<Map<String, dynamic>> products = prescription.medications.map((med) => {
          'name': med.medication.name,
          'quantity': 1,
          'form': med.medication.form,
          'dosage': med.medication.dosage,
          'usage': med.medication.usage,
        }).toList();

        PrescriptionStatus status = PrescriptionStatus.enAttente;

        prescriptionList.add(PrescriptionWithStatus(
          id: prescription.id,
          patientName: prescription.name,
          date: prescription.createdAt,
          status: status,
          products: products,
        ));
      }

      setState(() {
        _prescriptions = prescriptionList;
        _isLoading = false;
      });

      _listAnimationController.forward();

      try {
        final apiService = ApiService();
        final serverPrescriptions = await apiService.getPrescriptions();

        for (var prescription in serverPrescriptions) {
          await localDbService.insertPrescription(prescription);
        }

        final updatedLocalPrescriptions = await localDbService.getPrescriptions();
        List<PrescriptionWithStatus> updatedList = [];

        for (var prescription in updatedLocalPrescriptions) {
          List<Map<String, dynamic>> products = prescription.medications.map((med) => {
            'name': med.medication.name,
            'quantity': 1,
            'form': med.medication.form,
            'dosage': med.medication.dosage,
            'usage': med.medication.usage,
          }).toList();

          PrescriptionStatus status = PrescriptionStatus.enAttente;

          updatedList.add(PrescriptionWithStatus(
            id: prescription.id,
            patientName: prescription.name,
            date: prescription.createdAt,
            status: status,
            products: products,
          ));
        }

        if (mounted) {
          setState(() {
            _prescriptions = updatedList;
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération des données du serveur: $e');
      }
    } catch (e) {
      print('Erreur lors du chargement des ordonnances: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createNewPrescription() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const ManualPrescriptionView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((value) {
      if (value == true) {
        _loadPrescriptions();
      }
    });
  }

  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.enAttente:
        return warningColor;
      case PrescriptionStatus.validee:
        return successColor;
      case PrescriptionStatus.paye:
        return accent;
      default:
        return textSecondary;
    }
  }

  String _getStatusText(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.enAttente:
        return 'En attente';
      case PrescriptionStatus.validee:
        return 'Validée';
      case PrescriptionStatus.paye:
        return 'Payée';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.enAttente:
        return Icons.schedule_rounded;
      case PrescriptionStatus.validee:
        return Icons.verified_rounded;
      case PrescriptionStatus.paye:
        return Icons.payment_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  // Dans la méthode _buildCardHeader, remplacez cette partie :
  Widget _buildCardHeader(PrescriptionWithStatus prescription) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.1), primaryLight.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            color: primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prescription.patientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis, // Ajouté
                maxLines: 1, // Ajouté
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.medication_rounded,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded( // Ajouté Expanded ici
                    child: Text(
                      '${prescription.products.length} médicament${prescription.products.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis, // Ajouté
                      maxLines: 1, // Ajouté
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Flexible( // Remplacé le widget direct par Flexible
          child: _buildStatusBadge(prescription.status),
        ),
      ],
    );
  }

// Et dans _buildStatusBadge, ajoutez également une protection :
  Widget _buildStatusBadge(PrescriptionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible( // Ajouté Flexible
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis, // Ajouté
              maxLines: 1, // Ajouté
            ),
          ),
        ],
      ),
    );
  }

// Alternative : Si le problème persiste, vous pouvez également modifier _buildCardFooter :
  Widget _buildCardFooter(PrescriptionWithStatus prescription) {
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
            overflow: TextOverflow.ellipsis, // Ajouté
            maxLines: 1, // Ajouté
          ),
        ),
        const SizedBox(width: 8), // Ajouté un peu d'espace
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradient1, gradient2, gradient3],
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildAnimatedBackButton(),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Réponses des',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pharmacies',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildAnimatedPharmacyIcon(),
                        ],
                      ),
                      const SizedBox(height: 28),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Consultez les réponses et prix de différentes pharmacies',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionWithStatus prescription, int index) {
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
            opacity: animation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToPharmacyResponses(prescription),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(24),
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
                        _buildCardHeader(prescription),
                        const SizedBox(height: 20),
                        _buildCardContent(prescription),
                        const SizedBox(height: 16),
                        _buildCardFooter(prescription),
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


  Widget _buildCardContent(PrescriptionWithStatus prescription) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                      '${prescription.date.day.toString().padLeft(2, '0')}/${prescription.date.month.toString().padLeft(2, '0')}/${prescription.date.year}',
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



  void _navigateToPharmacyResponses(PrescriptionWithStatus prescription) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PharmacyResponsesView(
              patientName: prescription.patientName,
              productsList: prescription.products.map((product) {
                return {
                  'name': product['name'],
                  'description': 'Quantité: ${product['quantity']}',
                  'patientType': 'Adulte',
                };
              }).toList(),
              status: prescription.status,
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
      _loadPrescriptions();
    });
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
            'Aucune prescription',
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
            'Chargement des prescriptions...',
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildModernLoadingState()
                : _prescriptions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _prescriptions.length,
              itemBuilder: (context, index) {
                return _buildPrescriptionCard(_prescriptions[index], index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _createNewPrescription,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                highlightElevation: 0,
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Nouvelle prescription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}