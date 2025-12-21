// Fichier: lib/views/manual_prescription_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacie/views/pharmacy_responses_view.dart';
import 'package:pharmacie/views/pharmacy_responses_list_view.dart';
import 'package:uuid/uuid.dart'; // Pour générer des UUID
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/config/api_config.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/prescription/presentation/bloc/prescription_bloc.dart';

class ManualPrescriptionView extends StatelessWidget {
  final bool isEditing;
  final String? prescriptionId;
  final String? initialPatientName;
  final List<Map<String, dynamic>>? initialProducts;

  const ManualPrescriptionView({
    Key? key,
    this.isEditing = false,
    this.prescriptionId,
    this.initialPatientName,
    this.initialProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ManualPrescriptionContent(
      isEditing: isEditing,
      prescriptionId: prescriptionId,
      initialPatientName: initialPatientName,
      initialProducts: initialProducts,
    );
  }
}

class ManualPrescriptionContent extends StatefulWidget {
  final bool isEditing;
  final String? prescriptionId;
  final String? initialPatientName;
  final List<Map<String, dynamic>>? initialProducts;

  const ManualPrescriptionContent({
    Key? key,
    this.isEditing = false,
    this.prescriptionId,
    this.initialPatientName,
    this.initialProducts,
  }) : super(key: key);

