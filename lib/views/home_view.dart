// Fichier: lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:pharmacie/views/ambulanceView.dart';
import 'package:pharmacie/views/pharmacyView.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import 'package:carousel_slider/carousel_slider.dart';


import 'hospital_view.dart';
import 'laboratoryView.dart';

// Palette de couleurs vibrante avec Teal
class AppColors {
  static const Color primary = Colors.teal;
  static const Color primaryDark = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color accent = Color(0xFF00BCD4); // Cyan
  static const Color accentLight = Color(0xFF80DEEA);
  static const Color background = Color(0xFFF0FDFF);
  static const Color cardBackground = Colors.white;
  static const Color gradient1 = Color(0xFF00BCD4);
  static const Color gradient2 = Color(0xFF4DB6AC);
  static const Color gradient3 = Color(0xFF81C784);
  static const Color shadowColor = Color(0x1A000000);
}

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const HomeViewContent(),
    );
  }
}

class HomeViewContent extends StatefulWidget {
  const HomeViewContent({Key? key}) : super(key: key);

  @override
  State<HomeViewContent> createState() => _HomeViewContentState();
}

class _HomeViewContentState extends State<HomeViewContent>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.accentLight.withOpacity(0.1),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -50 * (1 - _headerAnimation.value)),
                      child: Opacity(
                        opacity: _headerAnimation.value,
                        child: _buildHeader(context),
                      ),
                    );
                  },
                ),*/
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _cardAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _cardAnimation.value,
                            child: _buildSearchBar(context, viewModel),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildSectionTitle('🏥 Services de santé',
                          subtitle: 'Trouvez rapidement ce dont vous avez besoin'),
                      const SizedBox(height: 16),
                      _buildCategories(viewModel),
                      const SizedBox(height: 1),
                    ],
                  ),
                ),
                _buildPromoBanner(context),
                const SizedBox(height: 13),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('💊 Trouver un médicament',
                          subtitle: 'Outils pratiques pour votre santé'),
                      const SizedBox(height: 16),
                      _buildMedicationFeatures(context, viewModel),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            AppColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bonjour',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 2000),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 0.2,
                          child: const Text('👋', style: TextStyle(fontSize: 18)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Trouvez la solution de\nsanté parfaite pour vous',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {},
                child: Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, HomeViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.accentLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: viewModel.updateSearchQuery,
        style: TextStyle(
          color: AppColors.primaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: '🔍 Rechercher médecin, médicament, article...',
          hintStyle: TextStyle(
            color: AppColors.primary.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(HomeViewModel viewModel) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: viewModel.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 1),
        itemBuilder: (context, index) {
          final category = viewModel.categories[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800 + (index * 200)),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: _buildCategoryCard(category, index),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconData(String title) {
    switch (title) {
      case 'Laboratoire':
        return Icons.biotech_rounded;
      case 'Pharmacie':
        return Icons.local_pharmacy_rounded;
      case 'Ambulance':
        return Icons.emergency_rounded;
      case 'Hospital':
        return Icons.local_hospital_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  Widget _buildCategoryCard(dynamic category, int index) {
    final colors = [
      [AppColors.gradient1, AppColors.gradient2],
      [AppColors.gradient2, AppColors.gradient3],
      [AppColors.primary, AppColors.accent],
      [AppColors.accent, AppColors.primaryLight],
    ];

    return Container(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors[index % colors.length],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: colors[index % colors.length][0].withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () {
                  // Navigation basée sur le titre de la catégorie
                  switch (category.title) {
                    case 'Laboratoire':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LaboratoryView(),
                        ),
                      );
                      break;
                    case 'Pharmacie':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PharmacyView(),
                        ),
                      );
                      print('Navigation vers Pharmacie');
                      break;
                    case 'Ambulance':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AmbulanceView(),
                        ),
                      );
                      print('Navigation vers Ambulance');
                      break;
                    case 'Hospital':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HospitalView(),
                        ),
                      );
                      print('Navigation vers Hospital');
                      break;
                    default:
                      print('Catégorie non reconnue: ${category.title}');
                  }
                },
                child: Center(
                  child: _getCategoryIcon(category.title), // Changement ici : appel direct du widget
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            category.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// Version avec images PNG/JPG
  Widget _getCategoryIcon(String title) {
    switch (title) {
      case 'Laboratoire':
        return Image.asset(
          'assets/icone/microscope.png',
          width: 40,
          height: 40,
          //color: Colors.white,
          fit: BoxFit.contain,
        );
      case 'Pharmacie':
        return Image.asset(
          'assets/icone/pharmacie.png',
          width: 40,
          height: 40,
          //color: Colors.white,
          fit: BoxFit.contain,
        );
      case 'Ambulance':
        return Image.asset(
          'assets/icone/ambulance (1).png',
          width: 40,
          height: 40,
         // color: Colors.white,
          fit: BoxFit.contain,
        );
      case 'Hospital':
        return Image.asset(
          'assets/icone/medicine.png',
          width: 40,
          height: 40,
          //color: Colors.white,
          fit: BoxFit.contain,
        );
      default:
        return Image.asset(
          'assets/icons/medical_default_icon.png',
          width: 28,
          height: 28,
          color: Colors.white,
          fit: BoxFit.contain,
        );
    }
  }

// Version avec SVG (recommandée)
// import 'package:flutter_svg/flutter_svg.dart';

/*
Widget _getCategoryIcon(String title) {
  switch (title) {
    case 'Laboratoire':
      return SvgPicture.asset(
        'assets/icons/laboratory_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    case 'Pharmacie':
      return SvgPicture.asset(
        'assets/icons/pharmacy_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    case 'Ambulance':
      return SvgPicture.asset(
        'assets/icons/ambulance_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    case 'Hospital':
      return SvgPicture.asset(
        'assets/icons/hospital_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    default:
      return SvgPicture.asset(
        'assets/icons/medical_default_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
  }
}
*/

// Version avec gestion d'erreur avancée (recommandée pour la production)
  Widget _getCategoryIconWithErrorHandling(String title) {
    final iconPaths = {
      'Laboratoire': 'assets/icons/laboratory_icon.png',
      'Pharmacie': 'assets/icons/pharmacy_icon.png',
      'Ambulance': 'assets/icons/ambulance_icon.png',
      'Hospital': 'assets/icons/hospital_icon.png',
    };

    final iconPath = iconPaths[title] ?? 'assets/icons/medical_default_icon.png';

    return Image.asset(
      iconPath,
      width: 28,
      height: 28,
      color: Colors.white,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // En cas d'erreur, retourne une icône par défaut
        return Icon(
          Icons.medical_services_rounded,
          color: Colors.white,
          size: 28,
        );
      },
    );
  }


  Widget _buildPromoBanner(BuildContext context) {
    // Dimensions fixes pour tous les écrans
    final double bannerHeight = 137;
    final double bannerWidth = 330;

    final List<Map<String, dynamic>> promoData = [
      {
        'title': '🌟 Consultations\nen ligne 24h/7j',
        'subtitle': 'Connectez-vous avec nos spécialistes',
        'backgroundImage': 'assets/images/04.png',
        'emoji': '👩‍⚕️',
      },
      {
        'title': '🚀 Livraison ultra\nrapide de médicaments',
        'subtitle': 'Chez vous en moins de 2h',
        'backgroundImage': 'assets/images/02.png',
        'emoji': '🏃‍♂️',
      },
      {
        'title': '💡 Conseils personnalisés\nde nos experts',
        'subtitle': 'Obtenez des recommandations sur mesure',
        'backgroundImage': 'assets/images/01.png', // ← Correction de l'extension (était .pnp)
        'emoji': '🧠',
      },
    ];

    return Container(
      height: bannerHeight,
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          height: bannerHeight,
          enlargeCenterPage: true,
          viewportFraction: 0.85,
          autoPlayInterval: const Duration(seconds: 6),
          autoPlayAnimationDuration: const Duration(milliseconds: 1200),
          autoPlayCurve: Curves.easeInOutCubic,
        ),
        items: promoData.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> promo = entry.value;

          return Builder(
            builder: (BuildContext context) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 1000 + (index * 300)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: bannerWidth,
                      height: bannerHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Image en arrière-plan avec orientation corrigée
                            Positioned.fill(
                              child: Image.asset(
                                promo['backgroundImage'],
                                fit: BoxFit.cover,
                                // Gestion d'erreur pour les images manquantes
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.purple.shade600,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Overlay sombre pour la lisibilité
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                ),
                              ),
                            ),
                            // Effet de brilliance animé (optionnel)
                            Positioned(
                              top: -30,
                              right: -30,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(seconds: 3),
                                builder: (context, value, child) {
                                  return Transform.rotate(
                                    angle: value * 6.28,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Contenu textuel avec contraintes flexibles
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min, // Important pour éviter le débordement
                                  children: [
                                    Flexible(
                                      child: Text(
                                        promo['title']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15, // Réduit légèrement
                                          height: 1.1,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 4,
                                              offset: Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4), // Réduit l'espacement
                                    Flexible(
                                      child: Text(
                                        promo['subtitle']!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 11, // Réduit légèrement
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 2,
                                              offset: Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8), // Réduit l'espacement
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () {},
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Découvrir',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 12,
                                                  color: Colors.black87,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }


  Widget _buildMedicationFeatures(BuildContext context, HomeViewModel viewModel) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.medicationFeatures.length,
      itemBuilder: (context, index) {
        final feature = viewModel.medicationFeatures[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _buildFeatureCard(context, feature, index),
            );
          },
        );
      },
    );
  }





  Widget _buildFeatureCard(BuildContext context, dynamic feature, int index) {
    final gradients = [
      [AppColors.primary, AppColors.accent],
      [AppColors.accent, AppColors.gradient3],
      [AppColors.gradient2, AppColors.primary],
      [AppColors.gradient3, AppColors.gradient1],
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => feature.routeBuilder()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradients[index % gradients.length],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: gradients[index % gradients.length][0].withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: getFeatureIcon(index), // Changement ici : appel direct du widget
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  feature.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryDark,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Version avec images PNG/JPG
  Widget getFeatureIcon(int index) {
    switch (index) {
      case 0:
        return Image.asset(
          'assets/icone/appareil-photo-reflex-numerique.png',
          width: 40,
          height: 40,
          //color: Colors.white, // Pour garder la couleur blanche
          fit: BoxFit.contain,
        );
      case 1:
        return Image.asset(
          'assets/icone/medicament.png',
          width: 40,
          height: 40,
         // color: Colors.white,
          fit: BoxFit.contain,
        );
      case 2:
        return Image.asset(
          'assets/icone/medicament (1).png',
          width: 40,
          height: 40,
          //color: Colors.white,
          fit: BoxFit.contain,
        );
      case 3:
        return Image.asset(
          'assets/icone/question.png',
          width: 40,
          height: 40,
          //color: Colors.white,
          fit: BoxFit.contain,
        );
      default:
        return Image.asset(
          'assets/icone/medical_icon.png',
          width: 28,
          height: 28,
          //color: Colors.white,
          fit: BoxFit.contain,
        );
    }
  }

// Alternative avec SVG (plus recommandée pour la qualité)
// Ajoutez d'abord flutter_svg: ^2.0.9 dans pubspec.yaml
// import 'package:flutter_svg/flutter_svg.dart';

/*
Widget getFeatureIcon(int index) {
  switch (index) {
    case 0:
      return SvgPicture.asset(
        'assets/icons/camera_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    case 1:
      return SvgPicture.asset(
        'assets/icons/medication_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    case 2:
      return SvgPicture.asset(
        'assets/icons/history_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    case 3:
      return SvgPicture.asset(
        'assets/icons/compare_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
    default:
      return SvgPicture.asset(
        'assets/icons/medical_icon.svg',
        width: 28,
        height: 28,
        color: Colors.white,
      );
  }
}
*/

// Version avec gestion d'erreur (recommandée)
  Widget getFeatureIconWithErrorHandling(int index) {
    final iconPaths = {
      0: 'assets/icone/appareil-photo-reflex-numerique.png',
      1: 'assets/icone/medication_icon.png',
      2: 'assets/icone/history_icon.png',
      3: 'assets/icone/compare_icon.png',
    };

    final iconPath = iconPaths[index] ?? 'assets/icone/medical_icon.png';

    return Image.asset(
      iconPath,
      width: 28,
      height: 28,
      color: Colors.white,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // En cas d'erreur, retourne une icône par défaut
        return Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 28,
        );
      },
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
            AppColors.accentLight.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 0, true),
              _buildNavItem(Icons.chat_bubble_rounded, 1, false),
              _buildNavItem(Icons.calendar_today_rounded, 2, false),
              _buildNavItem(Icons.person_rounded, 3, false),
            ],
          ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.accent.withOpacity(0.1),
                ],
              )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              )
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}