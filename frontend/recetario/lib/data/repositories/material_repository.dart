import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/material.dart' as models;
import '../services/material_service.dart';
import '../../core/utils/token_manager.dart';
import '../../config/env.dart';

class MaterialRepository {
  Future<List<models.Material>> getMaterialesByTemaId(String temaId) async {
    return await MaterialService.getMaterialesByTemaId(temaId);
  }

  Future<models.Material> crearMaterial(models.Material material) async {
    return await MaterialService.crearMaterial(material);
  }

  // ✅ NUEVO: Actualizar material
  Future<models.Material> actualizarMaterial(models.Material material) async {
    return await MaterialService.actualizarMaterial(material);
  }

  Future<void> eliminarMaterial(String materialId) async {
    return await MaterialService.eliminarMaterial(materialId);
  }

  Future<void> marcarComoVisto(String materialId) async {
    return await MaterialService.marcarComoVisto(materialId);
  }

  // Subir archivo (compatible con Web y Móvil)
  Future<Map<String, dynamic>> subirArchivo({
    File? archivo, // Para móvil/desktop
    Uint8List? bytes, // Para web
    required String nombreArchivo,
    required String temaId,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final uri = Uri.parse('${Env.backendUrl}/api/materiales/upload');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['tema_id'] = temaId;

      // Determinar si es Web o Móvil
      if (kIsWeb) {
        // WEB: Usar bytes
        if (bytes == null) {
          throw Exception('Se requieren los bytes del archivo para web');
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: nombreArchivo,
          ),
        );
      } else {
        // MÓVIL/DESKTOP: Usar archivo
        if (archivo == null) {
          throw Exception('Se requiere el archivo para móvil');
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            archivo.path,
            filename: nombreArchivo,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'url': data['data']['url'],
          'size_mb': data['data']['size_mb'],
        };
      } else {
        throw Exception('Error al subir archivo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en subirArchivo: $e');
    }
  }
}