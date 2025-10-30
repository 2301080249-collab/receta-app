import '../services/auth_service.dart';

/// Repository para autenticación
/// Responsabilidad: Orquestar llamadas a AuthService y manejar lógica de negocio
class AuthRepository {
  // ==================== LOGIN ====================

  /// Iniciar sesión con email y contraseña
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await AuthService.login(email, password);
  }

  // ==================== CAMBIAR CONTRASEÑA ====================

  /// Cambiar contraseña (primera vez o reseteo)
  Future<void> changePassword({
    required String userId,
    required String token,
    required String newPassword,
  }) async {
    return await AuthService.changePassword(
      userId: userId,
      token: token,
      newPassword: newPassword,
    );
  }

  // ==================== ✅ NUEVO: OMITIR CAMBIO DE CONTRASEÑA ====================

  /// Omitir cambio de contraseña (actualizar primera_vez = false)
  Future<void> skipPasswordChange({
    required String userId,
    required String token,
  }) async {
    return await AuthService.skipPasswordChange(userId: userId, token: token);
  }

  // ==================== VERIFICAR SESIÓN ====================

  /// Verificar si el token es válido
  Future<bool> verifyToken(String token) async {
    return await AuthService.verifyToken(token);
  }

  // ==================== LOGOUT ====================

  /// Cerrar sesión
  Future<void> logout(String token) async {
    // Por ahora solo limpia el estado local en el provider
    // TODO: Implementar endpoint de logout en backend si es necesario
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // ==================== ✅ NUEVOS MÉTODOS: OBTENER DATOS POR ROL ====================

  /// Obtener datos completos del docente
  Future<Map<String, dynamic>> getDocenteData(String token) async {
    return await AuthService.getDocenteData(token);
  }

  /// Obtener datos completos del estudiante
  Future<Map<String, dynamic>> getEstudianteData(String token) async {
    return await AuthService.getEstudianteData(token);
  }

  /// Obtener datos completos del administrador
  Future<Map<String, dynamic>> getAdministradorData(String token) async {
    return await AuthService.getAdministradorData(token);
  }

  // ==================== RECUPERAR CONTRASEÑA (FUTURO) ====================

  /// Solicitar reseteo de contraseña por email
  Future<void> requestPasswordReset(String email) async {
    throw UnimplementedError('Función en desarrollo');
  }

  /// Confirmar reseteo de contraseña con código
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    throw UnimplementedError('Función en desarrollo');
  }
}