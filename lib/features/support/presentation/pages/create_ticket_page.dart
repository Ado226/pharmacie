// Fichier: lib/features/support/presentation/pages/create_ticket_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/support_remote_datasource.dart';

class CreateTicketPage extends StatefulWidget {
  final int? commandeId;

  const CreateTicketPage({Key? key, this.commandeId}) : super(key: key);

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _sujetController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategorie = 'autre';
  bool _isLoading = false;
  SupportRemoteDatasource? _datasource;

  // Palette de couleurs
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal50 = Color(0xFFE0F2F1);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  final List<Map<String, dynamic>> _categories = [
    {'id': 'commande', 'label': 'Commande', 'icon': Icons.shopping_bag_outlined},
    {'id': 'paiement', 'label': 'Paiement', 'icon': Icons.payment},
    {'id': 'livraison', 'label': 'Livraison', 'icon': Icons.local_shipping_outlined},
    {'id': 'compte', 'label': 'Mon compte', 'icon': Icons.person_outline},
    {'id': 'autre', 'label': 'Autre', 'icon': Icons.help_outline},
  ];

  @override
  void initState() {
    super.initState();
    _initDatasource();
    if (widget.commandeId != null) {
      _selectedCategorie = 'commande';
    }
  }

  Future<void> _initDatasource() async {
    final prefs = await SharedPreferences.getInstance();
    _datasource = SupportRemoteDatasource(
      client: http.Client(),
      sharedPreferences: prefs,
    );
  }

  @override
  void dispose() {
    _sujetController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_datasource == null) return;

    setState(() => _isLoading = true);

    try {
      await _datasource!.createTicket(
        sujet: _sujetController.text.trim(),
        message: _messageController.text.trim(),
        categorie: _selectedCategorie,
        commandeId: widget.commandeId,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Ticket créé avec succès'),
              ],
            ),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Nouveau ticket',
          style: TextStyle(
            color: teal700,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Catégorie
              const Text(
                'Catégorie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategorie == cat['id'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategorie = cat['id']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryTeal : cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryTeal : textSecondary.withOpacity(0.2),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryTeal.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: isSelected ? Colors.white : textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Sujet
              _buildTextField(
                controller: _sujetController,
                label: 'Sujet',
                hint: 'Décrivez brièvement votre problème',
                icon: Icons.subject,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un sujet';
                  }
                  if (value.length < 5) {
                    return 'Le sujet doit contenir au moins 5 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
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
                child: TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  style: const TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Décrivez votre problème en détail...',
                    hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: cardWhite,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez décrire votre problème';
                    }
                    return null;
                  },
                ),
              ),

              if (widget.commandeId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt, size: 18, color: primaryTeal),
                      const SizedBox(width: 8),
                      Text(
                        'Lié à la commande #${widget.commandeId}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: textSecondary.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryTeal, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: cardWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, lightTeal],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Envoyer le ticket',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
