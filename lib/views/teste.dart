/*
// Fichier: lib/views/prescription_list_view.dart
import 'package:flutter/material.dart';
import 'dart:async'; // Ajouter l'import pour Timer
import '../models/prescription_model.dart';
import '../models/prescription_status.dart';  // Importer l'énumération centralisée
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart'; // Ajouter l'import du service Supabase
import '../services/supabase_config.dart'; // Ajouter l'import de la configuration Supabase
import '../views/manual_prescription_view.dart';
import '../views/pharmacy_responses_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Ajouter l'import de Supabase Flutter

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

class _PrescriptionListViewState extends State<ReponseListView> {
  // Liste d'ordonnances
  List<PrescriptionWithStatus> _prescriptions = [];
  bool _isLoading = true;

  // Référence au service Supabase
  late final SupabaseService _supabaseService;

  // Timer pour le rafraîchissement périodique
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Initialiser le service Supabase
    _supabaseService = SupabaseService();
    _initializeSupabase();

    // Charger les ordonnances au démarrage
    _loadPrescriptions();

    // Ajouter l'ordonnance payée si elle existe
    if (widget.paidPrescription != null) {
      _prescriptions.insert(0, widget.paidPrescription!);
    }
  }

  @override
  void dispose() {
    // Annuler le timer de rafraîchissement
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Initialiser Supabase et configurer le rafraîchissement périodique
  Future<void> _initializeSupabase() async {
    try {
      await _supabaseService.initialize();

      // Utiliser une approche simplifiée pour la mise à jour périodique
      // au lieu de s'appuyer sur Realtime qui peut causer des problèmes de compatibilité

      // Configurer un timer pour rafraîchir périodiquement les données
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

  // Méthode pour charger les ordonnances depuis la base de données et le serveur
  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Utiliser le service de base de données locale pour récupérer les ordonnances
      final localDbService = LocalDatabaseService();
      final localPrescriptions = await localDbService.getPrescriptions();

      // Convertir les prescriptions en PrescriptionWithStatus
      List<PrescriptionWithStatus> prescriptionList = [];

      for (var prescription in localPrescriptions) {
        // Créer une liste de produits simplifiée pour l'affichage
        List<Map<String, dynamic>> products = prescription.medications.map((med) => {
          'name': med.medication.name,
          'quantity': 1, // Par défaut, quantité = 1
          'form': med.medication.form,
          'dosage': med.medication.dosage,
          'usage': med.medication.usage,
        }).toList();

        // Déterminer le statut en fonction des données disponibles
        PrescriptionStatus status = PrescriptionStatus.enAttente;

        prescriptionList.add(PrescriptionWithStatus(
          id: prescription.id,
          patientName: prescription.name,
          date: prescription.createdAt,
          status: status,
          products: products,
        ));
      }

      // Mettre à jour la liste des ordonnances
      setState(() {
        _prescriptions = prescriptionList;
        _isLoading = false;
      });

      // Essayer de récupérer les données depuis le serveur
      try {
        final apiService = ApiService();
        final serverPrescriptions = await apiService.getPrescriptions();

        // Mettre à jour la base de données locale avec les données du serveur
        for (var prescription in serverPrescriptions) {
          await localDbService.insertPrescription(prescription);
        }

        // Recharger les données depuis la base de données locale
        final updatedLocalPrescriptions = await localDbService.getPrescriptions();

        // Convertir à nouveau en PrescriptionWithStatus
        List<PrescriptionWithStatus> updatedList = [];

        for (var prescription in updatedLocalPrescriptions) {
          List<Map<String, dynamic>> products = prescription.medications.map((med) => {
            'name': med.medication.name,
            'quantity': 1,
            'form': med.medication.form,
            'dosage': med.medication.dosage,
            'usage': med.medication.usage,
          }).toList();

          // Déterminer le statut
          PrescriptionStatus status = PrescriptionStatus.enAttente;

          updatedList.add(PrescriptionWithStatus(
            id: prescription.id,
            patientName: prescription.name,
            date: prescription.createdAt,
            status: status,
            products: products,
          ));
        }

        // Mettre à jour la liste des ordonnances
        if (mounted) {
          setState(() {
            _prescriptions = updatedList;
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération des données du serveur: $e');
        // Ne pas modifier l'état, garder les données locales
      }
    } catch (e) {
      print('Erreur lors du chargement des ordonnances: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Méthode pour créer une nouvelle ordonnance
  void _createNewPrescription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManualPrescriptionView(),
      ),
    ).then((value) {
      // Recharger les ordonnances après la création
      if (value == true) {
        _loadPrescriptions();
      }
    });
  }

  // Méthode pour obtenir la couleur en fonction du statut
  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.enAttente:
        return Colors.orange;
      case PrescriptionStatus.validee:
        return Colors.green;
      case PrescriptionStatus.paye:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Méthode pour obtenir le texte en fonction du statut
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: Colors.teal[800],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reponses Des Pharmacies',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal[400],
          ),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Liste des ordonnances
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      return InkWell(
                        onTap: () {
                          // Navigation vers la page des réponses des pharmacies
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PharmacyResponsesView(
                                patientName: prescription.patientName,
                                productsList: prescription.products.map((product) {
                                  // Conversion des produits simples en format attendu par PharmacyResponsesView
                                  return {
                                    'name': product['name'],
                                    'description': 'Quantité: ${product['quantity']}',
                                    'patientType': 'Adulte',
                                  };
                                }).toList(),
                                status: prescription.status, // Ajout du statut de l'ordonnance
                              ),
                            ),
                          ).then((_) {
                            // Recharger les données après être revenu de la page des réponses
                            _loadPrescriptions();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border(
                              left: BorderSide(
                                color: Colors.teal.shade400,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icône à gauche (optionnelle)
                                Icon(
                                  Icons.description_outlined,
                                  color: Colors.teal[400],
                                  size: 24,
                                ),
                                const SizedBox(width: 16),

                                // Contenu principal
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prescription.patientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Date: ${prescription.date.day}/${prescription.date.month}/${prescription.date.year}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Flèche à droite
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.teal[400],
                                      size: 16,
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(prescription.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusText(prescription.status),
                                        style: TextStyle(
                                          color: _getStatusColor(prescription.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewPrescription,
        backgroundColor: Colors.teal[700],
        child: const Icon(Icons.add),
      ),
    );
  }
}
 */

