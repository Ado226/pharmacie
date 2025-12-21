// Widget - Bottom Sheet des détails

import 'package:flutter/material.dart';
import '../../domain/entities/reponse_pharmacie_entity.dart';
import '../../domain/entities/commande_entity.dart';

class PharmacyDetailsBottomSheet extends StatelessWidget {
  final ReponsePharmacieEntity reponse;
  final List<CommandeProduitEntity> commandeProduits;

  const PharmacyDetailsBottomSheet({
    Key? key,
    required this.reponse,
    required this.commandeProduits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // En-tête
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reponse.pharmacie?.nom ?? 'Pharmacie',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reponse.pharmacie?.adresse ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (reponse.pharmacie?.numeroTelephone != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        reponse.pharmacie!.numeroTelephone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 20),
          Divider(height: 1),

          // Liste des produits
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(20),
              itemCount: commandeProduits.length,
              itemBuilder: (context, index) {
                final produitCommande = commandeProduits[index];
                final produitDispo = reponse.produitsDisponibles.firstWhere(
                  (p) => p.produitId == produitCommande.produitId,
                  orElse: () => const ProduitDisponibleEntity(
                    produitId: -1,
                    disponible: false,
                  ),
                );

                final isAvailable = produitDispo.disponible;

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icône de disponibilité
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green[100]
                                : Colors.red[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAvailable ? Icons.check : Icons.close,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(width: 16),

                        // Informations du produit
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produitCommande.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Quantité: ${produitCommande.quantite}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (isAvailable && produitDispo.prixUnitaire != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  '${produitDispo.prixUnitaire!.toStringAsFixed(0)} FCFA/unité',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF009688),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Prix total du produit
                        if (isAvailable && produitDispo.prixTotal != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${produitDispo.prixTotal!.toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF009688),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(height: 1),

          // Footer avec montant total
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Montant total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${reponse.montantTotalPharmacie.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF009688),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
