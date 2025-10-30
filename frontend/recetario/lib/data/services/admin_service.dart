import 'api_service.dart';
import '../../core/constants/api_constants.dart';

/// Servicio de operaciones de administrador
class AdminService {
  /// Crear usuario
  static Future<void> crearUsuario({
    required String token,
    required String nombreCompleto,
    required String email,
    required String codigo,
    required String rol,
    String? telefono,
    String? ciclo,
    String? seccion,
    String? especialidad,
    String? gradoAcademico,
    String? departamento,
  }) async {
    final response = await ApiService.post(
      ApiConstants.crearUsuario,
      headers: ApiConstants.headersWithAuth(token),
      body: {
        'nombre_completo': nombreCompleto,
        'email': email,
        'codigo': codigo,
        'rol': rol,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        if (ciclo != null) 'ciclo': ciclo, // ✅ Ya viene como string del número entero
        if (seccion != null) 'seccion': seccion,
        if (especialidad != null) 'especialidad': especialidad,
        if (gradoAcademico != null) 'grado_academico': gradoAcademico,
        if (departamento != null) 'departamento': departamento,
      },
    );

    ApiService.handleResponse(response);
  }

  /// Obtener lista de usuarios
  static Future<List<dynamic>> obtenerUsuarios(String token) async {
    final response = await ApiService.get(
      ApiConstants.listarUsuarios,
      headers: ApiConstants.headersWithAuth(token),
    );

    return ApiService.handleResponse(response);
  }

  /// Eliminar usuario
  static Future<void> eliminarUsuario(String token, String userId) async {
    final response = await ApiService.delete(
      '${ApiConstants.eliminarUsuario}/$userId',
      headers: ApiConstants.headersWithAuth(token),
    );

    ApiService.handleResponse(response);
  }

  /// Obtener estadísticas del dashboard
  static Future<Map<String, dynamic>> obtenerEstadisticas(String token) async {
    final response = await ApiService.get(
      ApiConstants.dashboardStats,
      headers: ApiConstants.headersWithAuth(token),
    );

    return ApiService.handleResponse(response);
  }

  /// Obtener usuario por ID
  static Future<Map<String, dynamic>> obtenerUsuarioPorId(
    String token,
    String userId,
  ) async {
    final response = await ApiService.get(
      '${ApiConstants.listarUsuarios}/$userId',
      headers: ApiConstants.headersWithAuth(token),
    );

    return ApiService.handleResponse(response);
  }

  /// Editar usuario
  static Future<void> editarUsuario({
    required String token,
    required String userId,
    required Map<String, dynamic> datosActualizados,
  }) async {
    final response = await ApiService.put(
      '${ApiConstants.editarUsuario}/$userId',
      headers: ApiConstants.headersWithAuth(token),
      body: datosActualizados,
    );

    ApiService.handleResponse(response);
  }

  /// Actualizar usuario (para modo edición completo)
  static Future<void> actualizarUsuario({
    required String token,
    required String id,
    required String nombreCompleto,
    required String email,
    required String codigo,
    required String telefono,
    required String rol,
    String? ciclo,
    String? seccion,
    String? especialidad,
    String? gradoAcademico,
    String? departamento,
  }) async {
    final response = await ApiService.put(
      '${ApiConstants.editarUsuario}/$id',
      headers: ApiConstants.headersWithAuth(token),
      body: {
        'nombre_completo': nombreCompleto,
        'email': email,
        'codigo': codigo,
        'telefono': telefono,
        'rol': rol,
        if (ciclo != null) 'ciclo': ciclo, // ✅ Ya viene como string del número entero
        if (seccion != null) 'seccion': seccion,
        if (especialidad != null) 'especialidad': especialidad,
        if (gradoAcademico != null) 'grado_academico': gradoAcademico,
        if (departamento != null) 'departamento': departamento,
      },
    );

    ApiService.handleResponse(response);
  }
}