import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cliente HTTP muy simple para hablar con el backend FastAPI.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Cambia esta URL si corres el backend en otra máquina o puerto.
  static const String baseUrl = 'http://localhost:8000';

  Future<List<dynamic>> getJsonList(String path,
      {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final resp = await _client.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) return decoded;
      throw Exception('Respuesta inesperada (se esperaba lista)');
    }

    String message = 'Error ${resp.statusCode} al llamar $path';
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}

    throw ApiException(message);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body,
      {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Respuesta inesperada (se esperaba objeto)');
    }

    String message = 'Error ${resp.statusCode} al llamar $path';
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {}

    throw ApiException(message);
  }
}

/// Mapea la `Casa` del front al `sedeId` usado en Mongo/Backend.
String mapCasaToSedeId(String casaNombre) {
  switch (casaNombre) {
    case 'Casa Principal':
      return 'CASA_PRINCIPAL';
    case 'Casa Ángeles':
      return 'CASA_ANGELES';
    case 'Casa Esperanza':
      return 'CASA_ESPERANZA';
    case 'Casa Estrellas':
      return 'CASA_ESTRELLAS';
    case 'Casa Sueños':
      return 'CASA_SUENOS';
    default:
      return 'CASA_PRINCIPAL';
  }
}