/*
import 'package:flutter/material.dart';
import '../models/prescription_status.dart';
import 'Reponse_list_view.dart';
import 'payment_view.dart';

class PharmacyResponsesView extends StatefulWidget {
  final String patientName;
  final List<Map<String, dynamic>> productsList;
  final PrescriptionStatus status;
  final bool isEditing;
  final String? prescriptionId;

  const PharmacyResponsesView({
    Key? key,
    required this.patientName,
    required this.productsList,
    this.status = PrescriptionStatus.enAttente,
    this.isEditing = false,
    this.prescriptionId,
  }) : super(key: key);

  @override
  State<PharmacyResponsesView> createState() => _PharmacyResponsesViewState();
}

class _PharmacyResponsesViewState extends State<PharmacyResponsesView> {
  // Liste simulée des pharmacies qui ont répondu
  final List<Map<String, dynamic>> _pharmacies = [
    {
      'name': 'Pharmacie Centrale',
      'distance': '1.2km',
      'deliveryTime': '30-45 min',
      'price': '12500 FCFA',
      'availability': '3/3 produits',
      'availabilityRatio': 1.0, // 100% des produits disponibles
      'selected': true, // Cette pharmacie est sélectionnée pour le statut "payé"
    },
    {
      'name': 'Pharmacie du Marché',
      'distance': '2.5km',
      'deliveryTime': '45-60 min',
      'price': '11800 FCFA',
      'availability': '2/3 produits',
      'availabilityRatio': 0.67, // 67% des produits disponibles
      'selected': false,
    },
    {
      'name': 'Pharmacie Saint-Jean',
      'distance': '3.8km',
      'deliveryTime': '60-75 min',
      'price': '13200 FCFA',
      'availability': '3/3 produits',
      'availabilityRatio': 1.0, // 100% des produits disponibles
      'selected': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: Colors.teal[800],
          ),
          onPressed: () {
            // Rediriger vers la liste des ordonnances au lieu de revenir en arrière
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ReponseListView(),
              ),
            );
          },
        ),
        title: Text(
          'Réponses des pharmacies',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal[400],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderText(),
                const SizedBox(height: 16),

                // Informations de l'ordonnance
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ordonnance: ${widget.patientName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Liste des médicaments demandés
                      Text(
                        'Médicaments demandés (${widget.productsList.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Affichage des produits
                      ...widget.productsList.map((product) => _buildProductItem(product)).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Affichage des réponses des pharmacies selon le statut
          Expanded(
            child: _buildPharmaciesSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    switch (widget.status) {
      case PrescriptionStatus.enAttente:
        return const Text(
          'Votre demande est en attente de réponses des pharmacies.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        );
      case PrescriptionStatus.enCours:
        return const Text(
          'Consultez les réponses des pharmacies et choisissez la meilleure offre.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        );
      case PrescriptionStatus.livree:
        return const Text(
          'Votre commande a été validée avec la pharmacie suivante.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPharmaciesSection() {
    switch (widget.status) {
      case PrescriptionStatus.enAttente:
        return _buildNoResponsesSection();
      case PrescriptionStatus.enCours:
        return _buildMultipleResponsesSection();
      case PrescriptionStatus.livree:
        return _buildSelectedPharmacySection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNoResponsesSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune réponse pour le moment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Les pharmacies n\'ont pas encore répondu à votre demande. Veuillez patienter ou réessayer plus tard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleResponsesSection() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pharmacies.length,
      itemBuilder: (context, index) {
        return _buildPharmacyCard(_pharmacies[index]);
      },
    );
  }

  Widget _buildSelectedPharmacySection() {
    // Trouver la pharmacie sélectionnée
    final selectedPharmacy = _pharmacies.firstWhere(
      (pharmacy) => pharmacy['selected'] == true,
      orElse: () => _pharmacies[0], // Par défaut, prendre la première si aucune n'est sélectionnée
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedPharmacy['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Informations de la pharmacie
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedPharmacy['distance'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedPharmacy['deliveryTime'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Prix et disponibilité
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prix total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedPharmacy['price'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Disponibilité',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedPharmacy['availability'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Statut de la commande
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Commande payée et confirmée',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Informations de livraison
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de livraison',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.delivery_dining,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Livraison estimée: ${selectedPharmacy['deliveryTime']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vous recevrez une notification lorsque votre commande sera en cours de livraison.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
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
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: Colors.teal[700],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Médicament sans nom',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // Utiliser le dosage et la quantité si la description n'existe pas
                  product['description'] ??
                  '${product['dosage'] ?? ''} ${product['quantity'] != null ? '- Qté: ${product['quantity']}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> pharmacy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Icône de la pharmacie
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_pharmacy,
                    color: Colors.teal[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Nom et distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy['distance'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Livraison estimée: ${pharmacy['deliveryTime']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Prix
                Text(
                  pharmacy['price'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Disponibilité des produits
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponibilité des produits',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),

                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pharmacy['availabilityRatio'],
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pharmacy['availability'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Bouton de sélection
                    ElevatedButton(
                      onPressed: () {
                        // Naviguer vers la page de paiement
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentView(
                              patientName: widget.patientName,
                              pharmacyName: pharmacy['name'],
                              totalPrice: pharmacy['price'],
                              productsList: widget.productsList,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Sélectionner',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
  }
}


*/

