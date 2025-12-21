// Fichier: lib/features/payment/presentation/pages/payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class PaymentPage extends StatefulWidget {
  final int commandeId;
  final double montant;
  final String? pharmacieNom;

  const PaymentPage({
    Key? key,
    required this.commandeId,
    required this.montant,
    this.pharmacieNom,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedMethod;
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  PaymentRemoteDatasource? _datasource;
  Map<String, dynamic>? _paymentInstructions;

  // Palette de couleurs
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Couleurs des opérateurs
  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color moovBlue = Color(0xFF0066B3);
  static const Color orangeColor = Color(0xFFFF6600);

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'mtn_money',
      'name': 'MTN Mobile Money',
      'icon': Icons.phone_android,
      'color': mtnYellow,
      'description': '*133#',
    },
    {
      'id': 'moov_money',
      'name': 'Moov Money',
      'icon': Icons.phone_android,
      'color': moovBlue,
      'description': '*155#',
    },
    {
      'id': 'orange_money',
      'name': 'Orange Money',
      'icon': Icons.phone_android,
      'color': orangeColor,
      'description': '#144#',
    },
    {
      'id': 'especes',
      'name': 'Espèces à la livraison',
      'icon': Icons.payments_outlined,
      'color': primaryTeal,
      'description': 'Payer en espèces',
    },
  ];

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initierPaiement() async {
    if (_selectedMethod == null) {
      _showError('Veuillez sélectionner un mode de paiement');
      return;
    }

    if (_selectedMethod != 'especes' && _phoneController.text.isEmpty) {
      _showError('Veuillez entrer votre numéro de téléphone');
      return;
    }

    if (_datasource == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _datasource!.initierPaiement(
        commandeId: widget.commandeId,
        methode: _selectedMethod!,
        numeroTelephone: _selectedMethod != 'especes' ? _phoneController.text : null,
      );

      setState(() {
        _paymentInstructions = result['instructions'];
      });

      if (mounted) {
        HapticFeedback.lightImpact();
        _showPaymentInstructions(result);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPaymentInstructions(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInstructionsSheet(result),
    );
  }

  Widget _buildInstructionsSheet(Map<String, dynamic> result) {
    final instructions = result['instructions'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryTeal, lightTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Paiement initié',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (instructions != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    instructions['message'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  if (instructions['reference'] != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Référence: ',
                          style: TextStyle(color: textSecondary),
                        ),
                        Text(
                          instructions['reference'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: primaryTeal,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: primaryTeal),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: instructions['reference']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Référence copiée'),
                                backgroundColor: primaryTeal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  if (instructions['montant'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Montant: ${instructions['montant']} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                  if (instructions['delai_minutes'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 16, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Délai: ${instructions['delai_minutes']} minutes',
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Compris',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
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
          'Paiement',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé de la commande
            _buildOrderSummary(),
            const SizedBox(height: 32),

            // Méthodes de paiement
            const Text(
              'Mode de paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),

            // Champ téléphone si mobile money
            if (_selectedMethod != null && _selectedMethod != 'especes') ...[
              const SizedBox(height: 24),
              _buildPhoneField(),
            ],

            const SizedBox(height: 32),
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${widget.commandeId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    if (widget.pharmacieNom != null)
                      Text(
                        widget.pharmacieNom!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant à payer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.montant.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMethod = method['id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryTeal : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (method['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method['icon'] as IconData,
                color: method['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method['description'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryTeal : textSecondary.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected ? primaryTeal : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
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
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          labelText: 'Numéro de téléphone',
          hintText: '07 XX XX XX XX',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone, color: primaryTeal, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _selectedMethod != null
            ? LinearGradient(
                colors: [primaryTeal, lightTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: _selectedMethod == null ? textSecondary.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _selectedMethod != null
            ? [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _isLoading || _selectedMethod == null ? null : _initierPaiement,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Payer ${widget.montant.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
