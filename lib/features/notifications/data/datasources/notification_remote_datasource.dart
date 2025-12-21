// Fichier: lib/features/notifications/data/datasources/notification_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';

class NotificationRemoteDatasource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  NotificationRemoteDatasource({
    required this.client,
    required this.sharedPreferences,
  });

  String? get _token => sharedPreferences.getString(ApiConfig.tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Récupérer les notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool nonLuesSeulement = false,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (nonLuesSeulement) 'non_lues': 'true',
    };

    final uri = Uri.parse(ApiConfig.notificationsUrl).replace(queryParameters: queryParams);
    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la récupération des notifications');
    }
  }

  /// Compter les notifications non lues
  Future<int> countNonLues() async {
    final response = await client.get(
      Uri.parse('${ApiConfig.notificationsUrl}/count'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      return 0;
    }
  }

  /// Marquer une notification comme lue
  Future<void> marquerCommeLue(int notificationId) async {
    final response = await client.put(
      Uri.parse('${ApiConfig.notificationsUrl}/$notificationId/lue'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la mise à jour');
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> marquerToutesLues() async {
    final response = await client.put(
      Uri.parse('${ApiConfig.notificationsUrl}/lues'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la mise à jour');
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(int notificationId) async {
    final response = await client.delete(
      Uri.parse('${ApiConfig.notificationsUrl}/$notificationId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la suppression');
    }
  }

  /// Mettre à jour le token FCM
  Future<void> updateFcmToken(String fcmToken) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.notificationsUrl}/fcm-token'),
      headers: _headers,
      body: jsonEncode({'fcm_token': fcmToken}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erreur lors de la mise à jour du token');
    }
  }
}
