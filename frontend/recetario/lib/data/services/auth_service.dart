import 'api_service.dart';
import '../../core/constants/api_constants.dart';

/// Servicio de autenticación
class AuthService {
  /// Login de usuario
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await ApiService.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );

    final data = ApiService.handleResponse(response);

    return {
      'user': data['user'],
      'token': data['token'],
      'primera_vez': data['primera_vez'] ?? false,
    };
  }

  /// Cambiar contraseña
  static Future<void> changePassword({
    required String userId,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConstants.cambiarPassword,
        headers: ApiConstants.headersWithAuth(token),
        body: {'user_id': userId, 'new_password': newPassword},
      );

      final data = ApiService.handleResponse(response);

      // Verificar si hay error en la respuesta
      if (data != null && data['error'] != null) {
        throw Exception(data['error']);
      }
    } catch (e) {
      // Re-lanzar el error con un mensaje más descriptivo
      throw Exception('Error al cambiar contraseña: ${e.toString()}');
    }
  }

  /// ✅ NUEVO: Omitir cambio de contraseña
  static Future<void> skipPasswordChange({
    required String userId,
    required String token,
  }) async {
    final response = await ApiService.patch(
      ApiConstants.omitirCambioPassword,
      headers: ApiConstants.headersWithAuth(token),
      body: {'user_id': userId},
    );

    ApiService.handleResponse(response);
  }

  /// Verificar token
  static Future<bool> verifyToken(String token) async {
    try {
      final response = await ApiService.get(
        ApiConstants.verificarToken,
        headers: ApiConstants.headersWithAuth(token),
      );
      ApiService.handleResponse(response);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== ✅ NUEVOS MÉTODOS: OBTENER DATOS POR ROL ====================

  /// Obtener datos del docente autenticado
  static Future<Map<String, dynamic>> getDocenteData(String token) async {
    final response = await ApiService.get(
      ApiConstants.perfilDocente,
      headers: ApiConstants.headersWithAuth(token),
    );

    return ApiService.handleResponse(response);
  }

  /// Obtener datos del estudiante autenticado
  static Future<Map<String, dynamic>> getEstudianteData(String token) async {
    final response = await ApiService.get(
      ApiConstants.perfilEstudiante,
      headers: ApiConstants.headersWithAuth(token),
    );

    return ApiService.handleResponse(response);
  }

  /// Obtener datos del administrador autenticado
  static Future<Map<String, dynamic>> getAdministradorData(String token) async {
    final response = await ApiService.get(
      ApiConstants.perfilAdmin,
      headers: ApiConstants.headersWithAuth(token),
    );

    return ApiService.handleResponse(response);
  }
}