import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'manual_prescription_view.dart';
import 'pharmacy_responses_view.dart';
import '../models/prescription_status.dart';
import '../core/config/api_config.dart';

class PrescriptionDetailsViewNew extends StatefulWidget {
  final String id;

  const PrescriptionDetailsViewNew({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<PrescriptionDetailsViewNew> createState() => _PrescriptionDetailsViewNewState();
}

class _PrescriptionDetailsViewNewState extends State<PrescriptionDetailsViewNew> with WidgetsBindingObserver {
  // Constantes de couleur uniformes
  static const Color _primaryTeal = Color(0xFF0D9488);
  static const Color _lightTeal = Color(0xFF5EEAD4);

  bool _isLoading = true;
  String _patientName = '';
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _products = [];
  String? _photoUrl;
  String? _errorMessage;
  String _statut = 'en_attente';
  double _montantTotal = 0.0;
  String? _pharmacieNom;
  int? _pharmacieId;
  DateTime? _datePaiement;

  // Clé pour capturer le reçu en image
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCommandeDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Rafraîchir les données quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _loadCommandeDetails();
    }
  }

  @override
  void didUpdateWidget(covariant PrescriptionDetailsViewNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rafraîchir si l'ID de la commande change
    if (oldWidget.id != widget.id) {
      _loadCommandeDetails();
    }
  }

