import '../services/curso_service.dart';
import '../models/curso.dart';
import '../services/token_service.dart';

/// Repository para operaciones de cursos
class CursoRepository {
  // ==================== CREAR CURSO ====================
  Future<Map<String, dynamic>> crearCurso({
    required String token,
    required String nombre,
    String? descripcion,
    required String docenteId,
    required String cicloId,
    required int nivel,
    String? seccion,
    required int creditos,
    String? horario,
  }) async {
    return await CursoService.crearCurso(
      token: token,
      nombre: nombre,
      descripcion: descripcion,
      docenteId: docenteId,
      cicloId: cicloId,
      nivel: nivel,
      seccion: seccion,
      creditos: creditos,
      horario: horario,
    );
  }

  // ==================== LISTAR CURSOS ====================
  Future<List<Curso>> listarCursos(String token) async {
    return await CursoService.listarCursos(token);
  }

  Future<List<Curso>> listarCursosPorCiclo(String token, String cicloId) async {
    return await CursoService.listarCursosPorCiclo(token, cicloId);
  }

  Future<List<Curso>> listarCursosPorDocente(
    String token,
    String docenteId,
  ) async {
    return await CursoService.listarCursosPorDocente(token, docenteId);
  }

  // ==================== OBTENER CURSO POR ID ====================
  Future<Curso> obtenerCursoPorId(String token, String cursoId) async {
    return await CursoService.obtenerCursoPorId(token, cursoId);
  }

  // ==================== ACTUALIZAR CURSO ====================
  Future<void> actualizarCurso({
    required String token,
    required String cursoId,
    String? nombre,
    String? descripcion,
    String? docenteId,
    String? cicloId,
    int? nivel,
    String? seccion,
    int? creditos,
    String? horario,
    bool? activo,
  }) async {
    return await CursoService.actualizarCurso(
      token: token,
      cursoId: cursoId,
      nombre: nombre,
      descripcion: descripcion,
      docenteId: docenteId,
      cicloId: cicloId,
      nivel: nivel,
      seccion: seccion,
      creditos: creditos,
      horario: horario,
      activo: activo,
    );
  }

  // ==================== ELIMINAR CURSO ====================
  Future<void> eliminarCurso(String token, String cursoId) async {
    return await CursoService.eliminarCurso(token, cursoId);
  }

  // ==================== ACTIVAR/DESACTIVAR ====================
  Future<void> activarCurso(String token, String cursoId) async {
    return await CursoService.activarCurso(token, cursoId);
  }

  Future<void> desactivarCurso(String token, String cursoId) async {
    return await CursoService.desactivarCurso(token, cursoId);
  }

  // ==================== OBTENER CURSOS DEL USUARIO ✨ ====================
  Future<List<Curso>> getCursosByEstudiante() async {
    final token = await TokenService.getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final userData = await TokenService.getUserData();
    if (userData == null) throw Exception('No se pudo obtener datos del usuario');

    final userId = userData['id'];  // ✅ CAMBIO AQUÍ - línea 102
    if (userId == null) throw Exception('Usuario sin ID');

    return await CursoService.getCursosByEstudiante(token, userId);
  }

  Future<List<Curso>> getCursosByDocente() async {
    final token = await TokenService.getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final userData = await TokenService.getUserData();
    if (userData == null) throw Exception('No se pudo obtener datos del usuario');

    final userId = userData['id'];  // ✅ CAMBIO AQUÍ - línea 112
    if (userId == null) throw Exception('Usuario sin ID');

    return await listarCursosPorDocente(token, userId);
  }
}