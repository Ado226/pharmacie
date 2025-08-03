// Fichier: lib/views/prescription_list_view.dart
import 'package:flutter/material.dart';
import '../models/prescription_model.dart';
import '../models/prescription_status.dart';  // Importer l'énumération centralisée
import '../services/api_service.dart';
import '../services/local_database_service.dart';
import '../views/manual_prescription_view.dart';
import '../views/pharmacy_responses_view.dart';
import '../views/prescription_details_view.dart';

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

class PrescriptionListView extends StatefulWidget {
  final PrescriptionWithStatus? paidPrescription;

  const PrescriptionListView({
    Key? key,
    this.paidPrescription,
  }) : super(key: key);

  @override
  State<PrescriptionListView> createState() => _PrescriptionListViewState();
}

class _PrescriptionListViewState extends State<PrescriptionListView> {
  // Liste d'ordonnances
  List<PrescriptionWithStatus> _prescriptions = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    // Charger les ordonnances au démarrage
    _loadPrescriptions();
    
    // Ajouter l'ordonnance payée si elle existe
    if (widget.paidPrescription != null) {
      _prescriptions.insert(0, widget.paidPrescription!);
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
        setState(() {
          _prescriptions = updatedList;
        });
      } catch (e) {
        print('Erreur lors de la récupération des données depuis le serveur: $e');
        // Continuer avec les données locales en cas d'erreur
      }
    } catch (e) {
      print('Erreur lors du chargement des ordonnances: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createNewPrescription() async {
    // Naviguer vers la page de création d'ordonnance
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManualPrescriptionView(),
      ),
    );
    
    // Si une nouvelle ordonnance a été créée, recharger les données
    if (result == true) {
      _loadPrescriptions();
    }
  }

  Color _getStatusColor(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.enCours:
        return Colors.blue;
      case PrescriptionStatus.enAttente:
        return Colors.orange;
      case PrescriptionStatus.livree:
        return Colors.green;
      case PrescriptionStatus.paye:
        return Colors.purple;
      case PrescriptionStatus.validee:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _getStatusText(PrescriptionStatus status) {
    switch (status) {
      case PrescriptionStatus.enCours:
        return 'En cours';
      case PrescriptionStatus.enAttente:
        return 'En attente';
      case PrescriptionStatus.livree:
        return 'Livrée';
      case PrescriptionStatus.paye:
        return 'Payée';
      case PrescriptionStatus.validee:
        // TODO: Handle this case.
        throw UnimplementedError();
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
          'Mes Ordonnances',
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
        children: [
          // Bouton pour créer une nouvelle ordonnance
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _createNewPrescription,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text(
                'Créer une nouvelle ordonnance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Titre de la liste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historique des ordonnances',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ),
          ),
          
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
                      // Navigation vers la page de détails de l'ordonnance
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrescriptionDetailsView(
                            id: prescription.id,
                            patientName: prescription.patientName,
                            date: prescription.date,
                            products: prescription.products,
                          ),
                        ),
                      );
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
    );
  }
}
