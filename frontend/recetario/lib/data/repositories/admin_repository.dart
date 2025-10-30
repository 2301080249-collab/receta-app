import '../services/admin_service.dart';

/// Repository para operaciones de administración
/// Responsabilidad: Orquestar llamadas a AdminService y manejar lógica de negocio
class AdminRepository {
  // ==================== USUARIOS ====================

  /// Crear nuevo usuario (estudiante, docente o admin)
  Future<void> crearUsuario({
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
    await AdminService.crearUsuario(
      token: token,
      nombreCompleto: nombreCompleto,
      email: email,
      codigo: codigo,
      rol: rol,
      telefono: telefono,
      ciclo: ciclo != null ? _cicloRomanoAEntero(ciclo).toString() : null, // ✅ CONVERTIR A ENTERO
      seccion: seccion,
      especialidad: especialidad,
      gradoAcademico: gradoAcademico,
      departamento: departamento,
    );
  }

  /// Obtener lista de todos los usuarios
  Future<List<dynamic>> obtenerUsuarios(String token) async {
    return await AdminService.obtenerUsuarios(token);
  }

  /// Obtener usuario por ID
  Future<Map<String, dynamic>> obtenerUsuarioPorId(
    String userId,
    String token,
  ) async {
    return await AdminService.obtenerUsuarioPorId(token, userId);
  }

  /// Eliminar usuario
  Future<void> eliminarUsuario(String userId, String token) async {
    return await AdminService.eliminarUsuario(token, userId);
  }

  /// Editar usuario
  Future<void> editarUsuario({
    required String userId,
    required String token,
    String? nombreCompleto,
    String? email,
    Map<String, dynamic>? datosAdicionales,
  }) async {
    final Map<String, dynamic> datos = {
      if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
      if (email != null) 'email': email,
      if (datosAdicionales != null) ...datosAdicionales,
    };

    return await AdminService.editarUsuario(
      token: token,
      userId: userId,
      datosActualizados: datos,
    );
  }

  /// Actualizar usuario existente
  Future<void> actualizarUsuario({
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
    return await AdminService.actualizarUsuario(
      token: token,
      id: id,
      nombreCompleto: nombreCompleto,
      email: email,
      codigo: codigo,
      telefono: telefono,
      rol: rol,
      ciclo: ciclo != null ? _cicloRomanoAEntero(ciclo).toString() : null, // ✅ CONVERTIR A ENTERO
      seccion: seccion,
      especialidad: especialidad,
      gradoAcademico: gradoAcademico,
      departamento: departamento,
    );
  }

  // ==================== ESTADÍSTICAS (DASHBOARD) ====================

  /// Obtener estadísticas del dashboard
  Future<Map<String, dynamic>> obtenerEstadisticas(String token) async {
    return await AdminService.obtenerEstadisticas(token);
  }

  // ==================== CICLOS (FUTURO) ====================

  /// Crear ciclo académico
  Future<void> crearCiclo({
    required String nombre,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required int duracionSemanas,
    required String token,
  }) async {
    throw UnimplementedError('Función en desarrollo');
  }

  /// Obtener ciclos
  Future<List<dynamic>> obtenerCiclos(String token) async {
    throw UnimplementedError('Función en desarrollo');
  }

  // ==================== CURSOS (FUTURO) ====================

  /// Crear curso
  Future<void> crearCurso({
    required String nombre,
    required String descripcion,
    required String docenteId,
    required String cicloId,
    required String token,
  }) async {
    throw UnimplementedError('Función en desarrollo');
  }

  /// Obtener cursos
  Future<List<dynamic>> obtenerCursos(String token) async {
    throw UnimplementedError('Función en desarrollo');
  }

  // ==================== UTILIDADES ====================

  /// Convierte número romano (I-X) a entero (1-10)
  int _cicloRomanoAEntero(String? ciclo) {
    const mapa = {
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8,
      'IX': 9,
      'X': 10,
    };
    return mapa[ciclo ?? 'I'] ?? 1;
  }
}