// Fichier: lib/services/mysql_service.dart
import 'dart:async';
import 'package:mysql1/mysql1.dart';
import '../services/database_config.dart';

class MySqlService {
  // Singleton pattern
  static final MySqlService _instance = MySqlService._internal();
  factory MySqlService() => _instance;
  MySqlService._internal();

  // Connection instance
  MySqlConnection? _connection;
  bool _isConnected = false;

  // Getter pour vérifier si la connexion est établie
  bool get isConnected => _isConnected;

  // Méthode pour établir une connexion à la base de données MySQL
  Future<void> connect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
      }

      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.user,
        password: DatabaseConfig.password,
        db: DatabaseConfig.db,
      );

      _connection = await MySqlConnection.connect(settings);
      _isConnected = true;
      print('Connexion à la base de données MySQL établie avec succès.');
    } catch (e) {
      _isConnected = false;
      print('Erreur lors de la connexion à la base de données MySQL: $e');
      rethrow;
    }
  }

  // Méthode pour fermer la connexion
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
        _isConnected = false;
        print('Connexion à la base de données MySQL fermée avec succès.');
      }
    } catch (e) {
      print('Erreur lors de la fermeture de la connexion MySQL: $e');
      rethrow;
    }
  }

  // Méthode pour exécuter une requête SELECT
  Future<List<Map<String, dynamic>>> query(String sql, [List<Object>? params]) async {
    try {
      if (!_isConnected || _connection == null) {
        await connect();
      }

      final Results results = await _connection!.query(sql, params);
      return results.map((row) => _convertResultRow(row)).toList();
    } catch (e) {
      print('Erreur lors de l\'exécution de la requête: $e');
      rethrow;
    }
  }

  // Méthode pour exécuter une requête INSERT
  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      if (!_isConnected || _connection == null) {
        await connect();
      }

      final String columns = data.keys.join(', ');
      final String placeholders = data.keys.map((_) => '?').join(', ');
      final String sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';

      final Results results = await _connection!.query(sql, data.values.toList());
      return results.insertId ?? 0;
    } catch (e) {
      print('Erreur lors de l\'insertion de données: $e');
      rethrow;
    }
  }

  // Méthode pour exécuter une requête UPDATE
  Future<int> update(String table, Map<String, dynamic> data, String where, [List<Object>? whereParams]) async {
    try {
      if (!_isConnected || _connection == null) {
        await connect();
      }

      final List<String> setClauses = data.keys.map((key) => '$key = ?').toList();
      final String setClause = setClauses.join(', ');
      final String sql = 'UPDATE $table SET $setClause WHERE $where';

      final List<Object> params = [...data.values];
      if (whereParams != null) {
        params.addAll(whereParams);
      }

      final Results results = await _connection!.query(sql, params);
      return results.affectedRows ?? 0;
    } catch (e) {
      print('Erreur lors de la mise à jour de données: $e');
      rethrow;
    }
  }

  // Méthode pour exécuter une requête DELETE
  Future<int> delete(String table, String where, [List<Object>? whereParams]) async {
    try {
      if (!_isConnected || _connection == null) {
        await connect();
      }

      final String sql = 'DELETE FROM $table WHERE $where';
      final Results results = await _connection!.query(sql, whereParams);
      return results.affectedRows ?? 0;
    } catch (e) {
      print('Erreur lors de la suppression de données: $e');
      rethrow;
    }
  }

  // Méthode pour convertir une ligne de résultat en Map
  Map<String, dynamic> _convertResultRow(ResultRow row) {
    final Map<String, dynamic> result = {};
    for (final field in row.fields.keys) {
      result[field] = row[field];
    }
    return result;
  }
}
