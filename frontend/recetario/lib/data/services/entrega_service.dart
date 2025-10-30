import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/entrega.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';
import 'token_service.dart';
import 'storage_service.dart';

class EntregaService {
  // Crear entrega (estudiante)
  static Future<Entrega> crearEntrega({
    required String tareaId,
    required String titulo,
    String? descripcion,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.post(
        ApiConstants.entregas,
        headers: ApiConstants.headersWithAuth(token),
        body: {
          'tarea_id': tareaId,
          'titulo': titulo,
          'descripcion': descripcion,
        },
      );

      final data = ApiService.handleResponse(response);
      return Entrega.fromJson(data);
    } catch (e) {
      throw Exception('Error al crear entrega: $e');
    }
  }

  // Subir archivo a entrega (FUNCIONA EN WEB Y MÓVIL)
  static Future<ArchivoEntrega> subirArchivo({
    required String entregaId,
    required PlatformFile archivo,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final uri = Uri.parse(
        '${ApiService.baseUrl}${ApiConstants.entregas}/$entregaId/archivos',
      );

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Determinar el content type basado en la extensión
      final mimeType = lookupMimeType(archivo.name) ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);

      if (kIsWeb) {
        // WEB: Usar bytes
        if (archivo.bytes == null) {
          throw Exception('No se pudieron leer los bytes del archivo');
        }
        
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          archivo.bytes!,
          filename: archivo.name,
          contentType: mediaType,
        ));
      } else {
        // MÓVIL: Usar path
        if (archivo.path == null) {
          throw Exception('No se pudo obtener la ruta del archivo');
        }

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          archivo.path!,
          filename: archivo.name,
          contentType: mediaType,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ArchivoEntrega.fromJson(data);
      }
      
      throw Exception('Error al subir archivo: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  // ✅ NUEVO: Eliminar archivo individual
  static Future<void> eliminarArchivoEntrega(String archivoId, String urlArchivo) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      // 1. Eliminar del Storage
      try {
        final path = StorageService.extraerPathDeUrl(urlArchivo);
        await StorageService.eliminarArchivo(path);
      } catch (e) {
        print('⚠️ Advertencia: No se pudo eliminar del Storage: $e');
        // Continuar aunque falle el Storage
      }

      // 2. Eliminar registro de la base de datos
      final response = await ApiService.delete(
        '${ApiConstants.entregas}/archivos/$archivoId',
        headers: ApiConstants.headersWithAuth(token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar registro del archivo');
      }

      print('✅ Archivo eliminado exitosamente');
    } catch (e) {
      throw Exception('Error al eliminar archivo: $e');
    }
  }

  // Editar entrega (estudiante, solo si no está calificada)
  static Future<void> editarEntrega({
    required String entregaId,
    required String titulo,
    String? descripcion,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.put(
        '${ApiConstants.entregas}/$entregaId',
        headers: ApiConstants.headersWithAuth(token),
        body: {
          'titulo': titulo,
          'descripcion': descripcion,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al editar entrega');
      }
    } catch (e) {
      throw Exception('Error al editar entrega: $e');
    }
  }

  // ✅ MEJORADO: Eliminar entrega CON archivos del Storage
  static Future<void> eliminarEntrega(String entregaId, List<ArchivoEntrega>? archivos) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      // 1. Eliminar archivos del Storage primero
      if (archivos != null && archivos.isNotEmpty) {
        for (var archivo in archivos) {
          try {
            final path = StorageService.extraerPathDeUrl(archivo.urlArchivo);
            await StorageService.eliminarArchivo(path);
          } catch (e) {
            print('⚠️ No se pudo eliminar archivo del Storage: ${archivo.nombreArchivo}');
          }
        }
      }

      // 2. Eliminar entrega de la base de datos (esto eliminará en cascada los registros de archivos)
      final response = await ApiService.delete(
        '${ApiConstants.entregas}/$entregaId',
        headers: ApiConstants.headersWithAuth(token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar entrega');
      }

      print('✅ Entrega eliminada exitosamente');
    } catch (e) {
      throw Exception('Error al eliminar entrega: $e');
    }
  }

  // Obtener entrega por ID
  static Future<Entrega> getEntregaById(String entregaId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.get(
        '${ApiConstants.entregas}/$entregaId',
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      return Entrega.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener entrega: $e');
    }
  }
}