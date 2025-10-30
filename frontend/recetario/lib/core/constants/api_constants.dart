/// Constantes para endpoints y configuración de API
class ApiConstants {
  // ==================== BASE PATHS ====================
  static const String auth = '/api/auth';
  static const String admin = '/api/admin';
  static const String estudiante = '/api/estudiante';
  static const String docente = '/api/docente';

  // ==================== AUTENTICACIÓN ====================
  static const String login = '$auth/login';
  static const String cambiarPassword = '$auth/cambiar-password';
  static const String verificarToken = '$auth/verify';
  static const String omitirCambioPassword = '$auth/omitir-cambio-password';

  // ==================== ✅ PERFIL POR ROL ====================
  static const String perfilDocente = '$docente/perfil';
  static const String perfilEstudiante = '$estudiante/perfil';
  static const String perfilAdmin = '$admin/perfil';

  // ==================== USUARIOS (ADMIN) ====================
  static const String crearUsuario = '$admin/crear-usuario';
  static const String listarUsuarios = '$admin/usuarios';
  static const String eliminarUsuario = '$admin/usuarios'; // + /:id
  static const String editarUsuario = '$admin/usuarios'; // + /:id

  // ==================== CICLOS ====================
  static const String crearCiclo = '$admin/ciclos';
  static const String listarCiclos = '$admin/ciclos';

  // ==================== CURSOS ====================
  // ✅ Para admin (CRUD completo)
  static const String cursosAdmin = '$admin/cursos';
  static const String crearCurso = '$admin/cursos';
  static const String listarCursosAdmin = '$admin/cursos';
  
  // ✅ Para estudiantes/docentes (solo lectura)
  static const String cursos = '/api/cursos';

  // ==================== MATRÍCULAS ====================
  static const String matriculas = '$admin/matriculas';
  static const String crearMatricula = '$admin/matriculas';
  static const String crearMatriculaMasiva = '$admin/matriculas/masiva';
  static const String estudiantesDisponibles = '$admin/matriculas/disponibles';

  // ==================== TEMAS ✨ ====================
  static const String temas = '/api/temas';
  
  // ==================== MATERIALES ✨ ====================
  static const String materiales = '/api/materiales';
  static const String materialesUpload = '/api/materiales/upload';
  
  // ==================== TAREAS ✨ ====================
  static const String tareas = '/api/tareas';
  
  // ==================== ENTREGAS ✨ ====================
  static const String entregas = '/api/entregas';

  // ==================== ESTADÍSTICAS ====================
  static const String estadisticas = '$admin/estadisticas';
  static const String dashboardStats = '$admin/dashboard/stats';

  // ==================== RECETAS (FUTURO) ====================
  static const String recetas = '/recetas';
  static const String crearReceta = '/recetas';
  static const String listarRecetas = '/recetas';

  // ==================== CATEGORÍAS (FUTURO) ====================
  static const String categorias = '/categorias';

  // ==================== HEADERS ====================

  /// Headers básicos para peticiones JSON
  static Map<String, String> headersJson() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  /// Headers con token de autenticación
  static Map<String, String> headersWithAuth(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Headers para multipart (archivos)
  static Map<String, String> headersMultipart(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  // ==================== TIMEOUTS ====================
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ==================== CÓDIGOS DE RESPUESTA ====================
  static const int ok = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}