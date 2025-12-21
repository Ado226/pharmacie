// Widget - Empty State

import 'package:flutter/material.dart';
import '../../domain/entities/commande_detail_entity.dart';

class PharmacyResponsesEmptyStateWidget extends StatelessWidget {
  final CommandeDetailEntity commandeDetail;

  const PharmacyResponsesEmptyStateWidget({
    Key? key,
    required this.commandeDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'En attente des réponses',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Aucune pharmacie n\'a encore répondu à votre commande.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),

            // Liste des pharmacies contactées
            if (commandeDetail.pharmaciesProximite.isNotEmpty) ...[
              Text(
                '${commandeDetail.nombrePharmaciesContactees} pharmacie(s) contactée(s):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: commandeDetail.pharmaciesProximite.length,
                  itemBuilder: (context, index) {
                    final pharmacie = commandeDetail.pharmaciesProximite[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.local_pharmacy,
                          color: Color(0xFF009688),
                        ),
                        title: Text(pharmacie.nom),
                        subtitle: Text(pharmacie.quartier),
                        trailing: Text(
                          '${pharmacie.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
