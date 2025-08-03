// Fichier: lib/views/hospital_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Modèle de données pour les établissements de santé
class HealthFacility {
  final String id;
  final String name;
  final HealthFacilityType type;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String phone;
  final String? email;
  final List<String> specialties;
  final String workingHours;
  final int capacity;
  final double rating;
  final String description;
  final bool isEmergencyAvailable;
  final bool hasParking;
  final bool isAccessible;

  HealthFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.email,
    required this.specialties,
    required this.workingHours,
    required this.capacity,
    required this.rating,
    required this.description,
    required this.isEmergencyAvailable,
    required this.hasParking,
    required this.isAccessible,
  });
}

enum HealthFacilityType {
  publicHospital,
  privateClinic,
  cma,
  dispensary,
}

extension HealthFacilityTypeExtension on HealthFacilityType {
  String get displayName {
    switch (this) {
      case HealthFacilityType.publicHospital:
        return 'Hôpital Public';
      case HealthFacilityType.privateClinic:
        return 'Clinique Privée';
      case HealthFacilityType.cma:
        return 'CMA';
      case HealthFacilityType.dispensary:
        return 'Dispensaire';
    }
  }

  Color get color {
    switch (this) {
      case HealthFacilityType.publicHospital:
        return Colors.blue;
      case HealthFacilityType.privateClinic:
        return Colors.green;
      case HealthFacilityType.cma:
        return Colors.orange;
      case HealthFacilityType.dispensary:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case HealthFacilityType.publicHospital:
        return Icons.local_hospital;
      case HealthFacilityType.privateClinic:
        return Icons.medical_services;
      case HealthFacilityType.cma:
        return Icons.healing;
      case HealthFacilityType.dispensary:
        return Icons.medication;
    }
  }
}

class HospitalView extends StatefulWidget {
  const HospitalView({Key? key}) : super(key: key);

  @override
  State<HospitalView> createState() => _HospitalViewState();
}

