import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class OrdonnanceView extends StatefulWidget {
  const OrdonnanceView({Key? key}) : super(key: key);

  @override
  State<OrdonnanceView> createState() => _OrdonnanceViewState();
}

class _OrdonnanceViewState extends State<OrdonnanceView>
    with TickerProviderStateMixin {
  File? _image;
  bool _isSaving = false;

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

  Future<void> _enregistrerOrdonnance() async {
    if (_image == null) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isSaving = true;
    });
    _shimmerController.repeat();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        _shimmerController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
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
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 3),
            elevation: 8,
          ),
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
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.error, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors de l\'enregistrement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 3),
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
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary
            ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          splashColor: isPrimary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradient1, gradient2],
              )
                  : null,
              color: isPrimary ? null : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: isPrimary
                  ? null
                  : Border.all(
                color: color.withOpacity(0.2),
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
                              isPrimary ? Colors.white : color,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                      ] else ...[
                        Icon(
                          icon,
                          size: 28,
                          color: isPrimary ? Colors.white : color,
                        ),
                        SizedBox(width: 16),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPrimary ? Colors.white : color,
                            letterSpacing: 0.5,
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
        leading: Container(
          margin: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primaryDark,
                size: 24,
              ),
            ),
          ),
        ),
        title: Text(
          'Nouvelle Ordonnance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: primaryDark,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                // Image Container
                _buildImageContainer(width, height),

                SizedBox(height: 40),

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
      ),
    );
  }
}