  @override
  State<ManualPrescriptionContent> createState() => _ManualPrescriptionContentState();
}

class _ManualPrescriptionContentState extends State<ManualPrescriptionContent> {
  final TextEditingController _patientNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientName != null) {
      _patientNameController.text = widget.initialPatientName!;
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  void _navigateToProductAddPage() {
    if (_patientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du patient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductAddView(
          patientName: _patientNameController.text,
          isEditing: widget.isEditing,
          prescriptionId: widget.prescriptionId,
          initialProducts: widget.initialProducts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50], // Teal-50
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: Colors.teal[700],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saisie Manuelle',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.teal[700],
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.teal[50],
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0F766E).withOpacity(0.1),
                        const Color(0xFF14B8A6).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0F766E).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nouveau Patient',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saisissez les informations du patient',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Section formulaire
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label avec indicateur requis
                      Row(
                        children: [
                          const Text(
                            'Nom du patient',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF374151), // Gray-700
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              color: Colors.red[500],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Champ de saisie amélioré
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _patientNameController,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: Adolphe FARMA',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: const Color(0xFF0F766E),
                                size: 20,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F766E),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red[400]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Texte d'aide
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Nom complet du patient requis',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Bouton d'action moderne
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _navigateToProductAddPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Continuer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Note de bas de page
                Center(
                  child: Text(
                    'Les champs marqués d\'un * sont obligatoires',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Page pour ajouter des produits
class ProductAddView extends StatefulWidget {
  final String patientName;
  final bool isEditing;
  final String? prescriptionId;
  final List<Map<String, dynamic>>? initialProducts;

  const ProductAddView({
    Key? key,
    required this.patientName,
    this.isEditing = false,
    this.prescriptionId,
    this.initialProducts,
  }) : super(key: key);

  @override
  State<ProductAddView> createState() => _ProductAddViewState();
}

class _ProductAddViewState extends State<ProductAddView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  late List<Map<String, dynamic>> _productsList = [];
  List<Map<String, dynamic>> _filteredProductsList = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialProducts != null) {
      _productsList = widget.initialProducts!;
    }
    // Simuler des produits pour la démonstration
    _loadMockProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  void _loadMockProducts() {
    final mockProducts = [
      {'id': '1', 'name': 'Paracétamol', 'description': 'Antalgique et antipyrétique'},
      {'id': '2', 'name': 'Ibuprofène', 'description': 'Anti-inflammatoire non stéroïdien'},
      {'id': '3', 'name': 'Amoxicilline', 'description': 'Antibiotique'},
      {'id': '4', 'name': 'Doliprane', 'description': 'Antalgique et antipyrétique'},
      {'id': '5', 'name': 'Efferalgan', 'description': 'Antalgique et antipyrétique'},
    ];
    
    setState(() {
      _filteredProductsList = List.from(mockProducts);
    });
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      _loadMockProducts();
    } else {
      setState(() {
        _filteredProductsList = _filteredProductsList
            .where((product) => product['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _addProduct() {
    if (_productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom du produit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _productsList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _productNameController.text,
        'description': 'Produit ajouté manuellement',
      });
      _productNameController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produit ajouté avec succès'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _saveAndFinish() {
    if (_productsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un produit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Naviguer vers la page d'aperçu de l'ordonnance
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionPreviewView(
          patientName: widget.patientName,
          productsList: _productsList,
          isEditing: widget.isEditing,
          prescriptionId: widget.prescriptionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      floatingActionButton: _productsList.isNotEmpty
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saveAndFinish,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.preview_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Aperçu de l\'ordonnance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_productsList.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        backgroundColor: Colors.teal[50],
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Image.asset(
            'assets/icone/en-arriere.png',
            width: 24,
            height: 24,
            color: Colors.teal[700],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ajouter des produits',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.teal[700],
            letterSpacing: -0.6,
          ),
        ),
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF14B8A6).withOpacity(0.1),
                  const Color(0xFF14B8A6).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Section de recherche redesignée
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            decoration: BoxDecoration(
              color: Colors.teal[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre de recherche améliorée
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchController.text.isNotEmpty
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFFCBD5E1),
                      width: _searchController.text.isNotEmpty ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14B8A6).withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterProducts,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      hintStyle: TextStyle(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.search_rounded,
                            key: ValueKey(_searchController.text.isNotEmpty),
                            color: _searchController.text.isNotEmpty
                                ? const Color(0xFF14B8A6)
                                : const Color(0xFF64748B),
                            size: 24,
                          ),
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.clear_rounded,
                              color: Color(0xFF64748B),
                              size: 16,
                            ),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                          splashRadius: 16,
                        ),
                      )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // Indicateur de résultats amélioré
                if (_searchController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    offset: const Offset(0, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF14B8A6).withOpacity(0.1),
                                const Color(0xFF0F766E).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF14B8A6).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                size: 16,
                                color: const Color(0xFF0F766E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_filteredProductsList.length} résultat${_filteredProductsList.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Color(0xFF0F766E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Section des résultats de recherche
                  Container(
                    color: Colors.teal[50],
                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête de section redesigné
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF14B8A6),
                                      Color(0xFF0F766E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Catalogue des produits',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDFA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF14B8A6).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Liste des produits avec design card amélioré
                        Container(
                          height: 400,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.teal[50],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _filteredProductsList.isEmpty
                                ? _buildEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Aucun produit trouvé',
                              subtitle: 'Essayez avec d\'autres mots-clés',
                            )
                                : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredProductsList.length,
                              separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = _filteredProductsList[index];
                                return _buildModernProductCard(product);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Section des produits ajoutés redesignée
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec compteur amélioré
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF14B8A6),
                                      Color(0xFF0F766E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Produits sélectionnés',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (_productsList.isNotEmpty)
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF14B8A6),
                                          Color(0xFF0F766E),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF14B8A6).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_productsList.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Liste verticale des produits sélectionnés (style catalogue)
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.teal[50],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _productsList.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Aucun produit sélectionné',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _productsList.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final product = _productsList[index];
                                      return _buildSelectedProductCardVertical(product, index);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Espace pour le FloatingActionButton
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Widget pour l'état vide
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

// Widget pour les cartes de produits modernes
  Widget _buildModernProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProductDetails(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône avec arrière-plan coloré
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color:  Colors.teal,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product['description'] ?? 'Aucune description disponible',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Bouton d'ajout avec animation
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showPatientTypeSelection(product),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  ////////////////////

// Widget pour les produits sélectionnés - Version compacte avec croix
  Widget _buildSelectedProductCard(Map<String, dynamic> product, int index) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF14B8A6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Contenu de la carte
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product['patientType'] ?? 'Adulte',
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bouton croix en haut à droite
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _productsList.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Widget pour les produits sélectionnés - Version verticale avec icône poubelle
  Widget _buildSelectedProductCardVertical(Map<String, dynamic> product, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône avec arrière-plan coloré
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: Color(0xFF14B8A6),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Contenu principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['patientType'] ?? 'Adulte',
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Bouton poubelle pour supprimer
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _productsList.removeAt(index);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Méthode pour afficher les détails du produit - Version améliorée
  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Handle indicator
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0), // Slate-200
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

              // En-tête moderne avec dégradé
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF14B8A6), // Teal-500
                      const Color(0xFF0D9488), // Teal-600
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icône du produit
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.medication_liquid_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Informations du produit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Comprimé • 500mg',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bouton de fermeture
                    Material(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu des détails
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      _buildDetailSection(
                        'Description',
                        product['description'] ?? 'Aucune description disponible',
                        Icons.description_outlined,
                      ),

                      const SizedBox(height: 32),

                      // Posologie
                      _buildDetailSection(
                        'Posologie',
                        'Selon prescription médicale. Consultez votre médecin ou pharmacien pour plus d\'informations sur la posologie adaptée.',
                        Icons.schedule_outlined,
                      ),

                      const SizedBox(height: 32),

                      // Contre-indications
                      _buildDetailSection(
                        'Contre-indications',
                        'Ne pas utiliser en cas d\'allergie à l\'un des composants. Ne pas dépasser la dose prescrite. Tenir hors de portée des enfants.',
                        Icons.warning_outlined,
                        isWarning: true,
                      ),

                      const SizedBox(height: 32),

                      // Effets secondaires
                      _buildDetailSection(
                        'Effets secondaires',
                        'Peut provoquer des nausées, des maux de tête ou des vertiges. Si ces symptômes persistent, consultez votre médecin.',
                        Icons.info_outlined,
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
              // Bouton flottant + pour ajouter le produit
              Positioned(
                bottom: 24,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showPatientTypeSelection(product);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Animation de sortie si nécessaire
    });
  }

// Widget helper pour les sections de détails
  Widget _buildDetailSection(String title, String content, IconData icon, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC), // Red-50 ou Slate-50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0), // Red-200 ou Slate-200
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isWarning ? const Color(0xFFDC2626) : const Color(0xFF14B8A6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isWarning ? const Color(0xFFDC2626) : const Color(0xFF14B8A6),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF475569), // Slate-600
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

// Méthode pour afficher la sélection de type de patient - Version améliorée
  void _showPatientTypeSelection(Map<String, dynamic> product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête du produit
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA), // Teal-50
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.medication_liquid_rounded,
                            color: Color(0xFF14B8A6),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A), // Slate-900
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0), // Slate-200
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Comprimé • 500mg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B), // Slate-500
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC), // Slate-50
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product['description'] ?? 'Aucune description disponible',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B), // Slate-500
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Titre de sélection
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sélectionnez le type de patient',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A), // Slate-900
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Options de patient
                    Row(
                      children: [
                        Expanded(
                          child: _buildPatientTypeButton(
                            'Adulte',
                            Icons.person_outline_rounded,
                                () {
                              _addProductWithType(product, 'Adulte');
                              Navigator.pop(context);
                            },
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPatientTypeButton(
                            'Enfant',
                            Icons.child_care_outlined,
                                () {
                              _addProductWithType(product, 'Enfant');
                              Navigator.pop(context);
                            },
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showProductDetails(product);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF14B8A6),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Voir les détails',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Widget helper pour les boutons de type de patient
  Widget _buildPatientTypeButton(String label, IconData icon, VoidCallback onPressed, {required bool isPrimary}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF14B8A6) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? const Color(0xFF14B8A6) : const Color(0xFFE2E8F0),
              width: 2,
            ),
            boxShadow: isPrimary ? [
              BoxShadow(
                color: const Color(0xFF14B8A6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFF14B8A6),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : const Color(0xFF14B8A6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Méthode pour ajouter un produit avec un type de patient spécifique - Version améliorée
  void _addProductWithType(Map<String, dynamic> product, String patientType) {
    final productWithType = Map<String, dynamic>.from(product);
    productWithType['patientType'] = patientType;

    setState(() {
      _productsList.add(productWithType);
    });

    // SnackBar moderne
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Produit ajouté avec succès',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${product['name']} • ${patientType}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF14B8A6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 500),
        elevation: 8,
      ),
    );
  }


}







// Page d'aperçu de l'ordonnance améliorée
class PrescriptionPreviewView extends StatefulWidget {
  final String patientName;
  final List<Map<String, dynamic>> productsList;
  final bool isEditing;
  final String? prescriptionId;

  const PrescriptionPreviewView({
    Key? key,
    required this.patientName,
    required this.productsList,
    this.isEditing = false,
    this.prescriptionId,
  }) : super(key: key);

  @override
  State<PrescriptionPreviewView> createState() => _PrescriptionPreviewViewState();
}

class _PrescriptionPreviewViewState extends State<PrescriptionPreviewView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  // Palette de couleurs cohérente
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color darkTeal = Color(0xFF0F766E);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: _buildModernAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrescriptionHeader(formattedDate),
                const SizedBox(height: 32),
                _buildProductsSection(),
                const SizedBox(height: 32),
                _buildNotesSection(),
                const SizedBox(height: 100), // Espace pour le bouton flottant
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.teal[50],
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Image.asset(
          'assets/icone/en-arriere.png',
          width: 24,
          height: 24,
          color: Colors.teal[700],
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Aperçu de l\'ordonnance',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.teal[700],
          letterSpacing: -0.6,
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF14B8A6).withOpacity(0.1),
                const Color(0xFF14B8A6).withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionHeader(String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: lightTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ORDONNANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: darkTeal,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Prescription médicale',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              /*Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderLight),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: primaryTeal, size: 18),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),*/
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: cardWhite,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: primaryTeal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Médicaments prescrits',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.productsList.length} produit${widget.productsList.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.productsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildProductCard(index),
        ),
      ],
    );
  }

