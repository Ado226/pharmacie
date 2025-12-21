// Fichier: lib/features/prescription/presentation/pages/prescriptions_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/socket_service.dart';
import '../bloc/prescription_bloc.dart';
import '../bloc/prescription_event.dart';
import '../bloc/prescription_state.dart';
import '../../domain/entities/prescription.dart';

/// Page de liste des prescriptions - UTILISE LE NOUVEAU BLOC !
/// Design identique à l'ancien, mais avec Clean Architecture
class PrescriptionsListPage extends StatefulWidget {
  const PrescriptionsListPage({Key? key}) : super(key: key);

  @override
  State<PrescriptionsListPage> createState() => _PrescriptionsListPageState();
}

class _PrescriptionsListPageState extends State<PrescriptionsListPage> {
  StreamSubscription? _nouvelleReponseSubscription;
  StreamSubscription? _statutChangeSubscription;

  @override
  void initState() {
    super.initState();
    // Charger les prescriptions au démarrage
    context.read<PrescriptionBloc>().add(const LoadAllPrescriptions());
    // Écouter les mises à jour temps réel
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketService = SocketService();

    // Écouter les nouvelles réponses pharmacie pour rafraîchir la liste
    _nouvelleReponseSubscription = socketService.onNouvelleReponse.listen((data) {
      // Rafraîchir la liste des commandes/ordonnances
      context.read<PrescriptionBloc>().add(const LoadAllPrescriptions());

      // Afficher un toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nouvelle réponse de ${data['pharmacie_nom'] ?? 'une pharmacie'}'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    });

    // Écouter les changements de statut
    _statutChangeSubscription = socketService.onStatutChange.listen((data) {
      // Rafraîchir la liste
      context.read<PrescriptionBloc>().add(const LoadAllPrescriptions());

      // Afficher le nouveau statut
      final message = data['message'] ?? 'Statut mis à jour';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _nouvelleReponseSubscription?.cancel();
    _statutChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Ordonnances'),
        backgroundColor: Colors.teal,
      ),
      body: BlocBuilder<PrescriptionBloc, PrescriptionState>(
        builder: (context, state) {
          if (state is PrescriptionLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is PrescriptionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PrescriptionBloc>().add(const LoadAllPrescriptions());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is PrescriptionsLoaded) {
            final prescriptions = state.prescriptions;

            if (prescriptions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune ordonnance',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PrescriptionBloc>().add(const LoadAllPrescriptions());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: prescriptions.length,
                itemBuilder: (context, index) {
                  return _buildPrescriptionCard(prescriptions[index]);
                },
              ),
            );
          }

          return const Center(
            child: Text('État inconnu'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation vers la page de création (à implémenter)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Créer une nouvelle ordonnance')),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails
          context.read<PrescriptionBloc>().add(LoadPrescriptionById(prescription.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(prescription.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${prescription.medications.length} médicament(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
