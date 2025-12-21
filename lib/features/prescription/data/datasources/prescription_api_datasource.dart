// Fichier: lib/features/prescription/data/datasources/prescription_api_datasource.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/config/api_config.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../../domain/entities/prescription.dart';

/// Interface du DataSource pour ton backend Node.js
abstract class PrescriptionApiDataSource {
  void setAuthToken(String token);
  Future<List<PrescriptionModel>> getAllPrescriptions();
  Future<PrescriptionModel> getPrescriptionById(String id);
  Future<String> createPrescription(PrescriptionModel prescription, {File? ordonnancePhoto});
  Future<bool> updatePrescription(PrescriptionModel prescription);
  Future<bool> deletePrescription(String id);
}

/// Implémentation avec ton backend Node.js (HTTP)
class PrescriptionApiDataSourceImpl implements PrescriptionApiDataSource {
  final http.Client httpClient;
  final String baseUrl;
  String? _authToken;

  PrescriptionApiDataSourceImpl({
    required this.httpClient,
    this.baseUrl = ApiConfig.baseUrl,
  });

  /// Setter pour le token d'authentification
  @override
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Headers avec authentification
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  @override
  Future<List<PrescriptionModel>> getAllPrescriptions() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/client/commandes'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PrescriptionModel.fromBackendJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Non authentifié');
      } else {
        throw ServerException('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Erreur lors de la récupération des prescriptions: $e');
    }
  }

  @override
  Future<PrescriptionModel> getPrescriptionById(String id) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/client/commandes/$id/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrescriptionModel.fromBackendJson(data);
      } else if (response.statusCode == 404) {
        throw ServerException('Prescription non trouvée');
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Non authentifié');
      } else {
        throw ServerException('Erreur serveur: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Erreur lors de la récupération de la prescription: $e');
    }
  }

  @override
  Future<String> createPrescription(
    PrescriptionModel prescription, {
    File? ordonnancePhoto,
  }) async {
    try {
      // Créer une requête multipart pour uploader l'image
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/client/commandes'),
      );

      // Ajouter les headers
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Ajouter les données JSON
      final commandeData = {
        'type_commande': ordonnancePhoto != null ? 'ordonnance_photo' : 'saisie_manuelle',
        'localisation_client_latitude': 0.0, // À remplacer par la vraie géolocalisation
        'localisation_client_longitude': 0.0,
        'localisation_timestamp': DateTime.now().toIso8601String(),
        'produits': prescription.medications.map((med) {
          return {
            'produit_id': int.tryParse(med.medication.id) ?? 0,
            'quantite': 1,
          };
        }).toList(),
      };

      request.fields['data'] = json.encode(commandeData);

      // Ajouter la photo si présente
      if (ordonnancePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'ordonnance_photo',
            ordonnancePhoto.path,
          ),
        );
      }

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['commande']['id'].toString();
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Non authentifié');
      } else {
        final error = json.decode(response.body);
        throw ServerException('Erreur création: ${error['error']}');
      }
    } on SocketException {
      throw NetworkException('Pas de connexion internet');
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Erreur lors de la création: $e');
    }
  }

  @override
  Future<bool> updatePrescription(PrescriptionModel prescription) async {
    try {
      // Ton backend n'a pas de route PUT pour les commandes
      // Tu peux l'ajouter ou utiliser une autre logique
      throw UnimplementedError('Mise à jour non implémentée dans le backend');
    } catch (e) {
      throw ServerException('Erreur mise à jour: $e');
    }
  }

  @override
  Future<bool> deletePrescription(String id) async {
    try {
      // Ton backend n'a pas de route DELETE pour les commandes
      // Tu peux l'ajouter ou utiliser une autre logique
      throw UnimplementedError('Suppression non implémentée dans le backend');
    } catch (e) {
      throw ServerException('Erreur suppression: $e');
    }
  }
}
