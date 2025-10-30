import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../../core/constants/api_constants.dart';

/// Cliente HTTP base para todas las peticiones
class ApiService {
  static String get baseUrl => Env.backendUrl;

  /// GET request
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.get(uri, headers: headers ?? ApiConstants.headersJson());
  }

  /// POST request
  static Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      uri,
      headers: headers ?? ApiConstants.headersJson(),
      body: jsonEncode(body),
    );
  }

  /// ✅ NUEVO: PATCH request
  static Future<http.Response> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.patch(
      uri,
      headers: headers ?? ApiConstants.headersJson(),
      body: jsonEncode(body),
    );
  }

  /// PUT request
  static Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.put(
      uri,
      headers: headers ?? ApiConstants.headersJson(),
      body: jsonEncode(body),
    );
  }

  /// DELETE request
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.delete(
      uri,
      headers: headers ?? ApiConstants.headersJson(),
    );
  }

  /// Manejar respuesta genérica
 /// Manejar respuesta genérica
static dynamic handleResponse(http.Response response) {
  // 🔍 DEBUG
  print('=== 🔧 HANDLE RESPONSE ===');
  print('Status Code: ${response.statusCode}');
  print('Body length: ${response.body.length}');
  print('Body: ${response.body}');
  print('=========================');
  
  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) return null;
    
    final decoded = jsonDecode(response.body);
    
    // 🔍 DEBUG
    print('=== 🎯 DECODED DATA ===');
    print('Type: ${decoded.runtimeType}');
    print('Is List: ${decoded is List}');
    if (decoded is List) {
      print('Length: ${decoded.length}');
      if (decoded.isNotEmpty) {
        print('Primer item: ${decoded[0]}');
      }
    } else if (decoded is Map) {
      print('Keys: ${decoded.keys}');
    }
    print('======================');
    
    return decoded;
  } else {
    print('❌ ERROR STATUS: ${response.statusCode}');
    print('❌ ERROR BODY: ${response.body}');
    final error = jsonDecode(response.body);
    throw Exception(
      error['error'] ?? error['message'] ?? 'Error en la petición',
    );
  }
}
}
