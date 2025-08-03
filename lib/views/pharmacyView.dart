// Fichier: lib/views/pharmacy_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Modèle de données pour une pharmacie
class Pharmacy {
  final String id;
  final String name;
  final String phone;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> openDays;
  final String openHours;
  final double distance;
  final bool isGuard;
  final String guardDay;

  Pharmacy({
    required this.id,
    required this.name,
    required this.phone,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openDays,
    required this.openHours,
    required this.distance,
    required this.isGuard,
    required this.guardDay,
  });
}

// Palette de couleurs (réutilisation du style existant)
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

class PharmacyView extends StatefulWidget {
  const PharmacyView({Key? key}) : super(key: key);

  @override
  State<PharmacyView> createState() => _PharmacyViewState();
}

class _PharmacyViewState extends State<PharmacyView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String selectedCity = 'Ma position';
  String selectedDay = 'Aujourd\'hui';
  bool isLocationEnabled = false;
  bool isLoading = false;
  String searchQuery = '';

  final List<String> cities = [
    'Ma position',
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Koudougou',
    'Banfora',
    'Ouahigouya',
  ];

  final List<String> days = [
    'Aujourd\'hui',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  // Données simulées des pharmacies
  List<Pharmacy> allPharmacies = [
    Pharmacy(
      id: '1',
      name: 'Pharmacie du Centre',
      phone: '+226 25 30 65 78',
      description: 'Pharmacie moderne avec service 24h/24. Spécialisée en médicaments génériques et produits de parapharmacie.',
      address: 'Avenue Kwame Nkrumah, Ouagadougou',
      latitude: 12.3714,
      longitude: -1.5197,
      openDays: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'],
      openHours: '7h00 - 22h00',
      distance: 0.8,
      isGuard: true,
      guardDay: 'Dimanche',
    ),
    Pharmacy(
      id: '2',
      name: 'Pharmacie Nouvelle',
      phone: '+226 25 31 42 89',
      description: 'Pharmacie de quartier avec conseil personnalisé. Large gamme de produits cosmétiques et d\'hygiène.',
      address: 'Secteur 12, Rue de la Paix, Ouagadougou',
      latitude: 12.3678,
      longitude: -1.5245,
      openDays: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
      openHours: '8h00 - 20h00',
      distance: 1.2,
      isGuard: false,
      guardDay: 'Lundi',
    ),
    Pharmacy(
      id: '3',
      name: 'Pharmacie de la Santé',
      phone: '+226 25 32 15 67',
      description: 'Pharmacie spécialisée en médicaments pédiatriques et matériel médical. Service de livraison disponible.',
      address: 'Zone du Bois, Ouagadougou',
      latitude: 12.3798,
      longitude: -1.5089,
      openDays: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'],
      openHours: '7h30 - 19h30',
      distance: 2.1,
      isGuard: true,
      guardDay: 'Samedi',
    ),
    Pharmacy(
      id: '4',
      name: 'Pharmacie Espoir',
      phone: '+226 25 33 78 90',
      description: 'Pharmacie communautaire avec prix abordables. Accepte les mutuelles de santé.',
      address: 'Secteur 30, Ouagadougou',
      latitude: 12.3456,
      longitude: -1.5321,
      openDays: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'],
      openHours: '8h00 - 18h00',
      distance: 3.5,
      isGuard: false,
      guardDay: 'Mardi',
    ),
    Pharmacy(
      id: '5',
      name: 'Pharmacie Moderne',
      phone: '+226 25 34 56 21',
      description: 'Pharmacie équipée des dernières technologies. Service de téléconseil disponible.',
      address: 'Avenue Charles de Gaulle, Ouagadougou',
      latitude: 12.3589,
      longitude: -1.5412,
      openDays: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
      openHours: '6h00 - 23h00',
      distance: 4.2,
      isGuard: true,
      guardDay: 'Mercredi',
    ),
  ];

  List<Pharmacy> filteredPharmacies = [];

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
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    filteredPharmacies = allPharmacies;
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _requestLocationPermission() async {
    setState(() {
      isLoading = true;
    });

    // Simulation de la demande de permission de géolocalisation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLocationEnabled = true;
      isLoading = false;
    });
  }

  void _filterPharmacies() {
    setState(() {
      filteredPharmacies = allPharmacies.where((pharmacy) {
        bool matchesSearch = pharmacy.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            pharmacy.address.toLowerCase().contains(searchQuery.toLowerCase());

        bool matchesDay = selectedDay == 'Aujourd\'hui' ||
            pharmacy.openDays.contains(selectedDay) ||
            (pharmacy.isGuard && pharmacy.guardDay == selectedDay);

        return matchesSearch && matchesDay;
      }).toList();

      // Trier par distance
      filteredPharmacies.sort((a, b) => a.distance.compareTo(b.distance));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilters(),
                  Expanded(
                    child: _buildPharmaciesList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏥 Pharmacies',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filteredPharmacies.length} pharmacies trouvées',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.map, color: Colors.white),
                  onPressed: () {
                    _showMapView();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
          _filterPharmacies();
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une pharmacie...',
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              'Ville',
              selectedCity,
              cities,
                  (value) {
                setState(() {
                  selectedCity = value!;
                });
                _filterPharmacies();
              },
              Icons.location_on,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              'Jour',
              selectedDay,
              days,
                  (value) {
                setState(() {
                  selectedDay = value!;
                });
                _filterPharmacies();
              },
              Icons.calendar_today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      String value,
      List<String> items,
      void Function(String?) onChanged,
      IconData icon,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }

  Widget _buildPharmaciesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredPharmacies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_pharmacy_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune pharmacie trouvée',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredPharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = filteredPharmacies[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildPharmacyCard(pharmacy, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPharmacyCard(Pharmacy pharmacy, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showPharmacyDetails(pharmacy),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pharmacy.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              if (pharmacy.isGuard) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'Garde',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pharmacy.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${pharmacy.distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pharmacy.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy.openHours,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildActionButton(
                          Icons.phone,
                          Colors.green,
                              () => _callPharmacy(pharmacy.phone),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          Icons.directions,
                          AppColors.primary,
                              () => _getDirections(pharmacy),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showPharmacyDetails(Pharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${pharmacy.distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 14,
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
                  _buildDetailSection('📍 Adresse', pharmacy.address),
                  _buildDetailSection('📱 Téléphone', pharmacy.phone),
                  _buildDetailSection('🕒 Horaires', pharmacy.openHours),
                  _buildDetailSection('📝 Description', pharmacy.description),
                  if (pharmacy.isGuard) ...[
                    _buildDetailSection('🛡️ Pharmacie de garde', 'Disponible le ${pharmacy.guardDay}'),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callPharmacy(pharmacy.phone),
                          icon: const Icon(Icons.phone),
                          label: const Text('Appeler'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _getDirections(pharmacy),
                          icon: const Icon(Icons.directions),
                          label: const Text('Itinéraire'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callPharmacy(String phone) {
    // Simulation d'un appel téléphonique
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appel vers $phone'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _getDirections(Pharmacy pharmacy) {
    // Simulation de l'ouverture de l'application de navigation
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de l\'itinéraire vers ${pharmacy.name}'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMapView() {
    // Simulation de l'affichage de la vue carte
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vue Carte'),
        content: const Text('La vue carte sera disponible prochainement avec l\'intégration de Google Maps ou OpenStreetMap.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}