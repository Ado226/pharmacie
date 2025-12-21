// Fichier: lib/services/unread_responses_service.dart
// Service pour gérer les réponses de pharmacies non lues (badge)

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class UnreadResponsesService {
  static const String _viewedResponsesKey = 'viewed_pharmacy_responses';
  static const String _lastCheckKey = 'last_responses_check';

  /// Récupérer le nombre de commandes avec des réponses non lues
  static Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        return 0;
      }

      // Récupérer les commandes du client
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/client/commandes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> commandes = json.decode(response.body);

        // Récupérer les IDs des commandes déjà vues
        final viewedIds = await _getViewedResponseIds();

        int unreadCount = 0;

        for (var commande in commandes) {
          final commandeId = commande['id'];
          final statut = commande['statut'] ?? '';

          // Si la commande a des réponses (statut en_cours ou plus avancé)
          // et n'a pas encore été vue
          if (_hasResponses(statut) && !viewedIds.contains(commandeId)) {
            unreadCount++;
          }
        }

        return unreadCount;
      }

      return 0;
    } catch (e) {
      print('Erreur getUnreadCount: $e');
      return 0;
    }
  }

  /// Vérifier si le statut indique qu'il y a des réponses
  static bool _hasResponses(String statut) {
    final lowerStatut = statut.toLowerCase();
    return lowerStatut == 'en_cours' ||
           lowerStatut == 'payee' ||
           lowerStatut == 'en_preparation' ||
           lowerStatut == 'livree' ||
           lowerStatut == 'validee';
  }

  /// Récupérer les IDs des commandes dont les réponses ont été vues
  static Future<Set<int>> _getViewedResponseIds() async {
    final prefs = await SharedPreferences.getInstance();
    final String? viewedJson = prefs.getString(_viewedResponsesKey);

    if (viewedJson == null) {
      return {};
    }

    try {
      final List<dynamic> viewedList = json.decode(viewedJson);
      return viewedList.map((e) => e as int).toSet();
    } catch (e) {
      return {};
    }
  }

  /// Marquer une commande comme vue (les détails ont été consultés)
  static Future<void> markAsViewed(int commandeId) async {
    final prefs = await SharedPreferences.getInstance();
    final viewedIds = await _getViewedResponseIds();

    viewedIds.add(commandeId);

    await prefs.setString(_viewedResponsesKey, json.encode(viewedIds.toList()));
  }

  /// Vérifier si une commande a déjà été vue
  static Future<bool> isViewed(int commandeId) async {
    final viewedIds = await _getViewedResponseIds();
    return viewedIds.contains(commandeId);
  }

  /// Réinitialiser toutes les commandes vues (pour debug)
  static Future<void> resetAllViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewedResponsesKey);
  }
}
