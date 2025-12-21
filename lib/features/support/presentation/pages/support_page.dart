// Fichier: lib/features/support/presentation/pages/support_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/support_remote_datasource.dart';
import 'ticket_detail_page.dart';
import 'create_ticket_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({Key? key}) : super(key: key);

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  SupportRemoteDatasource? _datasource;

  // Palette de couleurs
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal50 = Color(0xFFE0F2F1);
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
    _datasource = SupportRemoteDatasource(
      client: http.Client(),
      sharedPreferences: prefs,
    );
    _loadTickets();
  }

  Future<void> _loadTickets({bool refresh = false}) async {
    if (_datasource == null) return;

    if (refresh) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _datasource!.getMesTickets();
      setState(() {
        _tickets = result['tickets'] ?? [];
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
      case 'ouvert':
        return Colors.blue;
      case 'en_cours':
        return Colors.orange;
      case 'resolu':
        return Colors.green;
      case 'ferme':
        return textSecondary;
      default:
        return textSecondary;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'ouvert':
        return 'Ouvert';
      case 'en_cours':
        return 'En cours';
      case 'resolu':
        return 'Résolu';
      case 'ferme':
        return 'Fermé';
      default:
        return statut;
    }
  }

  IconData _getCategorieIcon(String categorie) {
    switch (categorie) {
      case 'commande':
        return Icons.shopping_bag_outlined;
      case 'paiement':
        return Icons.payment;
      case 'livraison':
        return Icons.local_shipping_outlined;
      case 'compte':
        return Icons.person_outline;
      case 'autre':
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: teal50,
      appBar: AppBar(
        backgroundColor: teal50,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: primaryTeal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Aide & Support',
          style: TextStyle(
            color: teal700,
            fontSize: 24,
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
          : RefreshIndicator(
              onRefresh: () => _loadTickets(refresh: true),
              color: primaryTeal,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHelpCard(),
                          const SizedBox(height: 24),
                          _buildFAQSection(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mes tickets',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${_tickets.length} ticket${_tickets.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _tickets.isEmpty
                      ? SliverToBoxAdapter(
                          child: _buildEmptyTickets(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ticket = _tickets[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: _buildTicketCard(ticket),
                              );
                            },
                            childCount: _tickets.length,
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketPage()),
          );
          if (result == true) {
            _loadTickets(refresh: true);
          }
        },
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouveau ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.support_agent, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Besoin d\'aide ?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Notre équipe est là pour vous aider',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'q': 'Comment passer une commande ?',
        'a': 'Pour passer une commande :\n\n1. Parcourez notre catalogue de produits\n2. Ajoutez les articles souhaités à votre panier\n3. Validez votre panier et choisissez votre mode de livraison\n4. Sélectionnez votre mode de paiement\n5. Confirmez votre commande\n\nVous recevrez une confirmation par notification.',
        'icon': Icons.shopping_cart_outlined
      },
      {
        'q': 'Comment suivre ma commande ?',
        'a': 'Pour suivre votre commande :\n\n1. Allez dans la section "Mes commandes"\n2. Cliquez sur la commande que vous souhaitez suivre\n3. Vous verrez le statut actuel de votre commande\n\nLes statuts possibles sont :\n- En attente : Commande reçue\n- En préparation : La pharmacie prépare votre commande\n- Prête : Votre commande est prête à être récupérée ou livrée\n- Livrée : Commande terminée',
        'icon': Icons.track_changes
      },
      {
        'q': 'Modes de paiement disponibles',
        'a': 'Nous acceptons les modes de paiement suivants :\n\n• MTN Mobile Money\n• Moov Money\n• Orange Money\n• Paiement à la livraison (espèces)\n\nTous les paiements mobiles sont sécurisés et vous recevrez une confirmation instantanée.',
        'icon': Icons.payment
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions fréquentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(faq['icon'] as IconData, color: primaryTeal, size: 20),
                  ),
                  title: Text(
                    faq['q'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  iconColor: primaryTeal,
                  collapsedIconColor: textSecondary,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      HapticFeedback.selectionClick();
                    }
                  },
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: teal50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        faq['a'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyTickets() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              size: 48,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun ticket',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez un ticket si vous avez besoin d\'aide',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final sujet = ticket['sujet'] ?? '';
    final statut = ticket['statut'] ?? '';
    final categorie = ticket['categorie'] ?? 'autre';
    final createdAt = ticket['created_at'] ?? '';
    final id = ticket['id'];

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailPage(ticketId: id),
          ),
        );
        if (result == true) {
          _loadTickets(refresh: true);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
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
                  _getCategorieIcon(categorie),
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
                      sujet,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatutColor(statut).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
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
                        const SizedBox(width: 8),
                        Text(
                          '#$id',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: textSecondary, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
