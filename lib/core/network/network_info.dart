// Fichier: lib/core/network/network_info.dart
import 'package:connectivity_plus/connectivity_plus.dart';

/// Interface pour vérifier la connexion internet
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

/// Implémentation avec connectivity_plus
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    // connectivity_plus retourne maintenant une List<ConnectivityResult>
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map((resultList) {
      // Vérifier si la liste ne contient pas 'none'
      return !resultList.contains(ConnectivityResult.none);
    });
  }
}
