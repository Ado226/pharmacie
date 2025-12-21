import 'package:flutter/material.dart';
import 'manual_prescription_view.dart';
import 'pharmacy_responses_view.dart';
import '../models/prescription_status.dart';
import '../core/config/api_config.dart';

class PrescriptionDetailsView extends StatelessWidget {
  final String id;
  final String patientName;
  final DateTime date;
  final List<dynamic> products;
  final String? photoUrl;

  const PrescriptionDetailsView({
    Key? key,
    required this.id,
    required this.patientName,
    required this.date,
    required this.products,
    this.photoUrl,
  }) : super(key: key);

  // Construire l'URL complète de l'image en utilisant ApiConfig centralisé
  String? _getFullImageUrl() {
    if (photoUrl == null || photoUrl!.isEmpty) return null;
    return ApiConfig.buildImageUrl(photoUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = _getFullImageUrl();

    // Debug: Afficher les données reçues
    print('🔍 Détails ordonnance ID: $id');
    print('🔍 Nom patient: $patientName');
    print('🔍 Nombre de produits: ${products.length}');
    print('🔍 Produits: $products');

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

                // Si c'est une ordonnance photo, afficher l'image
                if (fullImageUrl != null) ...[
                  const Text(
                    'Photo de l\'ordonnance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fullImageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Image non disponible',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'URL: $fullImageUrl',
                                style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nombre total de produits
                if (products.isNotEmpty)
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
          if (products.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun produit disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les détails des produits ne sont pas chargés',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
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
                    product['name'] ?? 'Médicament',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (product['description'] != null && product['description'].isNotEmpty)
                    Text(
                      product['description'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  if (product['dosage'] != null && product['dosage'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Posologie: ${product['dosage']}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (product['patientType'] != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product['patientType'],
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                                commandeId: int.tryParse(id), // Passer le commandeId pour charger les réponses depuis l'API
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
