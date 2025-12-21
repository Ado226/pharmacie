// Vue pour afficher la liste des commandes du client
import 'package:flutter/material.dart';
import '../services/pharmacy_response_service.dart';
import 'pharmacy_responses_list_view.dart';

class MesCommandesView extends StatefulWidget {
  const MesCommandesView({Key? key}) : super(key: key);

  @override
  State<MesCommandesView> createState() => _MesCommandesViewState();
}

class _MesCommandesViewState extends State<MesCommandesView> {
  static const Color _primary = Color(0xFF009688);
  static const Color _background = Color(0xFFF0FDFF);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _commandes = [];

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  Future<void> _loadCommandes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les commandes du client
      final commandes = await PharmacyResponseService.getMesCommandes();
      setState(() {
        _commandes = commandes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        title: Text(
          'Mes Commandes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de vos commandes...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                'Erreur',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCommandes,
                icon: Icon(Icons.refresh),
                label: Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_commandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Aucune commande',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore passé de commande',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommandes,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _commandes.length,
        itemBuilder: (context, index) {
          final commande = _commandes[index];
          return _buildCommandeCard(commande);
        },
      ),
    );
  }

  Widget _buildCommandeCard(Map<String, dynamic> commande) {
    final int id = commande['id'];
    final String statut = commande['statut'] ?? 'en_attente';
    final DateTime createdAt = DateTime.parse(commande['created_at']);
    final int nombreProduits = (commande['CommandeProduits'] as List?)?.length ?? 0;

    // Nom du patient avec valeur par défaut pour les anciennes commandes
    final String? nomPatient = commande['nom_patient'];
    final String displayPatientName = (nomPatient != null && nomPatient.isNotEmpty)
        ? nomPatient
        : 'Patient non renseigné';

    Color statutColor = Colors.orange;
    String statutText = 'En attente';
    if (statut == 'validee') {
      statutColor = Colors.green;
      statutText = 'Validée';
    } else if (statut == 'livree') {
      statutColor = Colors.blue;
      statutText = 'Livrée';
    } else if (statut == 'annulee') {
      statutColor = Colors.red;
      statutText = 'Annulée';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacyResponsesListView(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayPatientName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statutText,
                      style: TextStyle(
                        color: statutColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Commande #$id',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    '$nombreProduits produit(s)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Voir les réponses',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: _primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
