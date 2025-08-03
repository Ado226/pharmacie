// Fichier: lib/views/ambulance_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Palette de couleurs pour l'ambulance

class AmbulanceColors {
  static const Color primary = Colors.teal;
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00695C);
  static const Color accent = Color(0xFF00BCD4); // Cyan
  static const Color accentLight = Color(0xFF80DEEA);
  static const Color background = Color(0xFFF0FDFF);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFD69E2E);
  static const Color shadowColor = Color(0x1A000000);
}

class AmbulanceView extends StatefulWidget {
  const AmbulanceView({Key? key}) : super(key: key);

  @override
  State<AmbulanceView> createState() => _AmbulanceViewState();
}

class _AmbulanceViewState extends State<AmbulanceView>
    with TickerProviderStateMixin {
  int currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 1. PageController initialisé correctement
  late PageController _pageController;

  // 2. Variable d'état pour le loading
  bool isLoading = false;

  // 3. Variable pour la méthode de paiement sélectionnée
  String selectedPaymentMethod = '';

  // Controllers pour les formulaires
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Variables d'état
  String selectedAmbulanceType = '';
  String selectedUrgency = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool useCurrentLocation = false;
  double estimatedCost = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialisation du PageController
    _pageController = PageController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose(); // Dispose du PageController
    _pickupController.dispose();
    _destinationController.dispose();
    _patientNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmbulanceColors.background,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController, // Utilisation du controller
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildAmbulanceTypeStep(),
                  _buildLocationStep(),
                  _buildUrgencyStep(),
                  _buildPatientInfoStep(),
                  _buildSummaryAndPaymentStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AmbulanceColors.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: AmbulanceColors.primary,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Demande d\'Ambulance',
        style: TextStyle(
          color: AmbulanceColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color:
                    index <= currentStep
                        ? AmbulanceColors.primary
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAmbulanceTypeStep() {
    final ambulanceTypes = [
      {
        'type': 'Standard',
        'description': 'Transport médicalisé de base',
        'features': ['Brancard', 'Oxygène', 'Secouriste'],
        'price': 1500,
        'icon': Icons.local_hospital_rounded,
      },
      {
        'type': 'Médicalisée',
        'description': 'Avec équipe médicale complète',
        'features': ['Médecin', 'Infirmier', 'Équipement avancé'],
        'price': 3000,
        'icon': Icons.medical_services_rounded,
      },
      {
        'type': 'Réanimation',
        'description': 'Soins intensifs mobiles',
        'features': ['Réanimateur', 'Ventilateur', 'Monitoring'],
        'price': 500,
        'icon': Icons.emergency_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Type d\'Ambulance', '🚑'),
          const SizedBox(height: 20),
          ...ambulanceTypes.map((type) => _buildAmbulanceTypeCard(type)),
        ],
      ),
    );
  }

  Widget _buildAmbulanceTypeCard(Map<String, dynamic> type) {
    final isSelected = selectedAmbulanceType == type['type'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AmbulanceColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AmbulanceColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AmbulanceColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedAmbulanceType = type['type'];
              estimatedCost = type['price'].toDouble();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isSelected
                              ? [
                                AmbulanceColors.primary,
                                AmbulanceColors.primaryLight,
                              ]
                              : [Colors.grey.shade400, Colors.grey.shade300],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(type['icon'], color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type['type'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AmbulanceColors.primaryDark,
                            ),
                          ),
                          Text(
                            '${type['price']}F',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AmbulanceColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['description'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            (type['features'] as List<String>)
                                .map(
                                  (feature) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AmbulanceColors.primary
                                                  .withOpacity(0.1)
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isSelected
                                                ? AmbulanceColors.primary
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
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

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Localisation', '📍'),
          const SizedBox(height: 20),

          // Point de prise en charge
          _buildLocationCard(
            title: 'Point de prise en charge',
            controller: _pickupController,
            hint: 'Où vous trouvez-vous actuellement ?',
            icon: Icons.location_on_rounded,
            showCurrentLocationButton: true,
          ),

          const SizedBox(height: 16),

          // Destination
          _buildLocationCard(
            title: 'Destination',
            controller: _destinationController,
            hint: 'Où souhaitez-vous être transporté ?',
            icon: Icons.local_hospital_rounded,
          ),

          const SizedBox(height: 20),

          // Carte (simulée)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aperçu du trajet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool showCurrentLocationButton = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AmbulanceColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AmbulanceColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                Icon(icon, color: AmbulanceColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AmbulanceColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AmbulanceColors.primary),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            if (showCurrentLocationButton) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    useCurrentLocation = true;
                    controller.text = "Position actuelle (GPS)";
                  });
                },
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Utiliser ma position'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AmbulanceColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Urgence', '⏰'),
          const SizedBox(height: 20),

          _buildUrgencyOption(
            'Immédiate',
            'Prise en charge dans les plus brefs délais',
            Icons.emergency_rounded,
            AmbulanceColors.primary,
          ),

          const SizedBox(height: 16),

          _buildUrgencyOption(
            'Planifiée',
            'Programmer la prise en charge',
            Icons.schedule_rounded,
            AmbulanceColors.accent,
          ),

          if (selectedUrgency == 'Planifiée') ...[
            const SizedBox(height: 20),
            _buildDateTimeSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgencyOption(
    String type,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedUrgency == type;

    return Container(
      decoration: BoxDecoration(
        color: AmbulanceColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AmbulanceColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedUrgency = type;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AmbulanceColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
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

  Widget _buildDateTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AmbulanceColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AmbulanceColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisir la date et l\'heure',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AmbulanceColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Date',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: AmbulanceColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text(
                      selectedTime != null
                          ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Heure',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: AmbulanceColors.primaryDark,
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
    );
  }

  Widget _buildPatientInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Informations Patient', '👤'),
          const SizedBox(height: 20),

          _buildInfoField(
            'Nom du patient',
            _patientNameController,
            'Nom complet du patient',
            Icons.person_rounded,
          ),

          const SizedBox(height: 16),

          _buildInfoField(
            'Téléphone de contact',
            _phoneController,
            '+226 XX XX XX XX',
            Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          _buildInfoField(
            'Notes additionnelles (optionnel)',
            _notesController,
            'Informations médicales importantes, allergies, etc.',
            Icons.note_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AmbulanceColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AmbulanceColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                Icon(icon, color: AmbulanceColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AmbulanceColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AmbulanceColors.primary),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryAndPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('Récapitulatif & Paiement', '💳'),
          const SizedBox(height: 20),

          // Récapitulatif
          Container(
            decoration: BoxDecoration(
              color: AmbulanceColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AmbulanceColors.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Récapitulatif de votre demande',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AmbulanceColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Type d\'ambulance', selectedAmbulanceType),
                  _buildSummaryRow('Départ', _pickupController.text),
                  _buildSummaryRow('Destination', _destinationController.text),
                  _buildSummaryRow('Urgence', selectedUrgency),
                  if (selectedUrgency == 'Planifiée' && selectedDate != null)
                    _buildSummaryRow(
                      'Date/Heure',
                      '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} ${selectedTime?.format(context) ?? ''}',
                    ),
                  _buildSummaryRow('Patient', _patientNameController.text),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coût total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AmbulanceColors.primaryDark,
                        ),
                      ),
                      Text(
                        '${estimatedCost.toInt()}€',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AmbulanceColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Méthodes de paiement
          Container(
            decoration: BoxDecoration(
              color: AmbulanceColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AmbulanceColors.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Méthode de paiement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AmbulanceColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethod(
                    'Mobile Money',
                    Icons.phone_android_rounded,
                  ),
                  _buildPaymentMethod(
                    'Carte bancaire',
                    Icons.credit_card_rounded,
                  ),
                  _buildPaymentMethod('Espèces', Icons.payments_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '---' : value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AmbulanceColors.primaryDark,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode corrigée pour gérer la sélection des méthodes de paiement
  Widget _buildPaymentMethod(String method, IconData icon) {
    final isSelected = selectedPaymentMethod == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AmbulanceColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color:
            isSelected
                ? AmbulanceColors.primary.withOpacity(0.05)
                : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              selectedPaymentMethod = method;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected
                          ? AmbulanceColors.primary
                          : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected
                            ? AmbulanceColors.primary
                            : AmbulanceColors.primaryDark,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AmbulanceColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTitle(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AmbulanceColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AmbulanceColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AmbulanceColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Précédent',
                  style: TextStyle(
                    color: AmbulanceColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed:
                  isLoading
                      ? null
                      : (currentStep == 4 ? _submitRequest : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: AmbulanceColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        currentStep == 4 ? 'Confirmer la demande' : 'Suivant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (currentStep < 4) {
        setState(() {
          currentStep++;
        });
        _pageController.animateToPage(
          currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (selectedAmbulanceType.isEmpty) {
          _showErrorSnackBar('Veuillez sélectionner un type d\'ambulance');
          return false;
        }
        break;
      case 1:
        if (_pickupController.text.isEmpty) {
          _showErrorSnackBar('Veuillez indiquer le point de prise en charge');
          return false;
        }
        if (_destinationController.text.isEmpty) {
          _showErrorSnackBar('Veuillez indiquer la destination');
          return false;
        }
        break;
      case 2:
        if (selectedUrgency.isEmpty) {
          _showErrorSnackBar('Veuillez sélectionner le type d\'urgence');
          return false;
        }
        if (selectedUrgency == 'Planifiée' &&
            (selectedDate == null || selectedTime == null)) {
          _showErrorSnackBar('Veuillez sélectionner la date et l\'heure');
          return false;
        }
        break;
      case 3:
        if (_patientNameController.text.isEmpty) {
          _showErrorSnackBar('Veuillez indiquer le nom du patient');
          return false;
        }
        if (_phoneController.text.isEmpty) {
          _showErrorSnackBar('Veuillez indiquer un numéro de téléphone');
          return false;
        }
        break;
      case 4:
        if (selectedPaymentMethod.isEmpty) {
          _showErrorSnackBar('Veuillez sélectionner une méthode de paiement');
          return false;
        }
        break;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AmbulanceColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Simulation d'une requête API
      await Future.delayed(const Duration(seconds: 2));

      // Afficher la confirmation
      _showSuccessDialog();
    } catch (e) {
      _showErrorSnackBar('Une erreur est survenue. Veuillez réessayer.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AmbulanceColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Demande confirmée !',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AmbulanceColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre demande d\'ambulance a été enregistrée. Vous recevrez un SMS de confirmation avec les détails.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AmbulanceColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
