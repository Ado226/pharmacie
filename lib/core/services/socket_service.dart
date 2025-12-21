// Fichier: lib/core/services/socket_service.dart
// Service Socket.io pour les mises à jour en temps réel

import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

/// Service singleton pour gérer la connexion Socket.io
/// Permet de recevoir les mises à jour en temps réel du backend
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  int? _clientId;

  // Stream controllers pour les différents événements
  final _nouvelleReponseController = StreamController<Map<String, dynamic>>.broadcast();
  final _statutChangeController = StreamController<Map<String, dynamic>>.broadcast();
  final _commandeUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Getters pour les streams
  Stream<Map<String, dynamic>> get onNouvelleReponse => _nouvelleReponseController.stream;
  Stream<Map<String, dynamic>> get onStatutChange => _statutChangeController.stream;
  Stream<Map<String, dynamic>> get onCommandeUpdated => _commandeUpdatedController.stream;
  Stream<bool> get onConnectionStatus => _connectionStatusController.stream;

  bool get isConnected => _isConnected;

  /// Initialise la connexion Socket.io
  void init(int clientId) {
    _clientId = clientId;

    // Construire l'URL Socket.io à partir de la config
    final socketUrl = ApiConfig.resourceUrl;

    print('SocketService: Connexion à $socketUrl');

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      print('SocketService: Connecté au serveur');
      _isConnected = true;
      _connectionStatusController.add(true);

      // Rejoindre la room du client
      if (_clientId != null) {
        _socket?.emit('join-client', _clientId);
        print('SocketService: Rejoint room client-$_clientId');
      }
    });

    _socket?.onDisconnect((_) {
      print('SocketService: Déconnecté du serveur');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket?.onConnectError((error) {
      print('SocketService: Erreur de connexion - $error');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    // Écouter les nouvelles réponses pharmacie
    _socket?.on('nouvelle-reponse', (data) {
      print('SocketService: Nouvelle réponse reçue - $data');
      if (data is Map<String, dynamic>) {
        _nouvelleReponseController.add(data);
      } else if (data is Map) {
        _nouvelleReponseController.add(Map<String, dynamic>.from(data));
      }
    });

    // Écouter les changements de statut de commande
    _socket?.on('statut-change', (data) {
      print('SocketService: Statut changé - $data');
      if (data is Map<String, dynamic>) {
        _statutChangeController.add(data);
      } else if (data is Map) {
        _statutChangeController.add(Map<String, dynamic>.from(data));
      }
    });

    // Écouter les mises à jour de commande
    _socket?.on('commande-updated', (data) {
      print('SocketService: Commande mise à jour - $data');
      if (data is Map<String, dynamic>) {
        _commandeUpdatedController.add(data);
      } else if (data is Map) {
        _commandeUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Reconnecte le socket avec un nouveau client ID
  void reconnect(int clientId) {
    _clientId = clientId;
    if (_socket != null && _isConnected) {
      _socket?.emit('join-client', clientId);
    } else {
      init(clientId);
    }
  }

  /// Déconnecte le socket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  /// Libère les ressources
  void dispose() {
    disconnect();
    _nouvelleReponseController.close();
    _statutChangeController.close();
    _commandeUpdatedController.close();
    _connectionStatusController.close();
  }
}
