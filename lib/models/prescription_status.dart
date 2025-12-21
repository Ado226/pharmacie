// Définition centralisée de l'énumération PrescriptionStatus
// NOUVEAU FLUX SIMPLIFIÉ:
// 1. en_attente    → Commande créée, en attente de réponses des pharmacies
// 2. en_cours      → Admin a envoyé les réponses, client peut choisir une pharmacie
// 3. payee         → Client a payé la commande
// 4. en_preparation → Commande en préparation après paiement
// 5. livree        → Commande livrée au client (FIN)
// 6. annulee       → Commande annulée (à tout moment avant paiement)
enum PrescriptionStatus {
  enAttente,      // en_attente - Commande créée, en attente de réponses
  enCours,        // en_cours - Réponses reçues, client peut choisir
  enPreparation,  // en_preparation - Client a choisi, pharmacie prépare
  livree,         // livree - Commande livrée
  paye,           // payee - Commande payée (terminé)
  annulee,        // annulee - Commande annulée
}

/// Extension pour convertir un statut backend (String) en PrescriptionStatus
extension PrescriptionStatusExtension on PrescriptionStatus {
  /// Convertit un statut du backend (String) en PrescriptionStatus
  static PrescriptionStatus fromBackendString(String? statut) {
    if (statut == null || statut.isEmpty) {
      return PrescriptionStatus.enAttente;
    }

    final normalizedStatut = statut.toLowerCase().trim();

    switch (normalizedStatut) {
      case 'en_attente':
        return PrescriptionStatus.enAttente;
      case 'en_cours':
        return PrescriptionStatus.enCours;
      case 'en_preparation':
        return PrescriptionStatus.enPreparation;
      case 'livree':
        return PrescriptionStatus.livree;
      case 'payee':
        return PrescriptionStatus.paye;
      case 'annulee':
        return PrescriptionStatus.annulee;
      // Compatibilité avec anciens statuts
      case 'validee':
        return PrescriptionStatus.enCours;
      case 'prete':
        return PrescriptionStatus.livree;
      default:
        return PrescriptionStatus.enAttente;
    }
  }

  /// Convertit un PrescriptionStatus en String pour le backend
  String toBackendString() {
    switch (this) {
      case PrescriptionStatus.enAttente:
        return 'en_attente';
      case PrescriptionStatus.enCours:
        return 'en_cours';
      case PrescriptionStatus.enPreparation:
        return 'en_preparation';
      case PrescriptionStatus.livree:
        return 'livree';
      case PrescriptionStatus.paye:
        return 'payee';
      case PrescriptionStatus.annulee:
        return 'annulee';
    }
  }

  /// Retourne le label lisible du statut
  /// NOUVEAU FLUX SIMPLIFIÉ (6 statuts)
  String get label {
    switch (this) {
      case PrescriptionStatus.enAttente:
        return 'En attente';
      case PrescriptionStatus.enCours:
        return 'Réponses disponibles';
      case PrescriptionStatus.enPreparation:
        return 'En préparation';
      case PrescriptionStatus.livree:
        return 'Livrée';
      case PrescriptionStatus.paye:
        return 'Payée';
      case PrescriptionStatus.annulee:
        return 'Annulée';
    }
  }
}