/*
// Fichier: lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

class HomeViewContent extends StatelessWidget {

  const HomeViewContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(context, viewModel),
                const SizedBox(height: 24),
                _buildCategories(viewModel),
                const SizedBox(height: 24),
                _buildPromoBanner(context,),
                const SizedBox(height: 24),
                _buildMedicationTitle(),
                const SizedBox(height: 16),
                _buildMedicationFeatures(context, viewModel),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(
          'Trouvez la solution de\nsanté de vos rêves',
          style: TextStyle(
            color: Colors.teal.shade800,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context,HomeViewModel viewModel) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: viewModel.updateSearchQuery,
        decoration: const InputDecoration(
          hintText: 'Search doctor, drugs, articles...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategories(HomeViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: viewModel.categories.map((category) {
        return Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _getCategoryIcon(category.title),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _getCategoryIcon(String title) {
    final iconData = _getIconData(title);
    if (iconData is IconData) {
      return Icon(
        iconData,
        color: Colors.teal,
        size: 30,
      );
    } else if (iconData is Image) {
      return iconData;
    } else {
      return Icon(
        Icons.category_outlined,
        color: Colors.teal,
        size: 30,
      );
    }
  }

  Object _getIconData(String title) {
    switch (title) {
      case 'Laboratoire':
        return Icons.science_outlined;
      case 'Pharmacie':
        return Image.asset(
          'assets/icone/pharmacie.png',
          width: 30,
          height: 30,
        );
      case 'Hospital':
        return Image.asset(
          'assets/icone/symbole-du-caducee.png',
          width: 30,
          height: 30,
        );
      case 'Ambulance':
        return Image.asset(
          'assets/icone/ambulance.png',
          width: 30,
          height: 30,
        );
      default:
        return Image.asset(
          'assets/icone/pharmacie.png',
          width: 30,
          height: 30,
        );
    }
  }





  Widget _buildPromoBanner(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    final List<String> imageList = [
      'assets/images/portrait-d-une-pharmacienne-travaillant-dans-la-pharmacie.jpg',
      'assets/images/portrait-d-une-pharmacienne-travaillant-dans-la-pharmacie.jpg',
      'assets/images/portrait-d-une-pharmacienne-travaillant-dans-la-pharmacie.jpg',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        height: h * 0.16,
        enlargeCenterPage: true,
        viewportFraction: 1.0, // L'image occupe toute la largeur
        autoPlayInterval: const Duration(seconds: 10),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
      items: imageList.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: w, // S'assure que chaque élément prend toute la largeur
              //margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4,vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Protégez la santé de votre famille\ndès maintenant',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: h * 0.01),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              'En savoir plus',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }




  Widget _buildMedicationTitle() {
    return const Text(
      'Trouver un médicament',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }



  Widget _buildMedicationFeatures(BuildContext context, HomeViewModel viewModel) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.medicationFeatures.length,
      itemBuilder: (context, index) {
        final feature = viewModel.medicationFeatures[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => feature.routeBuilder()),
            );
          },
          child: Container(
            width: w * 0.6,
            height: h * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(3, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  feature.iconAsset,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

              ],
            ),
          ),
        );
      },
    );
  }


  IconData _getFeatureIconData(int index) {
    switch (index) {
      case 0:
        return Icons.camera_alt_outlined;
      case 1:
        return Icons.medication_outlined;
      case 2:
        return Icons.history_outlined;
      case 3:
        return Icons.compare_arrows_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.email_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: '',
        ),
      ],
    );
  }
}
*/