  Widget _buildProductCard(int index) {
    final product = widget.productsList[index];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryTeal, lightTeal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cardWhite,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product['description'] ?? 'Aucune description disponible',
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: borderLight,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.person_outline,
                          label: 'Patient',
                          value: product['patientType'].toString().split('.').last,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.medical_services_outlined,
                          label: 'Type',
                          value: 'Médicament',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryTeal),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Instructions importantes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Prendre les médicaments selon la prescription du médecin. Ne pas dépasser les doses prescrites. Consulter votre médecin en cas d\'effets indésirables ou de questions.',
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
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
        onPressed: _isLoading ? null : () => _handleValidation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: cardWhite,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: textSecondary,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cardWhite),
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 22),
            SizedBox(width: 12),
            Text(
              'Valider l\'ordonnance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleValidation(BuildContext context) async {
    // Import nécessaire pour AuthBloc
    final authBloc = BlocProvider.of<AuthBloc>(context);
    final authState = authBloc.state;

    // Vérifier si l'utilisateur est connecté
    if (authState is! LoginSuccess && authState is! RegisterSuccess) {
      // Afficher un dialog demandant à l'utilisateur de se connecter
      final shouldProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_person,
                  color: Color(0xFF0D9488),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Authentification requise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Vous devez être connecté pour créer une ordonnance. Souhaitez-vous vous connecter ou créer un compte?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldProceed == true) {
        // Naviguer vers la page de login
        // Importez LoginPage en haut du fichier
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );

        // Si l'utilisateur s'est connecté avec succès, réessayer la validation
        if (result == true && mounted) {
          _handleValidation(context);
        }
      }
      return;
    }

    // L'utilisateur est connecté, procéder à la validation
    setState(() => _isLoading = true);

    try {
      // Feedback haptique
      HapticFeedback.lightImpact();

      // Récupérer le token de l'utilisateur connecté
      final token = (authState is LoginSuccess)
          ? authState.token
          : (authState as RegisterSuccess).token;

      // Construire les données de l'ordonnance pour le backend
      final Map<String, dynamic> prescriptionData = {
        'type_commande': 'saisie_manuelle',
        'nom_patient': widget.patientName, // Ajouter le nom du patient
        'localisation': {
          'latitude': 0.0,
          'longitude': 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'produits': widget.productsList.map((product) {
          return {
            'produit_id': int.tryParse(product['id'] ?? '0') ?? 0,
            'nom_produit_personnalise': product['name'] ?? '',
            'quantite': 1,
            'age_cible': (product['patientType'] ?? 'Adulte').toLowerCase(),
          };
        }).toList(),
      };

      // Debug: Afficher les données envoyées
      print('📤 Données envoyées au backend:');
      print(json.encode(prescriptionData));

      // Envoyer l'ordonnance au backend via HTTP POST
      // Le backend attend les données dans un champ 'data' comme pour les ordonnances photo
      final response = await http.post(
        Uri.parse(ApiConfig.commandesUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data': json.encode(prescriptionData), // Envoyer dans le champ 'data'
        }),
      );

      // Debug: Afficher la réponse
      print('📥 Statut de la réponse: ${response.statusCode}');
      print('📥 Corps de la réponse: ${response.body}');

      // Gérer le cas d'un token invalide ou expiré (401 Unauthorized)
      if (response.statusCode == 401) {
        if (!mounted) return;

        // Déconnecter l'utilisateur en supprimant le token expiré
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(ApiConfig.tokenKey);
        await prefs.remove(ApiConfig.userIdKey);

        // Afficher un message et demander de se reconnecter
        final shouldLogin = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Session expirée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Votre session a expiré. Vous devez vous reconnecter pour continuer.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Se reconnecter',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldLogin == true) {
          // Naviguer vers la page de login
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );

          // Si l'utilisateur s'est connecté avec succès, réessayer la validation
          if (result == true && mounted) {
            _handleValidation(context);
          }
        }
        return;
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur lors de l\'enregistrement: ${response.body}');
      }

      if (!mounted) return;

      // Message de succès avec animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: cardWhite),
              const SizedBox(width: 12),
              const Text(
                'Ordonnance enregistrée avec succès!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      // Attendre un peu pour que l'utilisateur voie le message de succès
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Rediriger vers la page des réponses des pharmacies
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const PharmacyResponsesListView(),
        ),
        (route) => route.isFirst,
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: cardWhite),
              const SizedBox(width: 12),
              Text('Erreur: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Méthodes utilitaires (à adapter selon vos besoins)
  String _generateUuid() {
    // Remplacez par votre implémentation UUID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool _isValidUuid(String? uuid) {
    if (uuid == null) return false;
    final RegExp uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    return uuidRegex.hasMatch(uuid);
  }
}

