// Presentation Layer - Page principale
// Vue connectée au BLoC suivant Clean Architecture

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/socket_service.dart';
import '../../injection_container.dart';
import '../bloc/pharmacy_responses_cubit.dart';
import '../bloc/pharmacy_responses_state.dart';
import '../widgets/pharmacy_response_card.dart';
import '../widgets/pharmacy_details_bottom_sheet.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state_widget.dart';

class PharmacyResponsesPage extends StatelessWidget {
  final int commandeId;

  const PharmacyResponsesPage({
    Key? key,
    required this.commandeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PharmacyResponsesCubit>()..loadCommandeDetails(commandeId),
      child: PharmacyResponsesView(commandeId: commandeId),
    );
  }
}

class PharmacyResponsesView extends StatefulWidget {
  final int commandeId;

  const PharmacyResponsesView({
    Key? key,
    required this.commandeId,
  }) : super(key: key);

  @override
  State<PharmacyResponsesView> createState() => _PharmacyResponsesViewState();
}

class _PharmacyResponsesViewState extends State<PharmacyResponsesView> {
  StreamSubscription? _nouvelleReponseSubscription;
  StreamSubscription? _statutChangeSubscription;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketService = SocketService();

    // Écouter les nouvelles réponses pharmacie
    _nouvelleReponseSubscription = socketService.onNouvelleReponse.listen((data) {
      final commandeId = data['commande_id'];
      if (commandeId == widget.commandeId) {
        // Rafraîchir les données
        context.read<PharmacyResponsesCubit>().refreshCommandeDetails(widget.commandeId);

        // Afficher un toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nouvelle réponse de ${data['pharmacie_nom'] ?? 'une pharmacie'}'),
            backgroundColor: Color(0xFF009688),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    // Écouter les changements de statut
    _statutChangeSubscription = socketService.onStatutChange.listen((data) {
      final commandeId = data['commande_id'];
      if (commandeId == widget.commandeId) {
        // Rafraîchir les données
        context.read<PharmacyResponsesCubit>().refreshCommandeDetails(widget.commandeId);
      }
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
        title: Text('Réponses des pharmacies'),
        backgroundColor: Color(0xFF009688),
        elevation: 0,
        actions: [
          BlocBuilder<PharmacyResponsesCubit, PharmacyResponsesState>(
            builder: (context, state) {
              if (state is PharmacyResponsesLoaded || state is PharmacyResponsesEmpty) {
                return IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    context.read<PharmacyResponsesCubit>().refreshCommandeDetails(widget.commandeId);
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<PharmacyResponsesCubit, PharmacyResponsesState>(
        listener: (context, state) {
          // Gérer les erreurs avec SnackBar
          if (state is PharmacyResponsesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Réessayer',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<PharmacyResponsesCubit>().loadCommandeDetails(widget.commandeId);
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PharmacyResponsesLoading) {
            return PharmacyResponsesLoadingWidget();
          }

          if (state is PharmacyResponsesError) {
            return PharmacyResponsesErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<PharmacyResponsesCubit>().loadCommandeDetails(widget.commandeId);
              },
            );
          }

          if (state is PharmacyResponsesEmpty) {
            return PharmacyResponsesEmptyStateWidget(
              commandeDetail: state.commandeDetail,
            );
          }

          if (state is PharmacyResponsesLoaded) {
            return Column(
              children: [
                // En-tête avec informations de la commande
                _buildCommandeHeader(context, state),

                // Liste des réponses
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await context.read<PharmacyResponsesCubit>().refreshCommandeDetails(widget.commandeId);
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: state.commandeDetail.reponsesExistantes.length,
                      itemBuilder: (context, index) {
                        final reponse = state.commandeDetail.reponsesExistantes[index];
                        final isSelected = state.selectedResponse?.id == reponse.id;

                        return PharmacyResponseCard(
                          reponse: reponse,
                          isSelected: isSelected,
                          onTap: () {
                            context.read<PharmacyResponsesCubit>().selectResponse(reponse);
                          },
                          onDetailsPressed: () {
                            _showDetailsBottomSheet(
                              context,
                              reponse,
                              state.commandeDetail.commande.commandeProduits,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Barre de paiement si une pharmacie est sélectionnée
                if (state.selectedResponse != null)
                  _buildPaymentBar(context, state),
              ],
            );
          }

          return Center(child: Text('État inconnu'));
        },
      ),
    );
  }

  Widget _buildCommandeHeader(BuildContext context, PharmacyResponsesLoaded state) {
    final commande = state.commandeDetail.commande;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF00BCD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commande #${commande.id}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${commande.commandeProduits.length} produit(s) commandé(s)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${state.commandeDetail.nombrePharmaciesRepondu} pharmacie(s) ont répondu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBar(BuildContext context, PharmacyResponsesLoaded state) {
    final selectedResponse = state.selectedResponse!;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Montant total',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${selectedResponse.montantTotalPharmacie.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF009688),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigation vers le paiement
                  Navigator.pushNamed(
                    context,
                    '/payment',
                    arguments: {
                      'commandeId': widget.commandeId,
                      'reponseId': selectedResponse.id,
                      'montant': selectedResponse.montantTotalPharmacie,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF009688),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Procéder au paiement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsBottomSheet(
    BuildContext context,
    reponse,
    commandeProduits,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PharmacyDetailsBottomSheet(
        reponse: reponse,
        commandeProduits: commandeProduits,
      ),
    );
  }
}
