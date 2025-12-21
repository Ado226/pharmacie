// Fichier: lib/features/evaluations/presentation/pages/create_evaluation_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/evaluation_remote_datasource.dart';
import '../widgets/star_rating_widget.dart';

class CreateEvaluationPage extends StatefulWidget {
  final int pharmacieId;
  final int commandeId;
  final String pharmacieNom;

  const CreateEvaluationPage({
    Key? key,
    required this.pharmacieId,
    required this.commandeId,
    required this.pharmacieNom,
  }) : super(key: key);

  @override
  State<CreateEvaluationPage> createState() => _CreateEvaluationPageState();
}

class _CreateEvaluationPageState extends State<CreateEvaluationPage> {
  final _commentaireController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;
  EvaluationRemoteDatasource? _datasource;

  // Palette de couleurs
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color lightTeal = Color(0xFF5EEAD4);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color starColor = Color(0xFFFFB800);

  final List<String> _ratingLabels = [
    '',
    'Très mauvais',
    'Mauvais',
    'Moyen',
    'Bon',
    'Excellent',
  ];

  @override
  void initState() {
    super.initState();
    _initDatasource();
  }

  Future<void> _initDatasource() async {
    final prefs = await SharedPreferences.getInstance();
    _datasource = EvaluationRemoteDatasource(
      client: http.Client(),
      sharedPreferences: prefs,
    );
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    if (_rating == 0) {
      _showError('Veuillez sélectionner une note');
      return;
    }

    if (_datasource == null) return;

    setState(() => _isLoading = true);

    try {
      await _datasource!.createEvaluation(
        pharmacieId: widget.pharmacieId,
        commandeId: widget.commandeId,
        note: _rating,
        commentaire: _commentaireController.text.trim(),
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Merci pour votre évaluation !'),
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
            child: const Icon(Icons.close, color: textPrimary, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Évaluer la pharmacie',
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
          children: [
            // Pharmacie info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
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
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_pharmacy,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.pharmacieNom,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commande #${widget.commandeId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Rating section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
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
                  const Text(
                    'Comment évaluez-vous cette pharmacie ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AnimatedStarRating(
                    initialRating: _rating,
                    size: 48,
                    onRatingChanged: (rating) {
                      setState(() => _rating = rating);
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _rating > 0
                        ? Container(
                            key: ValueKey(_rating),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: starColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _ratingLabels[_rating],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: starColor.withOpacity(0.8),
                              ),
                            ),
                          )
                        : const SizedBox(height: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comment section
            Container(
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _commentaireController,
                maxLines: 5,
                maxLength: 500,
                style: const TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience (optionnel)',
                  hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cardWhite,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isValid = _rating > 0;

    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isValid
            ? LinearGradient(
                colors: [primaryTeal, lightTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isValid ? null : textSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isValid
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
        onPressed: _isLoading || !isValid ? null : _submitEvaluation,
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
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Envoyer mon avis',
                    style: TextStyle(
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
