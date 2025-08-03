import 'package:flutter/material.dart';
import 'manual_prescription_view.dart';
import 'pharmacy_responses_view.dart';
import '../models/prescription_status.dart';

class PrescriptionDetailsView extends StatelessWidget {
  final String id;
  final String patientName;
  final DateTime date;
  final List<dynamic> products;

  const PrescriptionDetailsView({
    Key? key,
    required this.id,
    required this.patientName,
    required this.date,
    required this.products,
  }) : super(key: key);

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
          'Détails de l\'ordonnance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal[400],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // Ajout des boutons flottants
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton pour modifier l'ordonnance
          FloatingActionButton(
            heroTag: 'modifyBtn',
            onPressed: () => _modifyPrescription(context),
            backgroundColor: Colors.orange,
            child: const Icon(Icons.edit),
          ),
          const SizedBox(height: 16),
          // Bouton pour renouveler l'ordonnance
          FloatingActionButton(
            heroTag: 'renewBtn',
            onPressed: () => _renewPrescription(context),
            backgroundColor: Colors.teal,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec informations de l'ordonnance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: $patientName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Nombre total de produits
                Text(
                  'Médicaments (${products.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des produits
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductItem(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône du médicament
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medication_outlined,
                color: Colors.teal[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informations du produit
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
                  const SizedBox(height: 8),
                  Text(
                    'Quantité: ${product['quantity']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _modifyPrescription(BuildContext context) {
    // Naviguer vers la page de modification de l'ordonnance
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualPrescriptionView(
          isEditing: true,
          prescriptionId: id,
          initialPatientName: patientName,
          initialProducts: List<Map<String, dynamic>>.from(products),
        ),
      ),
    );
  }

  void _renewPrescription(BuildContext context) {
    // Afficher une boîte de dialogue de confirmation stylisée
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de renouvellement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.teal[700],
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  'Renouveler l\'ordonnance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Voulez-vous renouveler cette ordonnance pour ${patientName}?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouton Annuler
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Fermer la boîte de dialogue
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Bouton Confirmer
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Fermer la boîte de dialogue
                          
                          // Naviguer vers la page des réponses des pharmacies
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PharmacyResponsesView(
                                patientName: patientName,
                                productsList: List<Map<String, dynamic>>.from(products),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirmer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
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
      },
    );
  }
}
