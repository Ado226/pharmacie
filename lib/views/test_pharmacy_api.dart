// Fichier: lib/views/test_pharmacy_api.dart
// Page de test pour l'intégration des réponses pharmacies

import 'package:flutter/material.dart';
import '../services/pharmacy_response_service.dart';
import '../models/pharmacy_response_api_model.dart';
import 'pharmacy_responses_api_view.dart';

class TestPharmacyApiView extends StatefulWidget {
  const TestPharmacyApiView({Key? key}) : super(key: key);

  @override
  State<TestPharmacyApiView> createState() => _TestPharmacyApiViewState();
}

class _TestPharmacyApiViewState extends State<TestPharmacyApiView> {
  final TextEditingController _commandeIdController = TextEditingController(text: '8');
  bool _isLoading = false;
  String? _result;
  bool _isSuccess = false;

  Future<void> _testGetCommandeDetails() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final commandeId = int.parse(_commandeIdController.text);
      final details = await PharmacyResponseService.getCommandeDetails(commandeId);

      setState(() {
        _isSuccess = true;
        _result = '''
✅ SUCCESS!

Commande #${details.commande.id}
Status: ${details.commande.statut}
Type: ${details.commande.typeCommande}
Client ID: ${details.commande.clientId}

Produits commandés: ${details.commande.commandeProduits.length}
${details.commande.commandeProduits.map((p) => '  - ${p.nomProduit} (x${p.quantite})').join('\n')}

Pharmacies proches: ${details.pharmaciesProximite.length}
${details.pharmaciesProximite.take(3).map((p) => '  - ${p.nom} (${(p.distanceMetres/1000).toStringAsFixed(1)}km)').join('\n')}

Réponses reçues: ${details.reponsesExistantes.length}
${details.reponsesExistantes.map((r) => '  - ${r.pharmacie?.nom ?? 'Pharmacie'}: ${r.montantTotalPharmacie} FCFA (${r.nombreProduitsDisponibles}/${r.nombreTotalProduits} dispo)').join('\n')}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _result = '❌ ERREUR:\n\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetReponses() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final commandeId = int.parse(_commandeIdController.text);
      final reponses = await PharmacyResponseService.getReponsesForCommande(commandeId);

      setState(() {
        _isSuccess = true;
        _result = '''
✅ SUCCESS!

Nombre de réponses: ${reponses.length}

${reponses.map((r) => '''
━━━━━━━━━━━━━━━━━━━━
Réponse #${r.id}
Pharmacie: ${r.pharmacie?.nom ?? 'N/A'}
Montant: ${r.montantTotalPharmacie} FCFA
Disponibilité: ${r.nombreProduitsDisponibles}/${r.nombreTotalProduits} produits
${r.commentairePharmacie != null ? 'Commentaire: ${r.commentairePharmacie}' : ''}
''').join('\n')}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _result = '❌ ERREUR:\n\n$e';
        _isLoading = false;
      });
    }
  }

  void _openRealView() {
    final commandeId = int.tryParse(_commandeIdController.text);
    if (commandeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ID de commande invalide')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyResponsesApiView(commandeId: commandeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test API Réponses Pharmacies'),
        backgroundColor: Color(0xFF009688),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Page de Test',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Testez l\'intégration Flutter ↔ Backend',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _commandeIdController,
              decoration: InputDecoration(
                labelText: 'ID de la commande',
                hintText: 'Ex: 8',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetCommandeDetails,
              icon: Icon(Icons.science),
              label: Text('Test: Récupérer détails complets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF009688),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGetReponses,
              icon: Icon(Icons.list),
              label: Text('Test: Récupérer réponses uniquement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _openRealView,
              icon: Icon(Icons.open_in_new),
              label: Text('Ouvrir la vue réelle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 24),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement...'),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              Card(
                color: _isSuccess ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Résultat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      SelectableText(
                        _result!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Assurez-vous que le backend est démarré\n'
                      '2. Vérifiez l\'URL dans api_config.dart\n'
                      '3. Connectez-vous d\'abord pour avoir un token\n'
                      '4. Entrez un ID de commande valide\n'
                      '5. Testez les endpoints\n'
                      '6. Ouvrez la vue réelle pour voir l\'UI',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commandeIdController.dispose();
    super.dispose();
  }
}
