// Fichier: lib/features/payment/presentation/pages/payment_history_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _paiements = [];
  int _currentPage = 1;
  int _totalPages = 1;
  PaymentRemoteDatasource? _datasource;

  // Palette de couleurs
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _initDatasource();
  }

  Future<void> _initDatasource() async {
    final prefs = await SharedPreferences.getInstance();
    _datasource = PaymentRemoteDatasource(
      client: http.Client(),
      sharedPreferences: prefs,
    );
    _loadPaiements();
  }

  Future<void> _loadPaiements({bool refresh = false}) async {
    if (_datasource == null) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }

    try {
      final result = await _datasource!.getHistorique(page: _currentPage);
      setState(() {
        _paiements = result['paiements'] ?? [];
        _totalPages = result['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'confirme':
        return Colors.green;
      case 'en_attente':
        return Colors.orange;
      case 'echoue':
        return Colors.red;
      default:
        return textSecondary;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'confirme':
        return 'Confirmé';
      case 'en_attente':
        return 'En attente';
      case 'echoue':
        return 'Échoué';
      default:
        return statut;
    }
  }

  IconData _getMethodeIcon(String methode) {
    switch (methode) {
      case 'mtn_money':
      case 'moov_money':
      case 'orange_money':
        return Icons.phone_android;
      case 'carte_bancaire':
        return Icons.credit_card;
      case 'especes':
        return Icons.payments_outlined;
      default:
        return Icons.payment;
    }
  }

  String _getMethodeLabel(String methode) {
    switch (methode) {
      case 'mtn_money':
        return 'MTN Money';
      case 'moov_money':
        return 'Moov Money';
      case 'orange_money':
        return 'Orange Money';
      case 'carte_bancaire':
        return 'Carte bancaire';
      case 'especes':
        return 'Espèces';
      default:
        return methode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historique des paiements',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
              ),
            )
          : _paiements.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadPaiements(refresh: true),
                  color: primaryTeal,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _paiements.length,
                    itemBuilder: (context, index) {
                      final paiement = _paiements[index];
                      return _buildPaymentCard(paiement);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun paiement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre historique de paiements apparaîtra ici',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> paiement) {
    final statut = paiement['statut'] ?? '';
    final methode = paiement['methode'] ?? '';
    final montant = paiement['montant'] ?? 0;
    final createdAt = paiement['created_at'] ?? '';
    final reference = paiement['reference_externe'] ?? '';
    final commande = paiement['Commande'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatutColor(statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getMethodeIcon(methode),
                    color: _getStatutColor(statut),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMethodeLabel(methode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$montant FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatutColor(statut).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatutLabel(statut),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatutColor(statut),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundGrey,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      reference.length > 20 ? '${reference.substring(0, 20)}...' : reference,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                if (commande != null)
                  Row(
                    children: [
                      Icon(Icons.receipt, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Commande #${commande['id']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
