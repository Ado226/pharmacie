// Fichier: lib/features/support/data/datasources/support_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';

class SupportRemoteDatasource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  SupportRemoteDatasource({
    required this.client,
    required this.sharedPreferences,
  });

  String? get _token => sharedPreferences.getString(ApiConfig.tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Créer un ticket de support
  Future<Map<String, dynamic>> createTicket({
    required String sujet,
    required String message,
    required String categorie,
    int? commandeId,
  }) async {
    final response = await client.post(
      Uri.parse(ApiConfig.ticketsUrl),
      headers: _headers,
      body: jsonEncode({
        'sujet': sujet,
        'message': message,
        'categorie': categorie,
        if (commandeId != null) 'commande_id': commandeId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la création du ticket');
    }
  }

  /// Récupérer mes tickets
  Future<Map<String, dynamic>> getMesTickets({int page = 1, int limit = 10}) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.ticketsUrl}/mes-tickets?page=$page&limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la récupération des tickets');
    }
  }

  /// Récupérer un ticket avec ses messages
  Future<Map<String, dynamic>> getTicket(int ticketId) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.ticketsUrl}/$ticketId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Ticket non trouvé');
    }
  }

  /// Envoyer un message dans un ticket
  Future<Map<String, dynamic>> sendMessage({
    required int ticketId,
    required String message,
  }) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.ticketsUrl}/$ticketId/message'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de l\'envoi du message');
    }
  }

  /// Fermer un ticket
  Future<void> closeTicket(int ticketId) async {
    final response = await client.put(
      Uri.parse('${ApiConfig.ticketsUrl}/$ticketId/fermer'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la fermeture du ticket');
    }
  }
}