class _HospitalViewState extends State<HospitalView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // État de la page
  bool _isMapView = false;
  String _searchQuery = '';
  String _selectedCity = 'Toutes les villes';
  HealthFacilityType? _selectedType;
  bool _sortByDistance = false;

  // Contrôleurs
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Données d'exemple
  final List<String> _cities = [
    'Toutes les villes',
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Koudougou',
    'Banfora',
    'Ouahigouya',
    'Kaya',
    'Tenkodogo',
    'Fada N\'Gourma',
    'Gaoua',
    'Dori'
  ];

  final List<HealthFacility> _healthFacilities = [
    HealthFacility(
      id: '1',
      name: 'Centre Hospitalier Universitaire Yalgado Ouédraogo',
      type: HealthFacilityType.publicHospital,
      address: '03 BP 7022 Ouagadougou 03',
      city: 'Ouagadougou',
      latitude: 12.3714,
      longitude: -1.5197,
      phone: '+226 25 30 67 00',
      email: 'chu-yo@chu-yo.bf',
      specialties: ['Chirurgie', 'Cardiologie', 'Neurologie', 'Pédiatrie', 'Gynécologie'],
      workingHours: '24h/24 - 7j/7',
      capacity: 600,
      rating: 4.2,
      description: 'Principal hôpital de référence du Burkina Faso, offrant des soins spécialisés de haute qualité.',
      isEmergencyAvailable: true,
      hasParking: true,
      isAccessible: true,
    ),
    HealthFacility(
      id: '2',
      name: 'Clinique Princesse Sarah',
      type: HealthFacilityType.privateClinic,
      address: 'Secteur 4, Avenue Kwame Nkrumah',
      city: 'Ouagadougou',
      latitude: 12.3656,
      longitude: -1.5339,
      phone: '+226 25 31 29 29',
      email: 'contact@clinique-sarah.bf',
      specialties: ['Médecine générale', 'Chirurgie', 'Maternité', 'Radiologie'],
      workingHours: '7h00 - 22h00',
      capacity: 120,
      rating: 4.5,
      description: 'Clinique privée moderne offrant des soins de qualité avec équipements de pointe.',
      isEmergencyAvailable: true,
      hasParking: true,
      isAccessible: true,
    ),
    HealthFacility(
      id: '3',
      name: 'CMA du Secteur 30',
      type: HealthFacilityType.cma,
      address: 'Secteur 30, Ouagadougou',
      city: 'Ouagadougou',
      latitude: 12.3484,
      longitude: -1.4854,
      phone: '+226 25 36 12 34',
      specialties: ['Médecine générale', 'Chirurgie mineure', 'Maternité', 'Pédiatrie'],
      workingHours: '6h30 - 17h30',
      capacity: 80,
      rating: 3.8,
      description: 'Centre médical avec antenne chirurgicale desservant la zone est de Ouagadougou.',
      isEmergencyAvailable: false,
      hasParking: false,
      isAccessible: false,
    ),
    HealthFacility(
      id: '4',
      name: 'Centre Hospitalier Régional de Bobo-Dioulasso',
      type: HealthFacilityType.publicHospital,
      address: '01 BP 676 Bobo-Dioulasso 01',
      city: 'Bobo-Dioulasso',
      latitude: 11.1770,
      longitude: -4.2970,
      phone: '+226 20 97 00 92',
      email: 'chr-bobo@chr-bobo.bf',
      specialties: ['Médecine interne', 'Chirurgie', 'Gynécologie', 'Pédiatrie', 'Ophtalmologie'],
      workingHours: '24h/24 - 7j/7',
      capacity: 400,
      rating: 4.0,
      description: 'Hôpital de référence régional pour l\'ouest du Burkina Faso.',
      isEmergencyAvailable: true,
      hasParking: true,
      isAccessible: true,
    ),
    HealthFacility(
      id: '5',
      name: 'Dispensaire de Tampouy',
      type: HealthFacilityType.dispensary,
      address: 'Secteur 25, Tampouy',
      city: 'Ouagadougou',
      latitude: 12.4020,
      longitude: -1.4751,
      phone: '+226 25 34 56 78',
      specialties: ['Médecine générale', 'Vaccination', 'Consultations prénatales'],
      workingHours: '7h00 - 17h00',
      capacity: 30,
      rating: 3.5,
      description: 'Dispensaire de quartier offrant des soins de santé primaires.',
      isEmergencyAvailable: false,
      hasParking: false,
      isAccessible: false,
    ),
    HealthFacility(
      id: '6',
      name: 'Clinique Notre Dame de la Paix',
      type: HealthFacilityType.privateClinic,
      address: 'Avenue de la Paix, Secteur 7',
      city: 'Bobo-Dioulasso',
      latitude: 11.1813,
      longitude: -4.2918,
      phone: '+226 20 98 15 25',
      email: 'clinique-paix@gmail.com',
      specialties: ['Médecine générale', 'Cardiologie', 'Dermatologie', 'Laboratoire'],
      workingHours: '8h00 - 20h00',
      capacity: 60,
      rating: 4.3,
      description: 'Clinique privée réputée pour la qualité de ses soins et son accueil.',
      isEmergencyAvailable: false,
      hasParking: true,
      isAccessible: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<HealthFacility> get _filteredFacilities {
    List<HealthFacility> filtered = _healthFacilities.where((facility) {
      bool matchesSearch = facility.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          facility.specialties.any((specialty) => specialty.toLowerCase().contains(_searchQuery.toLowerCase()));
      bool matchesCity = _selectedCity == 'Toutes les villes' || facility.city == _selectedCity;
      bool matchesType = _selectedType == null || facility.type == _selectedType;

      return matchesSearch && matchesCity && matchesType;
    }).toList();

    if (_sortByDistance) {
      // Simulation de tri par distance (ici par rating pour l'exemple)
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSearchAndFilters(),
                  _buildViewToggle(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _isMapView ? _buildMapView() : _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.teal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Structures de Santé',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal,
                Color(0xFF4DB6AC),
                Color(0xFF00BCD4),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: Icon(
                  Icons.local_hospital,
                  color: Colors.white.withOpacity(0.3),
                  size: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un établissement, spécialité...',
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filtre par ville
                _buildFilterChip(
                  label: _selectedCity,
                  icon: Icons.location_city,
                  onTap: () => _showCityPicker(),
                ),
                const SizedBox(width: 8),

                // Filtre par type
                _buildFilterChip(
                  label: _selectedType?.displayName ?? 'Tous types',
                  icon: Icons.category,
                  onTap: () => _showTypePicker(),
                ),
                const SizedBox(width: 8),

                // Tri par distance
                _buildFilterChip(
                  label: 'Distance',
                  icon: Icons.near_me,
                  isSelected: _sortByDistance,
                  onTap: () {
                    setState(() {
                      _sortByDistance = !_sortByDistance;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.teal,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.teal,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isMapView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isMapView ? Colors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      color: !_isMapView ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Liste',
                      style: TextStyle(
                        color: !_isMapView ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isMapView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isMapView ? Colors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      color: _isMapView ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Carte',
                      style: TextStyle(
                        color: _isMapView ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final filteredFacilities = _filteredFacilities;

    if (filteredFacilities.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun établissement trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final facility = filteredFacilities[index];
          return _buildFacilityCard(facility, index);
        },
        childCount: filteredFacilities.length,
      ),
    );
  }

  Widget _buildFacilityCard(HealthFacility facility, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showFacilityDetails(facility),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec nom et type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: facility.type.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              facility.type.icon,
                              color: facility.type.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facility.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: facility.type.color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    facility.type.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Note
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  facility.rating.toString(),
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Adresse et ville
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${facility.address}, ${facility.city}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Horaires
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            facility.workingHours,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Spécialités
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: facility.specialties.take(3).map((specialty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.teal.shade200,
                              ),
                            ),
                            child: Text(
                              specialty,
                              style: TextStyle(
                                color: Colors.teal.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (facility.specialties.length > 3) ...[
                        const SizedBox(height: 6),
                        Text(
                          '+${facility.specialties.length - 3} autres spécialités',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Services disponibles
                      Row(
                        children: [
                          if (facility.isEmergencyAvailable)
                            _buildServiceBadge(Icons.emergency, 'Urgences', Colors.red),
                          if (facility.hasParking)
                            _buildServiceBadge(Icons.local_parking, 'Parking', Colors.blue),
                          if (facility.isAccessible)
                            _buildServiceBadge(Icons.accessible, 'Accessible', Colors.green),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callFacility(facility.phone),
                              icon: Icon(Icons.phone, size: 18),
                              label: Text('Appeler'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: BorderSide(color: Colors.teal),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showDirections(facility),
                              icon: Icon(Icons.directions, size: 18),
                              label: Text('Itinéraire'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildServiceBadge(IconData icon, String label, Color color) {
    return Container(
        margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(icon, color: color, size: 14),
    const SizedBox(width: 4),
    Text(
    label,
    style: TextStyle(
    color: color,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    ),),
    ],
    ),
    );
  }

  Widget _buildMapView() {
    return SliverFillRemaining(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Simulation de carte
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vue Carte',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Intégration carte en cours...',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Boutons de contrôle
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "zoom_in",
                      onPressed: () {},
                      backgroundColor: Colors.white,
                      child: Icon(Icons.add, color: Colors.teal),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "zoom_out",
                      onPressed: () {},
                      backgroundColor: Colors.white,
                      child: Icon(Icons.remove, color: Colors.teal),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "my_location",
                      onPressed: () => _getCurrentLocation(),
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.my_location, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisir une ville',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final isSelected = city == _selectedCity;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: Colors.teal,
                      ),
                      title: Text(city),
                      onTap: () {
                        setState(() {
                          _selectedCity = city;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type d\'établissement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  _selectedType == null ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: Colors.teal,
                ),
                title: const Text('Tous types'),
                onTap: () {
                  setState(() {
                    _selectedType = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ...HealthFacilityType.values.map((type) {
                final isSelected = type == _selectedType;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: Colors.teal,
                  ),
                  title: Row(
                    children: [
                      Icon(type.icon, color: type.color, size: 20),
                      const SizedBox(width: 12),
                      Text(type.displayName),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showFacilityDetails(HealthFacility facility) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // En-tête
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: facility.type.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                facility.type.icon,
                                color: facility.type.color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    facility.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: facility.type.color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      facility.type.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.orange, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${facility.rating}/5',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${facility.capacity} lits',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
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

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          facility.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Informations de contact
                        const Text(
                          'Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on, '${facility.address}, ${facility.city}'),
                        _buildInfoRow(Icons.phone, facility.phone),
                        if (facility.email != null)
                          _buildInfoRow(Icons.email, facility.email!),
                        _buildInfoRow(Icons.access_time, facility.workingHours),
                        const SizedBox(height: 24),

                        // Spécialités
                        const Text(
                          'Spécialités',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: facility.specialties.map((specialty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.teal.shade200,
                                ),
                              ),
                              child: Text(
                                specialty,
                                style: TextStyle(
                                  color: Colors.teal.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Services
                        const Text(
                          'Services disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (facility.isEmergencyAvailable)
                              _buildServiceBadge(Icons.emergency, 'Urgences', Colors.red),
                            if (facility.hasParking)
                              _buildServiceBadge(Icons.local_parking, 'Parking', Colors.blue),
                            if (facility.isAccessible)
                              _buildServiceBadge(Icons.accessible, 'Accessible', Colors.green),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _callFacility(facility.phone),
                                icon: Icon(Icons.phone),
                                label: Text('Appeler'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal,
                                  side: BorderSide(color: Colors.teal),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showDirections(facility),
                                icon: Icon(Icons.directions),
                                label: Text('Itinéraire'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callFacility(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Copier le numéro dans le presse-papiers
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Numéro copié: $phoneNumber'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'appeler: $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDirections(HealthFacility facility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Itinéraire'),
        content: Text('Ouvrir l\'itinéraire vers ${facility.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openDirections(facility);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  void _openDirections(HealthFacility facility) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${facility.latitude},${facility.longitude}';

    try {
      final Uri uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'itinéraire'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ouverture de l\'itinéraire'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _getCurrentLocation() {
    // Simulation de géolocalisation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Géolocalisation en cours...'),
        backgroundColor: Colors.teal,
      ),
    );
  }
}