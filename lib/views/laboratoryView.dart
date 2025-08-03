// Fichier: lib/views/laboratory_view.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Réutilisation de la palette de couleurs
class AppColors {
  static const Color primary = Colors.teal;
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
}

class Laboratory {
  final String name;
  final String address;
  final double distance;
  final String phone;
  final List<String> openHours;
  final bool isOpen;
  final double rating;
  final List<String> services;

  Laboratory({
    required this.name,
    required this.address,
    required this.distance,
    required this.phone,
    required this.openHours,
    required this.isOpen,
    required this.rating,
    required this.services,
  });
}

class MedicalExam {
  final String name;
  final String category;
  final double price;
  final String duration;
  final bool fastingRequired;
  final List<String> availableInLabs;

  MedicalExam({
    required this.name,
    required this.category,
    required this.price,
    required this.duration,
    required this.fastingRequired,
    required this.availableInLabs,
  });
}

class LaboratoryView extends StatefulWidget {
  const LaboratoryView({Key? key}) : super(key: key);

  @override
  State<LaboratoryView> createState() => _LaboratoryViewState();
}

class _LaboratoryViewState extends State<LaboratoryView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  List<Laboratory> _nearbyLabs = [];
  List<MedicalExam> _availableExams = [];
  List<MedicalExam> _selectedExams = [];
  List<MedicalExam> _searchResults = [];
  bool _isLoadingLocation = false;
  String _currentLocation = "Ouagadougou, Centre";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _loadMockData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Données mock pour les laboratoires
    _nearbyLabs = [
      Laboratory(
        name: "Laboratoire Central",
        address: "Avenue Kwame Nkrumah, Ouagadougou",
        distance: 0.8,
        phone: "+226 25 30 60 70",
        openHours: ["Lun-Ven: 7h-18h", "Sam: 8h-12h"],
        isOpen: true,
        rating: 4.5,
        services: ["Analyses médicales", "Imagerie", "Tests COVID"],
      ),
      Laboratory(
        name: "Bio-Lab Express",
        address: "Secteur 4, Ouagadougou",
        distance: 1.2,
        phone: "+226 25 31 45 89",
        openHours: ["Lun-Sam: 6h30-19h"],
        isOpen: true,
        rating: 4.2,
        services: ["Analyses sanguines", "Biochimie", "Hématologie"],
      ),
      Laboratory(
        name: "Centre d'Analyses Médicales",
        address: "Zone du Bois, Ouagadougou",
        distance: 2.1,
        phone: "+226 25 36 78 92",
        openHours: ["Lun-Ven: 7h30-17h30"],
        isOpen: false,
        rating: 4.0,
        services: ["Analyses complètes", "Microbiologie", "Parasitologie"],
      ),
    ];

    // Données mock pour les examens
    _availableExams = [
      MedicalExam(
        name: "Numération Formule Sanguine (NFS)",
        category: "Hématologie",
        price: 5000,
        duration: "2h",
        fastingRequired: false,
        availableInLabs: ["Laboratoire Central", "Bio-Lab Express"],
      ),
      MedicalExam(
        name: "Glycémie à jeun",
        category: "Biochimie",
        price: 2500,
        duration: "1h",
        fastingRequired: true,
        availableInLabs: ["Laboratoire Central", "Bio-Lab Express", "Centre d'Analyses Médicales"],
      ),
      MedicalExam(
        name: "Test COVID-19 (PCR)",
        category: "Virologie",
        price: 15000,
        duration: "24h",
        fastingRequired: false,
        availableInLabs: ["Laboratoire Central"],
      ),
      MedicalExam(
        name: "Cholestérol total",
        category: "Biochimie",
        price: 3500,
        duration: "2h",
        fastingRequired: true,
        availableInLabs: ["Bio-Lab Express", "Centre d'Analyses Médicales"],
      ),
    ];
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Simulation de récupération de localisation
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _currentLocation = "Ouagadougou, Secteur 12";
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _searchExams(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _availableExams
          .where((exam) =>
      exam.name.toLowerCase().contains(query.toLowerCase()) ||
          exam.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addExamToSelection(MedicalExam exam) {
    if (!_selectedExams.contains(exam)) {
      setState(() {
        _selectedExams.add(exam);
      });
    }
  }

  void _removeExamFromSelection(MedicalExam exam) {
    setState(() {
      _selectedExams.remove(exam);
    });
  }

  double _getTotalPrice() {
    return _selectedExams.fold(0.0, (sum, exam) => sum + exam.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildLocationHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNearbyLabsTab(),
                  _buildExamsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        'Laboratoires',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.filter_list_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre position',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _isLoadingLocation
                    ? Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Localisation...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                    : Text(
                  _currentLocation,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _getCurrentLocation,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 18),
                const SizedBox(width: 8),
                Text('À proximité'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, size: 18),
                const SizedBox(width: 8),
                Text('Examens'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyLabsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Laboratoires ouverts (${_nearbyLabs.where((lab) => lab.isOpen).length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _nearbyLabs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lab = _nearbyLabs[index];
                return _buildLabCard(lab, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabCard(Laboratory lab, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 200)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: lab.isOpen
                  ? Border.all(color: AppColors.accent.withOpacity(0.3), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lab.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lab.address,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lab.isOpen
                              ? AppColors.accent.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lab.isOpen ? 'Ouvert' : 'Fermé',
                          style: TextStyle(
                            color: lab.isOpen ? AppColors.accent : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${lab.distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        lab.rating.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: lab.services.map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service,
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: lab.isOpen ? () {} : null,
                          icon: Icon(Icons.phone_rounded, size: 18),
                          label: Text('Appeler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.directions_rounded, size: 18),
                          label: Text('Itinéraire'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }

  Widget _buildExamsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildExamSearchBar(),
          const SizedBox(height: 16),
          if (_selectedExams.isNotEmpty) ...[
            _buildSelectedExams(),
            const SizedBox(height: 16),
          ],
          Text(
            _searchController.text.isEmpty
                ? 'Examens disponibles'
                : 'Résultats de recherche',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _searchController.text.isEmpty
                  ? _availableExams.length
                  : _searchResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final exam = _searchController.text.isEmpty
                    ? _availableExams[index]
                    : _searchResults[index];
                return _buildExamCard(exam, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchExams,
        decoration: InputDecoration(
          hintText: '🔍 Rechercher un examen...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded, color: Colors.grey[500]),
            onPressed: () {
              _searchController.clear();
              _searchExams('');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedExams() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Examens sélectionnés (${_selectedExams.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Spacer(),
              Text(
                '${_getTotalPrice().toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedExams.map((exam) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exam.name,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeExamFromSelection(exam),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Action pour vérifier la disponibilité
                _showAvailabilityDialog();
              },
              icon: Icon(Icons.search_rounded, size: 18),
              label: Text('Vérifier la disponibilité'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(MedicalExam exam, int index) {
    final isSelected = _selectedExams.contains(exam);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.accent, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (isSelected) {
                    _removeExamFromSelection(exam);
                  } else {
                    _addExamToSelection(exam);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exam.category,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isSelected
                                ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(
                            '${exam.price.toStringAsFixed(0)} FCFA',
                            Icons.monetization_on_rounded,
                            AppColors.accent,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            exam.duration,
                            Icons.access_time_rounded,
                            AppColors.primary,
                          ),
                          if (exam.fastingRequired) ...[
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              'À jeun',
                              Icons.no_food_rounded,
                              Colors.orange,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Disponible dans: ${exam.availableInLabs.join(", ")}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

    Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(
    text,
    style: TextStyle(
    color: color,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    ),
    ),
    ],
    ),
    );
    }

    void _showAvailabilityDialog() {
    if (_selectedExams.isEmpty) return;

    // Filtrer les laboratoires qui offrent tous les examens sélectionnés
    List<Laboratory> availableLabs = _nearbyLabs.where((lab) {
    return _selectedExams.every((exam) => exam.availableInLabs.contains(lab.name));
    }).toList();

    showDialog(
    context: context,
    builder: (BuildContext context) {
    return Dialog(
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
    AppColors.background,
    Colors.white,
    ],
    ),
    ),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: AppColors.accent.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
    Icons.medical_services_rounded,
    color: AppColors.accent,
    size: 24,
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Text(
    'Disponibilité des examens',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
    ),
    ),
    ),
    IconButton(
    onPressed: () => Navigator.pop(context),
    icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
    ),
    ],
    ),
    const SizedBox(height: 20),

    // Résumé des examens sélectionnés
    Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: AppColors.primaryLight.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Examens sélectionnés (${_selectedExams.length})',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
    ),
    ),
    const SizedBox(height: 8),
    ..._selectedExams.map((exam) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
    children: [
    Icon(Icons.check_circle_rounded,
    color: AppColors.accent, size: 16),
    const SizedBox(width: 8),
    Expanded(
    child: Text(
    exam.name,
    style: TextStyle(color: AppColors.primaryDark),
    ),
    ),
    Text(
    '${exam.price.toStringAsFixed(0)} FCFA',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    ),
    ),
    ],
    ),
    )).toList(),
    const Divider(),
    Row(
    children: [
    Text(
    'Total: ',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.primaryDark,
    ),
    ),
    Text(
    '${_getTotalPrice().toStringAsFixed(0)} FCFA',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: AppColors.accent,
    ),
    ),
    ],
    ),
    ],
    ),
    ),

    const SizedBox(height: 20),

    // Laboratoires disponibles
    Text(
    availableLabs.isNotEmpty
    ? 'Laboratoires disponibles (${availableLabs.length})'
        : 'Aucun laboratoire disponible',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
    ),
    ),

    const SizedBox(height: 12),

    if (availableLabs.isEmpty)
    Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.orange.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.orange.withOpacity(0.3)),
    ),
    child: Row(
    children: [
    Icon(Icons.warning_rounded, color: Colors.orange),
    const SizedBox(width: 12),
    Expanded(
    child: Text(
    'Aucun laboratoire ne propose tous ces examens. Veuillez contacter les laboratoires individuellement.',
    style: TextStyle(color: Colors.orange[800]),
    ),
    ),
    ],
    ),
    )
    else
    SizedBox(
    height: 200,
    child: ListView.separated(
    itemCount: availableLabs.length,
    separatorBuilder: (context, index) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
    final lab = availableLabs[index];
    return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
    color: lab.isOpen
    ? AppColors.accent.withOpacity(0.3)
        : Colors.grey.withOpacity(0.3),
    ),
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Expanded(
    child: Text(
    lab.name,
    style: TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
    ),
    ),
    ),
    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: lab.isOpen
    ? AppColors.accent.withOpacity(0.1)
        : Colors.red.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
    lab.isOpen ? 'Ouvert' : 'Fermé',
    style: TextStyle(
    color: lab.isOpen ? AppColors.accent : Colors.red,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 4),
    Row(
    children: [
    Icon(Icons.location_on_rounded,
    color: AppColors.primary, size: 14),
    const SizedBox(width: 4),
    Text(
    '${lab.distance.toStringAsFixed(1)} km',
    style: TextStyle(
    color: AppColors.primary,
    fontSize: 12,
    ),
    ),
    const SizedBox(width: 12),
    Icon(Icons.star_rounded, color: Colors.amber, size: 14),
    const SizedBox(width: 4),
    Text(
    lab.rating.toString(),
    style: TextStyle(
    color: Colors.grey[600],
    fontSize: 12,
    ),
    ),
    ],
    ),
    ],
    ),
    );
    },
    ),
    ),

    const SizedBox(height: 20),

    // Boutons d'action
    Row(
    children: [
    if (availableLabs.isNotEmpty) ...[
    Expanded(
    child: OutlinedButton.icon(
    onPressed: () {
    Navigator.pop(context);
    // Action pour voir plus de détails
    },
    icon: Icon(Icons.info_outline_rounded, size: 18),
    label: Text('Détails'),
    style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: BorderSide(color: AppColors.primary),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    ),
    ),
    const SizedBox(width: 12),
    ],
    Expanded(
    child: ElevatedButton.icon(
    onPressed: () {
    Navigator.pop(context);
    _showBookingDialog(availableLabs);
    },
    icon: Icon(Icons.calendar_today_rounded, size: 18),
    label: Text(availableLabs.isNotEmpty ? 'Réserver' : 'Fermer'),
    style: ElevatedButton.styleFrom(
    backgroundColor: availableLabs.isNotEmpty
    ? AppColors.accent
        : Colors.grey,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    );
    },
    );
    }

    void _showBookingDialog(List<Laboratory> availableLabs) {
    if (availableLabs.isEmpty) return;

    showDialog(
    context: context,
    builder: (BuildContext context) {
    return Dialog(
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
    AppColors.background,
    Colors.white,
    ],
    ),
    ),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Row(
    children: [
    Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: AppColors.accent.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
    Icons.calendar_today_rounded,
    color: AppColors.accent,
    size: 24,
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Text(
    'Réservation',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
    ),
    ),
    ),
    IconButton(
    onPressed: () => Navigator.pop(context),
    icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
    ),
    ],
    ),

    const SizedBox(height: 20),

    Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: AppColors.accent.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
    children: [
    Icon(Icons.info_outline_rounded, color: AppColors.accent),
    const SizedBox(width: 12),
    Expanded(
    child: Text(
    'Fonctionnalité de réservation en cours de développement. Veuillez contacter directement le laboratoire.',
    style: TextStyle(
    color: AppColors.primaryDark,
    ),
    ),
    ),
    ],
    ),
    ),

    const SizedBox(height: 20),

    SizedBox(
    width: double.infinity,
    child: ElevatedButton(
    onPressed: () => Navigator.pop(context),
    child: Text('Compris'),
    style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(vertical: 16),
    ),
    ),
    ),
    ],
    ),
    ),
    );
    },
    );
    }
    }