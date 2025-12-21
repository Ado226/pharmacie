import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'pharmacy_responses_list_view.dart';

class OrdonnanceView extends StatefulWidget {
  const OrdonnanceView({Key? key}) : super(key: key);

  @override
  State<OrdonnanceView> createState() => _OrdonnanceViewState();
}

class _OrdonnanceViewState extends State<OrdonnanceView>
    with TickerProviderStateMixin {
  File? _image;
  bool _isSaving = false;
  final _nomPatientController = TextEditingController();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _shimmerAnimation;

  // Palette de couleurs
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Scale Animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Slide Animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Pulse Animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation Animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // Shimmer Animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    _nomPatientController.dispose();
    super.dispose();
  }

  Future<void> _prendrePhoto() async {
    HapticFeedback.mediumImpact();
    _rotationController.forward().then((_) => _rotationController.reset());

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  Future<void> _choisirGalerie() async {
    HapticFeedback.lightImpact();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  void _supprimerImage() {
    HapticFeedback.lightImpact();
    setState(() {
      _image = null;
    });
    _fadeController.reset();
    _scaleController.reset();
  }

  // ✅ CLEAN ARCHITECTURE: Utiliser PrescriptionBloc pour enregistrer l'ordonnance
  Future<void> _enregistrerOrdonnance() async {
    if (_image == null) return;

    // Vérifier l'authentification
    final authState = context.read<AuthBloc>().state;
    if (authState is! LoginSuccess && authState is! RegisterSuccess) {
      // L'utilisateur n'est pas connecté, afficher une boîte de dialogue
      HapticFeedback.mediumImpact();

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_outline, color: primary, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Connexion requise',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Vous devez être connecté pour enregistrer une ordonnance. Voulez-vous vous connecter maintenant?',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler', style: TextStyle(fontSize: 16, color: Colors.teal.shade700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (result == true) {
        // Naviguer vers la page de connexion
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }

      return;
    }

    // L'utilisateur est connecté, procéder à l'enregistrement
    HapticFeedback.heavyImpact();
    setState(() {
      _isSaving = true;
    });
    _shimmerController.repeat();

    try {
      // Récupérer le token de l'utilisateur connecté
      final token = (authState is LoginSuccess)
          ? authState.token
          : (authState as RegisterSuccess).token;

      // Construire les données de l'ordonnance pour le backend
      final Map<String, dynamic> prescriptionData = {
        'type_commande': 'ordonnance_photo',
        'nom_patient': _nomPatientController.text.trim(),
        'localisation': {
          'latitude': 0.0,
          'longitude': 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Créer une requête multipart pour envoyer l'image
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.commandesUrl),
      );

      // Ajouter les headers
      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter les données JSON
      request.fields['data'] = json.encode(prescriptionData);

      // Ajouter le fichier image avec détection du type MIME
      final imageBytes = await _image!.readAsBytes();
      final imageName = _image!.path.split(Platform.pathSeparator).last;
      final imageExtension = imageName.split('.').last.toLowerCase();

      // Déterminer le Content-Type basé sur l'extension
      String contentTypeHeader = 'image/jpeg';
      if (imageExtension == 'png') {
        contentTypeHeader = 'image/png';
      } else if (imageExtension == 'jpg' || imageExtension == 'jpeg') {
        contentTypeHeader = 'image/jpeg';
      } else if (imageExtension == 'gif') {
        contentTypeHeader = 'image/gif';
      } else if (imageExtension == 'webp') {
        contentTypeHeader = 'image/webp';
      }

      // Créer le MultipartFile avec le bon content-type
      final multipartFile = http.MultipartFile.fromBytes(
        'ordonnance_photo',
        imageBytes,
        filename: imageName,
      );

      // Ajouter manuellement le header Content-Type au fichier
      request.headers['Content-Type'] = 'multipart/form-data';
      request.files.add(multipartFile);

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur lors de l\'enregistrement: ${response.body}');
      }

      if (mounted) {
        _shimmerController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ordonnance enregistrée avec succès!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 3),
            elevation: 8,
          ),
        );

        // Rediriger vers la page des réponses des pharmacies
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PharmacyResponsesListView()),
        );
      }
    } catch (e) {
      if (mounted) {
        _shimmerController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.error, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur: ${e.toString()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 3),
            elevation: 8,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildImageContainer(double width, double height) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: width,
        height: height * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              spreadRadius: 0,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: accentLight.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 40,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: _image == null
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient1.withOpacity(0.1),
                  gradient2.withOpacity(0.15),
                  gradient3.withOpacity(0.1),
                ],
                stops: [0.0, 0.5, 1.0],
              )
                  : null,
              color: _image != null ? cardBackground : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _image == null ? accent.withOpacity(0.2) : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _image == null ? _prendrePhoto : null,
              splashColor: accent.withOpacity(0.1),
              highlightColor: accentLight.withOpacity(0.05),
              child: _image == null
                  ? _buildEmptyState()
                  : _buildImageState(width, height),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.1),
                      primaryLight.withOpacity(0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 72,
                        color: primaryDark,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Capturer une ordonnance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Appuyez ici pour prendre une photo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageState(double width, double height) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.file(
                _image!,
                width: width,
                height: height * 0.45,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _supprimerImage,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    const Color primaryTeal = Color(0xFF0D9488);
    const Color lightTeal = Color(0xFF5EEAD4);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
          BoxShadow(
            color: primaryTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          splashColor: isPrimary ? Colors.white.withOpacity(0.2) : primaryTeal.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [primaryTeal, lightTeal],
              )
                  : null,
              color: isPrimary ? null : primaryTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: isPrimary
                  ? null
                  : Border.all(
                color: primaryTeal.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                if (isLoading && isPrimary)
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Transform.translate(
                            offset: Offset(_shimmerAnimation.value * 200, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Centre parfaitement le contenu
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading) ...[
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(
                              isPrimary ? Colors.white : primaryTeal,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                      ] else ...[
                        Icon(
                          icon,
                          size: 20,
                          color: isPrimary ? Colors.white : primaryTeal,
                        ),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isPrimary ? Colors.white : primaryTeal,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNomPatientField() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _nomPatientController,
        cursorColor: Colors.teal.shade700,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: 'Nom du patient',
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.teal.shade700,
            fontWeight: FontWeight.w600,
          ),
          hintText: 'Ex: Jean Dupont',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade700.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_outline, color: Colors.teal.shade700, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
          ),
          filled: true,
          fillColor: cardBackground,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
          'Nouvelle Ordonnance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF0D9488),
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  background,
                  cardBackground,
                ],
                stops: [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 100.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 124, // padding + navbar
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),

                            // Image Container
                            _buildImageContainer(width, height),

                            SizedBox(height: 24),

                            // Champ nom du patient
                            _buildNomPatientField(),

                            SizedBox(height: 24),

                            // Action Buttons
                            if (_image == null) ...[
                              _buildActionButton(
                                icon: Icons.camera_alt_rounded,
                                label: "Prendre une photo",
                                onPressed: _prendrePhoto,
                                color: primary,
                                isPrimary: true,
                              ),
                              SizedBox(height: 20),
                              _buildActionButton(
                                icon: Icons.photo_library_rounded,
                                label: "Choisir depuis la galerie",
                                onPressed: _choisirGalerie,
                                color: accent,
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.camera_alt_rounded,
                                      label: "Reprendre",
                                      onPressed: _prendrePhoto,
                                      color: primaryLight,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.photo_library_rounded,
                                      label: "Galerie",
                                      onPressed: _choisirGalerie,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            Spacer(),

                            // Save Button
                            if (_image != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: _buildActionButton(
                                  icon: Icons.save_rounded,
                                  label: _isSaving ? "Enregistrement..." : "Enregistrer l'ordonnance",
                                  onPressed: _isSaving ? () {} : _enregistrerOrdonnance,
                                  color: primaryDark,
                                  isPrimary: true,
                                  isLoading: _isSaving,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}