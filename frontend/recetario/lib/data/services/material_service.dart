import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import '../models/material.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';
import 'token_service.dart';

class MaterialService {
  // Crear material (docente)
  static Future<Material> crearMaterial(Material material) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.post(
        ApiConstants.materiales,
        headers: ApiConstants.headersWithAuth(token),
        body: material.toJson(),
      );

      final data = ApiService.handleResponse(response);
      return Material.fromJson(data);
    } catch (e) {
      throw Exception('Error al crear material: $e');
    }
  }

  // ✅ NUEVO: Actualizar material (docente)
  static Future<Material> actualizarMaterial(Material material) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.put(
        '${ApiConstants.materiales}/${material.id}',
        headers: ApiConstants.headersWithAuth(token),
        body: material.toJson(),
      );

      final data = ApiService.handleResponse(response);
      return Material.fromJson(data['data']);
    } catch (e) {
      throw Exception('Error al actualizar material: $e');
    }
  }

  // Subir archivo (docente)
  static Future<Map<String, dynamic>> subirArchivo({
    required File archivo,
    required String temaId,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final uri = Uri.parse('${ApiService.baseUrl}${ApiConstants.materialesUpload}');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['tema_id'] = temaId;
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        archivo.path,
        contentType: MediaType('application', 'octet-stream'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Error al subir archivo: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  // Listar materiales por tema (estudiante/docente)
  static Future<List<Material>> getMaterialesByTemaId(String temaId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.get(
        '${ApiConstants.temas}/$temaId/materiales',
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response) as List;
      return data.map((json) => Material.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener materiales: $e');
    }
  }

  // Marcar material como visto (estudiante)
  static Future<void> marcarComoVisto(String materialId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.post(
        '${ApiConstants.materiales}/$materialId/marcar-visto',
        headers: ApiConstants.headersWithAuth(token),
        body: {},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al marcar material como visto');
      }
    } catch (e) {
      throw Exception('Error al marcar material como visto: $e');
    }
  }

  // Eliminar material (docente)
  static Future<void> eliminarMaterial(String materialId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.delete(
        '${ApiConstants.materiales}/$materialId',
        headers: ApiConstants.headersWithAuth(token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar material');
      }
    } catch (e) {
      throw Exception('Error al eliminar material: $e');
    }
  }
}