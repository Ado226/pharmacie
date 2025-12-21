// Fichier: lib/services/notification_service.dart
// Service de notifications locales (sans Firebase/WorkManager)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Timer? _pollingTimer;

  // Clé pour stocker la navigation en attente
  static const String _pendingNavigationKey = 'pending_notification_navigation';

  // Intervalle de polling quand l'app est ouverte (30 secondes)
  static const Duration _pollingInterval = Duration(seconds: 30);

  // Dernier ID de notification vu
  static int _lastNotificationId = 0;

  // GlobalKey pour la navigation
  static GlobalKey<NavigatorState>? navigatorKey;

  // Stream pour notifier les changements
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  // Compteur de notifications non lues
  static int _unreadCount = 0;
  static final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  static Stream<int> get onUnreadCountChanged => _unreadCountController.stream;
  static int get unreadCount => _unreadCount;

  /// Initialiser le service de notifications
  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    if (_initialized) return;

    navigatorKey = navKey;

    try {
      // 1. Initialiser les notifications locales
      await _initLocalNotifications();

      // 2. Charger le dernier ID de notification
      final prefs = await SharedPreferences.getInstance();
      _lastNotificationId = prefs.getInt('last_notification_id') ?? 0;

      // 3. Démarrer le polling quand l'app est ouverte
      _startPolling();

      // 4. Vérifier s'il y a une navigation en attente
      await _checkPendingNavigation();

      _initialized = true;
      print('NotificationService initialise');
    } catch (e) {
      print('Erreur initialisation NotificationService: $e');
    }
  }

  /// Initialiser les notifications locales
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Créer le canal de notification Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'pharmacie_reponses',
        'Reponses Pharmacies',
        description: 'Notifications quand une pharmacie repond a votre demande',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Afficher une notification avec les données de navigation
  static Future<void> _showNotificationWithNavigation({
    required int id,
    required String title,
    required String body,
    required String type,
    dynamic data,
  }) async {
    // Préparer le payload avec les infos de navigation
    final payload = json.encode({
      'id': id,
      'type': type,
      'data': data,
      'commande_id': data?['commande_id'],
    });

    const androidDetails = AndroidNotificationDetails(
      'pharmacie_reponses',
      'Reponses Pharmacies',
      channelDescription: 'Notifications quand une pharmacie repond',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF0D9488),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handler quand une notification est tapée (app ouverte)
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapee: ${response.payload}');
    _handleNotificationTap(response.payload);
  }

  /// Handler quand une notification est tapée (app fermée)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    print('Notification tapee (background): ${response.payload}');
    // Sauvegarder pour navigation au prochain démarrage
    _savePendingNavigation(response.payload);
  }

  /// Sauvegarder la navigation en attente
  static Future<void> _savePendingNavigation(String? payload) async {
    if (payload == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingNavigationKey, payload);
  }

  /// Vérifier s'il y a une navigation en attente
  static Future<void> _checkPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_pendingNavigationKey);

    if (pending != null) {
      await prefs.remove(_pendingNavigationKey);
      // Attendre que l'app soit prête
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(pending);
      });
    }
  }

  /// Gérer le tap sur une notification
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final data = json.decode(payload);
      final type = data['type'] as String?;
      final commandeId = data['commande_id'] ?? data['data']?['commande_id'];

      print('Navigation: type=$type, commandeId=$commandeId');

      // Émettre l'événement pour les listeners
      _notificationController.add({
        'action': 'navigate',
        'type': type,
        'commande_id': commandeId,
        'data': data,
      });

      // Naviguer vers la bonne page si navigatorKey est disponible
      if (navigatorKey?.currentState != null && commandeId != null) {
        navigatorKey!.currentState!.pushNamed(
          '/pharmacy-responses-detail',
          arguments: {'commande_id': commandeId},
        );
      }
    } catch (e) {
      print('Erreur parsing notification: $e');
    }
  }

  /// Démarrer le polling quand l'app est au premier plan
  static void _startPolling() {
    _checkForNewNotifications();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _checkForNewNotifications();
    });
  }

  /// Arrêter le polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Vérifier les nouvelles notifications (app ouverte)
  static Future<void> _checkForNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) return;

      final countResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/client/notifications/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (countResponse.statusCode == 200) {
        final countData = json.decode(countResponse.body);
        final newCount = countData['count'] ?? 0;

        if (newCount > _unreadCount) {
          await _fetchAndShowNewNotifications(token);
        }

        _unreadCount = newCount;
        _unreadCountController.add(_unreadCount);
      }
    } catch (e) {
      // Silencieux
    }
  }

  /// Récupérer et afficher les nouvelles notifications
  static Future<void> _fetchAndShowNewNotifications(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/client/notifications?limit=5&non_lues=true'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = data['notifications'] as List? ?? [];

        for (var notif in notifications) {
          final notifId = notif['id'] as int;

          if (notifId > _lastNotificationId) {
            await _showNotificationWithNavigation(
              id: notifId,
              title: notif['titre'] ?? 'Nouvelle reponse',
              body: notif['message'] ?? '',
              type: notif['type'] ?? 'systeme',
              data: notif['data'],
            );

            _notificationController.add({
              'title': notif['titre'],
              'body': notif['message'],
              'type': notif['type'],
              'data': notif['data'],
            });

            _lastNotificationId = notifId;
            await prefs.setInt('last_notification_id', notifId);
          }
        }
      }
    } catch (e) {
      print('Erreur fetch notifications: $e');
    }
  }

  /// Récupérer le nombre de notifications non lues
  static Future<int> refreshUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/client/notifications/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _unreadCount = data['count'] ?? 0;
        _unreadCountController.add(_unreadCount);
        return _unreadCount;
      }
    } catch (e) {
      print('Erreur count: $e');
    }
    return _unreadCount;
  }

  /// Récupérer les notifications
  static Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool nonLuesSeulement = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) return [];

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (nonLuesSeulement) 'non_lues': 'true',
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/client/notifications')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
    } catch (e) {
      print('Erreur get notifications: $e');
    }
    return [];
  }

  /// Marquer une notification comme lue
  static Future<bool> markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/client/notifications/$notificationId/lue'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await refreshUnreadCount();
        return true;
      }
    } catch (e) {
      print('Erreur mark as read: $e');
    }
    return false;
  }

  /// Marquer toutes comme lues
  static Future<bool> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/client/notifications/marquer-toutes-lues'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _unreadCount = 0;
        _unreadCountController.add(0);
        return true;
      }
    } catch (e) {
      print('Erreur mark all: $e');
    }
    return false;
  }

  /// Supprimer une notification
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/client/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await refreshUnreadCount();
        return true;
      }
    } catch (e) {
      print('Erreur delete: $e');
    }
    return false;
  }

  /// Forcer une vérification
  static Future<void> checkNow() async {
    await _checkForNewNotifications();
  }

  /// Nettoyer
  static void dispose() {
    stopPolling();
    _notificationController.close();
    _unreadCountController.close();
  }
}