  Future<void> _loadCommandeDetails() async {
    // Ne pas afficher le loading si des données existent déjà (rafraîchissement silencieux)
    final bool isFirstLoad = _patientName.isEmpty;

    if (isFirstLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        setState(() {
          _errorMessage = 'Vous n\'êtes pas connecté';
          _isLoading = false;
        });
        return;
      }

      print('Chargement commande ID: ${widget.id} (premier chargement: $isFirstLoad)');

      // Utiliser la route /status qui retourne les produits
      final response = await http.get(
        Uri.parse('${ApiConfig.commandesUrl}/${widget.id}/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Statut reponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('Commande trouvee: ${data['id']}');

        setState(() {
          // Utiliser nom_patient s'il existe, sinon fallback sur "Patient"
          final nomPatient = data['nom_patient'];
          if (nomPatient != null && nomPatient.toString().isNotEmpty) {
            _patientName = nomPatient;
          } else {
            _patientName = 'Patient';
          }

          _date = DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String());
          _photoUrl = data['ordonnance_photo_url'];
          _statut = data['statut'] ?? 'en_attente';
          _montantTotal = double.tryParse(data['montant_total']?.toString() ?? '0') ?? 0.0;
          _pharmacieId = data['pharmacie_assignee_id'];

          // Date de paiement (si disponible)
          if (data['updated_at'] != null && (_statut == 'payee' || _statut == 'en_preparation' || _statut == 'livree')) {
            _datePaiement = DateTime.parse(data['updated_at']);
          }

          // Récupérer les prix depuis la réponse de la pharmacie assignée (si disponible)
          // La structure backend est: produits_disponibles = [{produit_id, disponible, prix_unitaire, quantite, prix_total}]
          Map<int, Map<String, dynamic>> prixParProduitId = {};
          // Stocker aussi les produits disponibles par index pour gérer les cas où produit_id = 0
          List<Map<String, dynamic>> produitsDisponiblesListe = [];
          final reponsesExistantes = data['reponses_existantes'] as List?;

          print('DEBUG: pharmacieId = $_pharmacieId, reponses = ${reponsesExistantes?.length ?? 0}');

          if (reponsesExistantes != null && reponsesExistantes.isNotEmpty) {
            // Fonction pour extraire les prix d'une réponse
            void extrairePrixDeReponse(Map<String, dynamic> reponse) {
              final produitsDisponibles = reponse['produits_disponibles'];
              print('DEBUG: Reponse trouvee, produits_disponibles = $produitsDisponibles');

              if (produitsDisponibles != null && produitsDisponibles is List) {
                for (var prodDispo in produitsDisponibles) {
                  final produitId = int.tryParse(prodDispo['produit_id']?.toString() ?? '0') ?? 0;
                  final prixUnitaire = double.tryParse(prodDispo['prix_unitaire']?.toString() ?? '0') ?? 0.0;
                  final prixTotal = double.tryParse(prodDispo['prix_total']?.toString() ?? '0') ?? 0.0;
                  final quantite = int.tryParse(prodDispo['quantite']?.toString() ?? '1') ?? 1;

                  print('DEBUG: Produit $produitId -> prix_unitaire=$prixUnitaire, prix_total=$prixTotal');

                  // Stocker par produit_id si valide
                  if (produitId > 0 && prixUnitaire > 0) {
                    prixParProduitId[produitId] = {
                      'prix_unitaire': prixUnitaire,
                      'prix_total': prixTotal,
                      'quantite': quantite,
                    };
                  }

                  // Stocker aussi dans la liste pour correspondance par index
                  produitsDisponiblesListe.add({
                    'produit_id': produitId,
                    'prix_unitaire': prixUnitaire,
                    'prix_total': prixTotal,
                    'quantite': quantite,
                    'disponible': prodDispo['disponible'] ?? true,
                  });
                }
              }
              // Utiliser aussi le montant total de la pharmacie si disponible
              if (reponse['montant_total_pharmacie'] != null) {
                final montantPharmacie = double.tryParse(reponse['montant_total_pharmacie']?.toString() ?? '0') ?? 0.0;
                if (montantPharmacie > 0) {
                  _montantTotal = montantPharmacie;
                  print('DEBUG: Montant total pharmacie = $_montantTotal');
                }
              }
            }

            bool reponseTrouvee = false;

            // Strategie 1: Si pharmacieId est defini, chercher la reponse correspondante
            if (_pharmacieId != null) {
              final pharmacieIdInt = int.tryParse(_pharmacieId.toString()) ?? _pharmacieId;
              for (var reponse in reponsesExistantes) {
                final reponsePharmacieId = int.tryParse(reponse['pharmacie_id']?.toString() ?? '') ?? reponse['pharmacie_id'];
                print('DEBUG: Comparaison pharmacie: $reponsePharmacieId vs $pharmacieIdInt');

                if (reponsePharmacieId == pharmacieIdInt) {
                  extrairePrixDeReponse(reponse);
                  reponseTrouvee = true;
                  break;
                }
              }
            }

            // Strategie 2: Si aucune reponse trouvee et commande payee, utiliser la premiere reponse disponible
            if (!reponseTrouvee && (_statut == 'payee' || _statut == 'en_preparation' || _statut == 'livree')) {
              print('DEBUG: Fallback - utilisation de la premiere reponse disponible');
              final premiereReponse = reponsesExistantes[0];
              extrairePrixDeReponse(premiereReponse);
            }
          }

          print('DEBUG: Prix extraits pour ${prixParProduitId.length} produits, liste: ${produitsDisponiblesListe.length}');

          // Récupérer les produits depuis la route /status
          final produitsList = data['produits'] as List?;
          if (produitsList != null) {
            _products = produitsList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final produit = item['produit'];
              final produitId = int.tryParse(item['produit_id']?.toString() ?? '0') ?? 0;

              // Essayer d'abord nom_produit_personnalise, puis nom du produit, sinon fallback
              String nomProduit;
              if (item['nom_produit_personnalise'] != null && item['nom_produit_personnalise'].toString().isNotEmpty) {
                nomProduit = item['nom_produit_personnalise'];
              } else if (produit != null && produit['nom'] != null && produit['nom'].toString().isNotEmpty) {
                nomProduit = produit['nom'];
              } else {
                nomProduit = 'Produit #$produitId';
              }

              // Chercher le prix dans les produits disponibles de la pharmacie
              double prixUnitaire = double.tryParse(item['prix_unitaire']?.toString() ?? '0') ?? 0.0;

              // Stratégie 1: chercher par produit_id si valide
              if (prixUnitaire <= 0 && produitId > 0 && prixParProduitId.containsKey(produitId)) {
                prixUnitaire = prixParProduitId[produitId]!['prix_unitaire'] ?? 0.0;
                print('DEBUG: Prix trouve par ID pour produit $produitId ($nomProduit): $prixUnitaire');
              }

              // Stratégie 2: si toujours 0, utiliser l'index correspondant dans la liste des produits disponibles
              if (prixUnitaire <= 0 && index < produitsDisponiblesListe.length) {
                final prodDispo = produitsDisponiblesListe[index];
                prixUnitaire = (prodDispo['prix_unitaire'] as double?) ?? 0.0;
                print('DEBUG: Prix trouve par INDEX[$index] pour produit ($nomProduit): $prixUnitaire');
              }

              return {
                'produit_id': produitId,
                'name': nomProduit,
                'description': produit?['description'] ?? '',
                'dosage': produit?['posologie'] ?? '',
                'quantite': item['quantite'],
                'patientType': item['age_cible'] == 'enfant' ? 'Enfant' : 'Adulte',
                'prix_unitaire': prixUnitaire,
              };
            }).toList().cast<Map<String, dynamic>>();
          }

          _isLoading = false;
        });