/*
// Fichier: lib/views/manual_prescription_view.dart
import 'package:flutter/material.dart';
import 'package:pharmacie/views/pharmacy_responses_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/manual_prescription_viewmodel.dart';
import '../models/medication_model.dart';
import '../models/prescription_model.dart';
import '../models/prescription_status.dart';  // Importer l'énumération centralisée
import '../services/supabase_service.dart';  // Ajouter l'import du service Supabase
import 'dart:math'; // Importer la bibliothèque Math pour générer des UUID
import 'package:uuid/uuid.dart'; // Importer la bibliothèque UUID

class ManualPrescriptionView extends StatelessWidget {
  final bool isEditing;
  final String? prescriptionId;
  final String? initialPatientName;
  final List<Map<String, dynamic>>? initialProducts;

  const ManualPrescriptionView({
    Key? key,
    this.isEditing = false,
    this.prescriptionId,
    this.initialPatientName,
    this.initialProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManualPrescriptionViewModel(),
      child: ManualPrescriptionContent(
        isEditing: isEditing,
        prescriptionId: prescriptionId,
        initialPatientName: initialPatientName,
        initialProducts: initialProducts,
      ),
    );
  }
}

class ManualPrescriptionContent extends StatefulWidget {
  final bool isEditing;
  final String? prescriptionId;
  final String? initialPatientName;
  final List<Map<String, dynamic>>? initialProducts;

  const ManualPrescriptionContent({
    Key? key,
    this.isEditing = false,
    this.prescriptionId,
    this.initialPatientName,
    this.initialProducts,
  }) : super(key: key);

  @override
  State<ManualPrescriptionContent> createState() => _ManualPrescriptionContentState();
}

class _ManualPrescriptionContentState extends State<ManualPrescriptionContent> {
  final TextEditingController _patientNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientName != null) {
      _patientNameController.text = widget.initialPatientName!;
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  void _navigateToProductAddPage() {
    if (_patientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du patient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductAddView(
          patientName: _patientNameController.text,
          isEditing: widget.isEditing,
          prescriptionId: widget.prescriptionId,
          initialProducts: widget.initialProducts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png', // Chemin vers ton icône personnalisée
            width: 24,
            height: 24,
            color: Colors.teal[800],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saisie Manuelle de Produit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal[400],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du patient
            const Text(
              'Nom du patient',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _patientNameController,
              decoration: InputDecoration(
                hintText: 'Entrez le nom du patient',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton valider
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: _navigateToProductAddPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Valider',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page pour ajouter des produits
class ProductAddView extends StatefulWidget {
  final String patientName;
  final bool isEditing;
  final String? prescriptionId;
  final List<Map<String, dynamic>>? initialProducts;

  const ProductAddView({
    Key? key,
    required this.patientName,
    this.isEditing = false,
    this.prescriptionId,
    this.initialProducts,
  }) : super(key: key);

  @override
  State<ProductAddView> createState() => _ProductAddViewState();
}

class _ProductAddViewState extends State<ProductAddView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  late List<Map<String, dynamic>> _productsList = [];
  List<Map<String, dynamic>> _filteredProductsList = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null) {
      _productsList = widget.initialProducts!;
    }
    // Simuler des produits pour la démonstration
    _loadMockProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  void _loadMockProducts() {
    final mockProducts = [
      {'id': '1', 'name': 'Paracétamol', 'description': 'Antalgique et antipyrétique'},
      {'id': '2', 'name': 'Ibuprofène', 'description': 'Anti-inflammatoire non stéroïdien'},
      {'id': '3', 'name': 'Amoxicilline', 'description': 'Antibiotique'},
      {'id': '4', 'name': 'Doliprane', 'description': 'Antalgique et antipyrétique'},
      {'id': '5', 'name': 'Efferalgan', 'description': 'Antalgique et antipyrétique'},
    ];

    setState(() {
      _filteredProductsList = List.from(mockProducts);
    });
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      _loadMockProducts();
    } else {
      setState(() {
        _filteredProductsList = _filteredProductsList
            .where((product) => product['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _addProduct() {
    if (_productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du produit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _productsList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _productNameController.text,
        'description': 'Produit ajouté manuellement',
      });
      _productNameController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produit ajouté avec succès'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _saveAndFinish() {
    if (_productsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un produit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Naviguer vers la page d'aperçu de l'ordonnance
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionPreviewView(
          patientName: widget.patientName,
          productsList: _productsList,
          isEditing: widget.isEditing,
          prescriptionId: widget.prescriptionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50, // Correction ici
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png', // Chemin vers ton icône personnalisée
            width: 24,
            height: 24,
            color: Colors.teal[800],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ajouter des produits',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal[800],
          ),
        ),

        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information du patient
           /*
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.teal[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Catégorie: ${widget.patientType}',
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            */
            const SizedBox(height: 8),

            // Recherche de produits
            TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Reste du contenu dans un Expanded avec SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résultats de recherche
                    const Text(
                      'Résultats de recherche',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 350,
                      child: _filteredProductsList.isEmpty
                          ? const Center(
                        child: Text(
                          'Aucun produit trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: _filteredProductsList.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProductsList[index];
                          return InkWell(
                            onTap: () {
                              // Afficher les détails du produit
                              _showProductDetails(product);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.teal.shade400,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Icône à gauche (optionnelle)
                                    Icon(
                                      Icons.medication_outlined,
                                      color: Colors.teal[400],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),

                                    // Contenu principal
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product['description'] ?? 'Aucune description',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Bouton d'ajout
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.teal,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        _showPatientTypeSelection(product);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Produits ajoutés
                    const Text(
                      'Produits ajoutés',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110, // Hauteur augmentée pour éviter le débordement
                      child: _productsList.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun produit ajouté',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal, // Défilement horizontal
                              itemCount: _productsList.length,
                              itemBuilder: (context, index) {
                                final product = _productsList[index];
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Card(
                                    color: Colors.white,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.teal.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14, // Taille de police réduite
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _productsList.removeAt(index);
                                                  });
                                                },
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product['description'] ?? 'Aucune description',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                            maxLines: 1, // Limiter à une seule ligne
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8), // Espace fixe au lieu de Spacer
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.teal[50],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              'Pour: ${product['patientType']}',
                                              style: TextStyle(
                                                color: Colors.teal[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                  ],
                ),
              ),
            ),

            //const SizedBox(height: 10),

            // Bouton de validation finale
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _saveAndFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aperçu de l\'ordonnance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Méthode pour afficher les détails du produit
  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            margin: const EdgeInsets.only(left: 4), // Marge pour la bordure
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                left: BorderSide(
                  color: Colors.teal.shade400,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre de titre avec bouton de fermeture
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Détails du produit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.teal[800]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Contenu des détails
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête du produit avec icône
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icône du médicament
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.medication,
                                color: Colors.teal.shade400,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Nom et description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Comprimé - 500mg',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          product['description'] ?? 'Aucune description',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Informations supplémentaires (simulées)
                        const Text(
                          'Posologie',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selon prescription médicale. Consultez votre médecin ou pharmacien pour plus d\'informations.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Contre-indications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ne pas utiliser en cas d\'allergie à l\'un des composants. Ne pas dépasser la dose prescrite. Tenir hors de portée des enfants.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Effets secondaires',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Peut provoquer des nausées, des maux de tête ou des vertiges. Si ces symptômes persistent, consultez votre médecin.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        // Espace supplémentaire en bas pour éviter que le contenu ne soit caché par le bouton flottant
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton flottant pour ajouter à l'ordonnance
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                // Fermer d'abord la page de détails
                Navigator.pop(context);
                // Puis afficher la boîte de dialogue de sélection
                _showPatientTypeSelection(product);
              },
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text(
                'Ajouter',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour afficher la sélection de type de patient
  void _showPatientTypeSelection(Map<String, dynamic> product) {
    String selectedType = 'Adulte'; // Valeur par défaut

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(left: 4), // Marge pour la bordure
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border(
                left: BorderSide(
                  color: Colors.teal.shade400,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête du produit avec icône
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône du médicament
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.medication,
                          color: Colors.teal.shade400,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nom et description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Comprimé - 500mg',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    product['description'] ?? 'Aucune description',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Pour qui ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Option Adulte
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: () {
                              selectedType = 'Adulte';
                              _addProductWithType(product, selectedType);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade50,
                              foregroundColor: Colors.teal[800],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Adulte',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),

                      // Option Enfant
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: () {
                              selectedType = 'Enfant';
                              _addProductWithType(product, selectedType);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal[800],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Enfant',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton "Voir détails"
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Fermer la boîte de dialogue actuelle
                          _showProductDetails(product); // Afficher les détails du produit
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal[800],
                        ),
                        child: const Text(
                          'Voir détails',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Bouton "Annuler"
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal[800],
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  // Méthode pour ajouter un produit avec un type de patient spécifique
  void _addProductWithType(Map<String, dynamic> product, String patientType) {
    final productWithType = Map<String, dynamic>.from(product);
    productWithType['patientType'] = patientType;

    setState(() {
      _productsList.add(productWithType);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté pour ${patientType.toLowerCase()}'),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

// Page d'aperçu de l'ordonnance
class PrescriptionPreviewView extends StatelessWidget {
  final String patientName;
  final List<Map<String, dynamic>> productsList;
  final bool isEditing;
  final String? prescriptionId;

  const PrescriptionPreviewView({
    Key? key,
    required this.patientName,
    required this.productsList,
    this.isEditing = false,
    this.prescriptionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate = '${now.day}/${now.month}/${now.year}';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: Colors.teal[800],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aperçu de l\'ordonnance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal[800],
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de l'ordonnance
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ordonnance',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[800],
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.teal[800],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Patient: $patientName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Liste des produits
                  Text(
                    'Produits (${productsList.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productsList.length,
                    itemBuilder: (context, index) {
                      final product = productsList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.teal[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product['description'] ?? 'Aucune description',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.teal[800],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pour: ${product['patientType']}',
                                      style: TextStyle(
                                        color: Colors.teal[800],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.medical_services_outlined,
                                      size: 16,
                                      color: Colors.teal[800],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Médicament',
                                      style: TextStyle(
                                        color: Colors.teal[800],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Notes et instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes et instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Prendre les médicaments selon la prescription du médecin. Ne pas dépasser les doses prescrites. Consulter votre médecin en cas d\'effets indésirables.',
                          style: TextStyle(
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

          // Bouton de validation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                // Afficher un indicateur de chargement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enregistrement de l\'ordonnance...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  // Générer un UUID valide pour la prescription
                  final String uuid = _generateUuid();
                  print('ID généré: $uuid'); // Pour déboguer

                  final prescriptionModel = PrescriptionModel(
                    id: isEditing && prescriptionId != null
                        ? prescriptionId!
                        : uuid,
                    name: patientName,
                    createdAt: DateTime.now(),
                    medications: productsList.map((product) {
                      // Utiliser l'ID du produit s'il existe et est un UUID valide, sinon générer un UUID
                      final String medId = _isValidUuid(product['id'])
                          ? product['id']
                          : _generateUuid();

                      final medication = MedicationModel(
                        id: medId,
                        name: product['name'],
                        description: product['description'] ?? '',
                        form: product['form'] ?? 'Comprimé',
                        dosage: product['dosage'] ?? '',
                        usage: product['usage'] ?? '',
                        contraindications: product['contraindications'] ?? '',
                        imageUrl: product['imageUrl'] ?? '',
                      );

                      final patientTypeString = product['patientType'].toString().split('.').last;
                      final patientType = PatientType.values.firstWhere(
                        (type) => type.toString().split('.').last == patientTypeString,
                        orElse: () => PatientType.adulte,
                      );

                      return PrescriptionMedicationItem(
                        medication: medication,
                        patientType: patientType,
                      );
                    }).toList(),
                  );

                  // Enregistrer l'ordonnance via le service Supabase
                  final supabaseService = SupabaseService();
                  await supabaseService.initialize();

                  if (isEditing && prescriptionId != null) {
                    await supabaseService.updatePrescription(prescriptionModel);
                  } else {
                    await supabaseService.createPrescription(prescriptionModel);
                  }

                  // Afficher un message de succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ordonnance enregistrée avec succès!'),
                      backgroundColor: Colors.teal,
                    ),
                  );

                  // Naviguer vers la page des réponses des pharmacies
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PharmacyResponsesView(
                        patientName: patientName,
                        productsList: productsList.map((product) => {
                          'name': product['name'],
                          'dosage': product['dosage'],
                          'quantity': product['quantity'],
                          'patientType': product['patientType'].toString().split('.').last,
                        }).toList(),
                        status: PrescriptionStatus.enAttente,
                        isEditing: isEditing,
                        prescriptionId: prescriptionId ?? prescriptionModel.id,
                      ),
                    ),
                  );
                } catch (e) {
                  // Afficher un message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'enregistrement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Valider l\'ordonnance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour générer un UUID valide
  String _generateUuid() {
    return const Uuid().v4();
  }

  // Méthode pour vérifier si une chaîne est un UUID valide
  bool _isValidUuid(String? uuid) {
    if (uuid == null) return false;
    final RegExp uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    return uuidRegex.hasMatch(uuid);
  }
}

*/

/*
// Fichier: lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

class HomeViewContent extends StatelessWidget {

  const HomeViewContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(context, viewModel),
                const SizedBox(height: 24),
                _buildCategories(viewModel),
                const SizedBox(height: 24),
                _buildPromoBanner(context,),
                const SizedBox(height: 24),
                _buildMedicationTitle(),
                const SizedBox(height: 16),
                _buildMedicationFeatures(context, viewModel),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(
          'Trouvez la solution de\nsanté de vos rêves',
          style: TextStyle(
            color: Colors.teal.shade800,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context,HomeViewModel viewModel) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: viewModel.updateSearchQuery,
        decoration: const InputDecoration(
          hintText: 'Search doctor, drugs, articles...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategories(HomeViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: viewModel.categories.map((category) {
        return Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _getCategoryIcon(category.title),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _getCategoryIcon(String title) {
    final iconData = _getIconData(title);
    if (iconData is IconData) {
      return Icon(
        iconData,
        color: Colors.teal,
        size: 30,
      );
    } else if (iconData is Image) {
      return iconData;
    } else {
      return Icon(
        Icons.category_outlined,
        color: Colors.teal,
        size: 30,
      );
    }
  }

  Object _getIconData(String title) {
    switch (title) {
      case 'Laboratoire':
        return Icons.science_outlined;
      case 'Pharmacie':
        return Image.asset(
          'assets/icone/pharmacie.png',
          width: 30,
          height: 30,
        );
      case 'Hospital':
        return Image.asset(
          'assets/icone/symbole-du-caducee.png',
          width: 30,
          height: 30,
        );
      case 'Ambulance':
        return Image.asset(
          'assets/icone/ambulance.png',
          width: 30,
          height: 30,
        );
      default:
        return Image.asset(
          'assets/icone/pharmacie.png',
          width: 30,
          height: 30,
        );
    }
  }





  Widget _buildPromoBanner(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    final List<String> imageList = [
      'assets/images/portrait-d-une-pharmacienne-travaillant-dans-la-pharmacie.jpg',
      'assets/images/portrait-d-une-pharmacienne-travaillant-dans-la-pharmacie.jpg',
      'assets/images/portrait-d-une-pharmacienne-travaillant-dans-la-pharmacie.jpg',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        height: h * 0.16,
        enlargeCenterPage: true,
        viewportFraction: 1.0, // L'image occupe toute la largeur
        autoPlayInterval: const Duration(seconds: 10),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
      items: imageList.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: w, // S'assure que chaque élément prend toute la largeur
              //margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4,vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Protégez la santé de votre famille\ndès maintenant',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: h * 0.01),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              'En savoir plus',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }




  Widget _buildMedicationTitle() {
    return const Text(
      'Trouver un médicament',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }



  Widget _buildMedicationFeatures(BuildContext context, HomeViewModel viewModel) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.medicationFeatures.length,
      itemBuilder: (context, index) {
        final feature = viewModel.medicationFeatures[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => feature.routeBuilder()),
            );
          },
          child: Container(
            width: w * 0.6,
            height: h * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(3, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  feature.iconAsset,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

              ],
            ),
          ),
        );
      },
    );
  }


  IconData _getFeatureIconData(int index) {
    switch (index) {
      case 0:
        return Icons.camera_alt_outlined;
      case 1:
        return Icons.medication_outlined;
      case 2:
        return Icons.history_outlined;
      case 3:
        return Icons.compare_arrows_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.email_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: '',
        ),
      ],
    );
  }
}
*/