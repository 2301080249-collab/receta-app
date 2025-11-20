import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../../core/constants/api_constants.dart';

/// Cliente HTTP base para todas las peticiones
class ApiService {
  static String get baseUrl => Env.backendUrl;

  /// 🔧 Headers base con bypass de ngrok
  static Map<String, String> _getBaseHeaders([Map<String, String>? additionalHeaders]) {
    final headers = {
      'ngrok-skip-browser-warning': '69420', // ✅ Bypass de ngrok
      ...ApiConstants.headersJson(),
    };
    
    // ✅ Headers adicionales SOLO para web
    if (kIsWeb) {
      headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
    }
    
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  /// GET request
  static Future<http.Response> get(
  String endpoint, {
  Map<String, String>? headers,
}) async {
  final uri = Uri.parse('$baseUrl$endpoint');
  
  // ✅ LOG ANTES DE HACER LA PETICIÓN
  print('🌐 HTTP GET: $uri');
  print('⏰ Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
  
  final response = await http.get(uri, headers: _getBaseHeaders(headers));
  
  // ✅ LOG DESPUÉS DE RECIBIR RESPUESTA
  print('✅ HTTP GET Response: ${response.statusCode} - Body length: ${response.body.length}');
  
  return response;
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
      headers: _getBaseHeaders(headers),
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
      headers: _getBaseHeaders(headers),
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
      headers: _getBaseHeaders(headers),
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
      headers: _getBaseHeaders(headers),
    );
  }

  /// Manejar respuesta genérica
  static dynamic handleResponse(http.Response response) {
    // ✅ NUEVO: Filtrar logs de preflight/OPTIONS
    if (response.request?.method == 'OPTIONS') {
      return null; // Ignorar preflight
    }

    // 🔍 DEBUG - Solo loguear peticiones reales
    print('=== 🔧 HANDLE RESPONSE ===');
    print('Method: ${response.request?.method ?? "UNKNOWN"}');
    print('Status Code: ${response.statusCode}');
    print('Body length: ${response.body.length}');
    if (response.body.length < 500) {
      print('Body: ${response.body}');
    } else {
      print('Body: (demasiado largo - ${response.body.length} chars)');
    }
    print('=========================');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      
      final decoded = jsonDecode(response.body);
      
      // 🔍 DEBUG - Solo para listas y mapas
      if (decoded is List) {
        print('✅ Lista con ${decoded.length} elementos');
      } else if (decoded is Map) {
        print('✅ Mapa con ${decoded.keys.length} keys');
      }
      
      return decoded;
    } else {
      print('❌ ERROR STATUS: ${response.statusCode}');
      print('❌ ERROR BODY: ${response.body}');
      
      try {
        final error = jsonDecode(response.body);
        
        String errorMessage = 'Error en la petición';
        
        if (error['message'] != null) {
          errorMessage = error['message'].toString();
        } else if (error['error'] != null && error['error'] is String) {
          errorMessage = error['error'];
        }
        
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception(response.body);
      }
    }
  }
}