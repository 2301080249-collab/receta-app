import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../../core/utils/token_manager.dart';

/// Servicio para manejar notificaciones y compartir recetas
class NotificationService {
  /// Obtener lista de usuarios para compartir
  Future<List<Map<String, dynamic>>> obtenerUsuariosParaCompartir() async {
    try {
      final token = await TokenManager.getToken();
      
      print('🔑 Token obtenido: ${token?.substring(0, 20)}...'); 
      
      final response = await ApiService.get(
        '/api/usuarios/para-compartir',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = ApiService.handleResponse(response);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      
      return [];
    } catch (e) {
      print('❌ Error obteniendo usuarios: $e');
      rethrow;
    }
  }

  /// Compartir receta con usuarios
  /// [mensaje] es opcional - si no se proporciona, se usa un mensaje por defecto
  Future<void> compartirReceta({
    required String recetaId,
    required List<String> usuariosIds,
    String? mensaje, // 🆕 Parámetro opcional para mensaje personalizado
  }) async {
    try {
      final token = await TokenManager.getToken();
      
      final body = {
        'receta_id': recetaId,
        'usuarios_ids': usuariosIds,
      };
      
      // 🆕 Solo agregar mensaje si existe y no está vacío
      if (mensaje != null && mensaje.isNotEmpty) {
        body['mensaje'] = mensaje;
      }
      
      final response = await ApiService.post(
        '/api/notificaciones/compartir-receta',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      ApiService.handleResponse(response);
      print('✅ Receta compartida exitosamente');
    } catch (e) {
      print('❌ Error compartiendo receta: $e');
      rethrow;
    }
  }

  /// Obtener notificaciones del usuario actual
  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await ApiService.get(
        '/api/notificaciones/mis-notificaciones',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = ApiService.handleResponse(response);
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      
      return [];
    } catch (e) {
      print('❌ Error obteniendo notificaciones: $e');
      rethrow;
    }
  }

  /// Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await ApiService.patch(
        '/api/notificaciones/$notificacionId/leer',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {},
      );

      ApiService.handleResponse(response);
      print('✅ Notificación marcada como leída');
    } catch (e) {
      print('❌ Error marcando notificación: $e');
      rethrow;
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await ApiService.patch(
        '/api/notificaciones/leer-todas',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {},
      );

      ApiService.handleResponse(response);
      print('✅ Todas las notificaciones marcadas como leídas');
    } catch (e) {
      print('❌ Error marcando todas las notificaciones: $e');
      rethrow;
    }
  }

  /// Registrar token FCM del dispositivo en el backend
  Future<void> registrarTokenFCM(String fcmToken) async {
    try {
      final token = await TokenManager.getToken();
      
      final response = await ApiService.post(
        '/api/notificaciones/registrar-dispositivo',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'fcm_token': fcmToken,
          'plataforma': 'mobile',
        },
      );

      ApiService.handleResponse(response);
      print('✅ Token FCM registrado en backend');
    } catch (e) {
      print('❌ Error registrando token FCM: $e');
      rethrow;
    }
  }
}