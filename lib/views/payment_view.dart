// Fichier: lib/views/payment_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'prescription_list_view.dart';
import '../core/config/api_config.dart';

class PaymentView extends StatefulWidget {
  final String patientName;
  final String pharmacyName;
  final String totalPrice;
  final List<Map<String, dynamic>> productsList;
  final int? commandeId; // ID de la commande pour mise à jour du statut
  final int? pharmacieId; // ID de la pharmacie sélectionnée
  final double? montantTotal; // Montant total numérique

  const PaymentView({
    Key? key,
    required this.patientName,
    required this.pharmacyName,
    required this.totalPrice,
    required this.productsList,
    this.commandeId,
    this.pharmacieId,
    this.montantTotal,
  }) : super(key: key);

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Focus nodes pour les animations
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  String _selectedPaymentMethod = 'Orange Money';
  bool _isLoading = false;

  // Palette de couleurs teal
  static const Color _teal50 = Color(0xFFE0F2F1);
  static const Color _teal100 = Color(0xFFB2DFDB);
  static const Color _teal200 = Color(0xFF80CBC4);
  static const Color _teal400 = Color(0xFF26A69A);
  static const Color _teal700 = Color(0xFF00796B);
  static const Color _teal800 = Color(0xFF00695C);

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Orange Money',
      'icon': Icons.phone_android,
      'color': Color(0xFFFF6600),
    },
    {
      'name': 'Moov Money',
      'icon': Icons.phone_android,
      'color': Color(0xFF0066CC),
    },
    {
      'name': 'Telecel Money',
      'icon': Icons.phone_android,
      'color': Color(0xFFE60000),
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Mettre à jour le statut de la commande dans le backend
        if (widget.commandeId != null) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(ApiConfig.tokenKey);

          if (token != null) {
            print('💳 Mise à jour du statut de la commande #${widget.commandeId} vers "payee"...');
            print('📍 Pharmacie ID: ${widget.pharmacieId}');
            print('💰 Montant total: ${widget.montantTotal}');

            // Construire le body avec pharmacie_id et montant_total si disponibles
            final Map<String, dynamic> requestBody = {'statut': 'payee'};
            if (widget.pharmacieId != null) {
              requestBody['pharmacie_id'] = widget.pharmacieId;
            }
            if (widget.montantTotal != null) {
              requestBody['montant_total'] = widget.montantTotal;
            }

            final response = await http.put(
              Uri.parse('${ApiConfig.commandesUrl}/${widget.commandeId}/status'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: json.encode(requestBody),
            );

            print('📡 Réponse API: ${response.statusCode}');

            if (response.statusCode == 200) {
              print('✅ Statut mis à jour avec succès!');
            } else {
              print('⚠️ Erreur lors de la mise à jour: ${response.body}');
            }
          }
        } else {
          print('⚠️ Pas de commandeId fourni, le statut ne sera pas mis à jour');
        }

        // Simuler un délai supplémentaire pour l'UX
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          _isLoading = false;
        });

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Paiement effectué avec succès!'),
              ],
            ),
            backgroundColor: _teal700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Créer une nouvelle prescription avec le statut "payé"
        final paidPrescription = PrescriptionWithStatus(
          id: widget.commandeId?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          patientName: widget.patientName,
          date: DateTime.now(),
          statut: 'payee',
          products: widget.productsList,
        );

        // Rediriger vers la page "Mes Ordonnances" avec l'ordonnance payée
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PrescriptionListView(
              paidPrescription: paidPrescription,
            ),
          ),
        );
      } catch (e) {
        print('❌ Erreur lors du paiement: $e');
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erreur lors du paiement: $e')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _teal50,
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: _teal700,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paiement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _teal700,
          ),
        ),
        centerTitle: true,
        backgroundColor: _teal50,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // 100 de padding en bas pour le bouton flottant
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec montant total - carte arrondie
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_teal700, _teal400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _teal700.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icône paiement
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info montant
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Montant total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.totalPrice,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge pharmacie
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.pharmacyName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section informations personnelles
              _buildSectionHeader('Informations personnelles', Icons.person_outline),
              const SizedBox(height: 12),

              // Champs de formulaire personnalisés
              // Nom et prénom
              _buildCustomInputField(
                controller: _nameController,
                focusNode: _nameFocus,
                label: 'Nom et prénom',
                hint: 'Entrez votre nom complet',
                icon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom et prénom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Numéro de téléphone
              _buildCustomInputField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                label: 'Numéro de téléphone',
                hint: 'Ex: 07 XX XX XX XX',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Adresse de livraison
              _buildCustomInputField(
                controller: _addressController,
                focusNode: _addressFocus,
                label: 'Adresse de livraison',
                hint: 'Quartier, rue, repère...',
                icon: Icons.location_on_rounded,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre adresse de livraison';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Section mode de paiement
              _buildSectionHeader('Mode de paiement', Icons.payment),
              const SizedBox(height: 12),

              // Options de paiement stylisées
              ..._paymentMethods.map((method) => _buildPaymentOption(method)),
            ],
          ),
        ),
      ),
      // Bouton flottant en bas
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width - 32,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_teal700, _teal400],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _teal700.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _processPayment,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Traitement en cours...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 20, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Payer ${widget.totalPrice}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_teal700, _teal400],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _teal800,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        final hasText = controller.text.isNotEmpty;

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _teal800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isFocused ? _teal700 : _teal400,
            ),
            hintText: hint,
            hintStyle: TextStyle(
              color: _teal200,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              color: isFocused ? _teal700 : (hasText ? _teal400 : _teal200),
              size: 20,
            ),
            suffixIcon: hasText && !isFocused
                ? Icon(Icons.check_circle, color: _teal400, size: 18)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _teal100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: hasText ? _teal400 : _teal100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: _teal700, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
            errorStyle: TextStyle(
              color: Colors.red[600],
              fontSize: 11,
            ),
          ),
          validator: validator,
          onChanged: (_) {
            (context as Element).markNeedsBuild();
          },
        );
      },
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final bool isSelected = _selectedPaymentMethod == method['name'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method['name'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _teal700 : _teal100,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icône du mode de paiement
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (method['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method['icon'],
                color: method['color'],
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Nom du mode de paiement
            Expanded(
              child: Text(
                method['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _teal800 : Colors.black87,
                ),
              ),
            ),

            // Indicateur de sélection
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _teal700 : _teal200,
                  width: 1.5,
                ),
                color: isSelected ? _teal700 : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