        print('Donnees chargees: ${_products.length} produits, patient: $_patientName');
      } else {
        setState(() {
          _errorMessage = 'Impossible de charger les details';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement: $e');
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  String? _getFullImageUrl() {
    if (_photoUrl == null || _photoUrl!.isEmpty) return null;
    return ApiConfig.buildImageUrl(_photoUrl!);
  }

  /// Obtenir la couleur du statut
  Color _getStatusColor() {
    switch (_statut.toLowerCase().trim()) {
      case 'en_attente':
        return Colors.orange;
      case 'en_cours':
      case 'validee':
        return const Color(0xFF2196F3);
      case 'en_preparation':
        return const Color(0xFF9C27B0);
      case 'livree':
      case 'prete':
        return const Color(0xFF4CAF50);
      case 'payee':
        return const Color(0xFF009688);
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtenir le label du statut
  String _getStatusLabel() {
    switch (_statut.toLowerCase().trim()) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
      case 'validee':
        return 'Reponses disponibles';
      case 'en_preparation':
        return 'En preparation';
      case 'livree':
      case 'prete':
        return 'Livree';
      case 'payee':
        return 'Payee';
      case 'annulee':
        return 'Annulee';
      default:
        return _statut;
    }
  }

  /// Verifie si l'ordonnance est payee
  bool _isPaid() {
    final status = _statut.toLowerCase().trim();
    return status == 'payee' || status == 'en_preparation' || status == 'livree';
  }

  /// Generer le contenu du QR code
  String _generateQRContent() {
    return json.encode({
      'type': 'PHARMACIE_RECEIPT',
      'commande_id': widget.id,
      'patient': _patientName,
      'date': _date.toIso8601String(),
      'montant': _montantTotal,
      'statut': _statut,
      'nb_produits': _products.length,
    });
  }

  /// Telecharger le recu en PDF
  Future<void> _downloadReceipt() async {
    try {
      // Afficher les options de telechargement
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Telecharger le recu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryTeal,
                ),
              ),
              const SizedBox(height: 20),
              // Option PDF
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red[700]),
                ),
                title: const Text('Telecharger en PDF'),
                subtitle: const Text('Fichier PDF professionnel'),
                onTap: () {
                  Navigator.pop(context);
                  _generateAndSavePDF();
                },
              ),
              // Option Partager
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.share, color: Colors.blue[700]),
                ),
                title: const Text('Partager le recu'),
                subtitle: const Text('Envoyer par WhatsApp, Email...'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReceipt();
                },
              ),
              // Option Imprimer
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.print, color: Colors.green[700]),
                ),
                title: const Text('Imprimer'),
                subtitle: const Text('Imprimer le recu directement'),
                onTap: () {
                  Navigator.pop(context);
                  _printReceipt();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Generer le document PDF
  Future<pw.Document> _buildPdfDocument() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tete
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal700,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'RECU DE PAIEMENT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Pharmacie - Application Mobile',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Informations de la commande
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMATIONS DE LA COMMANDE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 10),
                    _buildPdfInfoRow('N° Commande:', '#${widget.id}'),
                    _buildPdfInfoRow('Patient:', _patientName),
                    _buildPdfInfoRow('Date commande:', dateFormat.format(_date)),
                    if (_datePaiement != null)
                      _buildPdfInfoRow('Date paiement:', dateFormat.format(_datePaiement!)),
                    _buildPdfInfoRow('Statut:', _getStatusLabel()),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tableau des produits
              pw.Text(
                'DETAILS DES PRODUITS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal700,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // En-tete du tableau
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Produit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qte', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Prix Unit.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Lignes des produits
                  ..._products.map((product) {
                    final prixUnitaire = (product['prix_unitaire'] ?? 0.0) as double;
                    final quantite = product['quantite'] ?? 1;
                    final prixTotal = prixUnitaire * quantite;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(product['name'] ?? 'Produit'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('$quantite', textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${prixUnitaire.toStringAsFixed(0)} F', textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${prixTotal.toStringAsFixed(0)} F', textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              // Total
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal700,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL PAYE',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      '${_montantTotal.toStringAsFixed(0)} FCFA',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Pied de page
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Merci pour votre confiance !',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Ce recu a ete genere automatiquement par l\'application Pharmacie',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Date d\'emission: ${dateFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Generer et sauvegarder le PDF
  Future<void> _generateAndSavePDF() async {
    try {
      // Afficher le dialog de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _primaryTeal),
                const SizedBox(height: 16),
                const Text('Generation du PDF...'),
              ],
            ),
          ),
        ),
      );

      // Generer le PDF
      final pdf = await _buildPdfDocument();
      final bytes = await pdf.save();

      // Obtenir le dossier de telechargement
      Directory? directory;
      if (Platform.isAndroid) {
        // Sur Android, utiliser le dossier Download public
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'Recu_Commande_${widget.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      Navigator.pop(context); // Fermer le dialog

      // Afficher le succes avec option d'ouvrir
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 28),
              const SizedBox(width: 10),
              const Text('PDF Telecharge !'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Le recu a ete sauvegarde dans:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filePath,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            Container(
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
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  OpenFilex.open(filePath);
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ouvrir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Partager le recu
  Future<void> _shareReceipt() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: _primaryTeal),
        ),
      );

      final pdf = await _buildPdfDocument();
      final bytes = await pdf.save();

      final directory = await getTemporaryDirectory();
      final fileName = 'Recu_Commande_${widget.id}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Recu de paiement - Commande #${widget.id}\nMontant: ${_montantTotal.toStringAsFixed(0)} FCFA',
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Imprimer le recu
  Future<void> _printReceipt() async {
    try {
      final pdf = await _buildPdfDocument();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Recu_Commande_${widget.id}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'impression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.teal[50],
        appBar: _buildModernAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primaryTeal),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: TextStyle(
                  fontSize: 16,
                  color: _primaryTeal,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.teal[50],
        appBar: _buildModernAppBar(),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
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
                    onPressed: _loadCommandeDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Reessayer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: _buildModernAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Carte d'en-tete avec info patient
            _buildPatientCard(),
            const SizedBox(height: 16),

            // Section Paiement (si paye)
            if (_isPaid()) ...[
              _buildPaymentSection(),
              const SizedBox(height: 16),
            ],

            // Photo ordonnance
            if (_photoUrl != null && _photoUrl!.isNotEmpty) ...[
              _buildPhotoSection(),
              const SizedBox(height: 16),
            ],

            // Liste des produits (seulement si des produits existent ET pas payée)
            if (_products.isNotEmpty && !_isPaid())
              _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  /// AppBar moderne avec fond teal 50
  AppBar _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.teal[50],
      elevation: 0,
      leading: IconButton(
        icon: Image.asset(
          'assets/icone/en-arriere.png',
          width: 24,
          height: 24,
          color: _primaryTeal,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Details de l\'ordonnance',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: _primaryTeal,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: _primaryTeal, size: 22),
          onPressed: _loadCommandeDetails,
        ),
      ],
    );
  }

  /// Carte informations patient
  Widget _buildPatientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person, color: _primaryTeal, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _patientName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: '${_date.day}/${_date.month}/${_date.year}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.medication,
                  label: 'Produits',
                  value: '${_products.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Badge de statut
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _getStatusColor().withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPaid() ? Icons.check_circle : Icons.access_time,
                  color: _getStatusColor(),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: _primaryTeal, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _primaryTeal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Section Paiement avec QR Code
  Widget _buildPaymentSection() {
    return RepaintBoundary(
      key: _receiptKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tete avec icone
            Row(
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
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recu de paiement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryTeal,
                        ),
                      ),
                      Text(
                        'Transaction confirmee',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.verified, color: Colors.green[600], size: 28),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Details du paiement
            _buildPaymentDetailRow('N Commande', '#${widget.id}'),
            _buildPaymentDetailRow('Patient', _patientName),
            _buildPaymentDetailRow('Date commande', '${_date.day}/${_date.month}/${_date.year}'),
            if (_datePaiement != null)
              _buildPaymentDetailRow('Date paiement', '${_datePaiement!.day}/${_datePaiement!.month}/${_datePaiement!.year}'),

            const SizedBox(height: 16),

            // Liste des produits avec details
            if (_products.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: _primaryTeal, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Details des produits',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _primaryTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // En-tete du tableau
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'Produit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Qte',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'P.U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Lignes des produits
                    ...(_products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      final prixUnitaire = (product['prix_unitaire'] ?? 0.0) as double;
                      final quantite = product['quantite'] ?? 1;
                      final prixTotal = prixUnitaire * quantite;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? Colors.white : Colors.teal[50],
                          border: Border(
                            bottom: BorderSide(color: Colors.teal[100]!, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                product['name'] ?? 'Produit',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _primaryTeal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '$quantite',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryTeal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${prixUnitaire.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _primaryTeal,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${prixTotal.toStringAsFixed(0)} F',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryTeal,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Montant total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL PAYE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_montantTotal.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR Code
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal[200]!, width: 2),
                    ),
                    child: QrImageView(
                      data: _generateQRContent(),
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _primaryTeal,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: _primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scannez pour verifier',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bouton telecharger
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
              child: ElevatedButton.icon(
                onPressed: _downloadReceipt,
                icon: const Icon(Icons.download),
                label: const Text(
                  'Telecharger le recu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryTeal,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Photo de l'ordonnance
  Widget _buildPhotoSection() {
    final fullImageUrl = _getFullImageUrl();
    if (fullImageUrl == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: _primaryTeal, size: 24),
              const SizedBox(width: 12),
              Text(
                'Photo de l\'ordonnance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fullImageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Image non disponible',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: _primaryTeal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Section Liste des produits - Design compact et raffine
  Widget _buildProductsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined, color: _primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                'Medicaments (${_products.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun produit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: index < _products.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal[100]!, width: 0.5),
                ),
                child: Row(
                  children: [
                    // Numero compact
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _primaryTeal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Infos produit
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              product['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _primaryTeal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge Adulte/Enfant
                          if (product['patientType'] != null && product['patientType'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: product['patientType'].toString().toLowerCase() == 'enfant'
                                    ? Colors.orange[100]
                                    : Colors.blue[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product['patientType'].toString().toLowerCase() == 'enfant'
                                    ? 'Enfant'
                                    : 'Adulte',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: product['patientType'].toString().toLowerCase() == 'enfant'
                                      ? Colors.orange[800]
                                      : Colors.blue[800],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Quantite badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.teal[200]!, width: 0.5),
                      ),
                      child: Text(
                        'x${product['quantite']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryTeal,
                        ),
                      ),
                    ),
                    // Prix si paye
                    if (_isPaid() && product['prix_unitaire'] != null && product['prix_unitaire'] > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${(product['prix_unitaire'] * product['quantite']).toStringAsFixed(0)} F',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryTeal,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList()),
        ],
      ),
    );
  }

  Widget _buildProductTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: _primaryTeal,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
