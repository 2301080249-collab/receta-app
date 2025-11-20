import 'dart:convert'; // 👈 AGREGAR ESTE IMPORT
import 'api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/curso.dart';

/// Servicio para operaciones con cursos
class CursoService {
  /// Crear curso (ADMIN)
  static Future<Map<String, dynamic>> crearCurso({
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
    final response = await ApiService.post(
      ApiConstants.crearCurso,
      headers: ApiConstants.headersWithAuth(token),
      body: {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'docente_id': docenteId,
        'ciclo_id': cicloId,
        'nivel': nivel,
        if (seccion != null) 'seccion': seccion,
        'creditos': creditos,
        if (horario != null) 'horario': horario,
      },
    );

    return ApiService.handleResponse(response);
  }

  /// Listar todos los cursos (ADMIN)
  static Future<List<Curso>> listarCursos(String token) async {
    final response = await ApiService.get(
      ApiConstants.cursosAdmin,
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;
    
    print('🎯 [CursoService.listarCursos] data.length: ${data.length}');
    if (data.isNotEmpty) {
      print('🎯 [CursoService.listarCursos] Primer item completo: ${data[0]}');
      print('🎯 [CursoService.listarCursos] Tiene ciclos?: ${data[0]['ciclos']}');
    }
    
    return data.map((json) => Curso.fromJson(json)).toList();
  }

  /// Listar cursos por ciclo (ADMIN)
  static Future<List<Curso>> listarCursosPorCiclo(
    String token,
    String cicloId,
  ) async {
    final response = await ApiService.get(
      '${ApiConstants.cursosAdmin}?ciclo_id=$cicloId',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;
    return data.map((json) => Curso.fromJson(json)).toList();
  }

  /// Listar cursos por docente (ADMIN)
  static Future<List<Curso>> listarCursosPorDocente(
    String token,
    String docenteId,
  ) async {
    final response = await ApiService.get(
      '${ApiConstants.cursosAdmin}?docente_id=$docenteId',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;
    return data.map((json) => Curso.fromJson(json)).toList();
  }

  /// Obtener curso por ID (ADMIN)
  static Future<Curso> obtenerCursoPorId(String token, String cursoId) async {
    final response = await ApiService.get(
      '${ApiConstants.cursosAdmin}/$cursoId',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response);
    return Curso.fromJson(data);
  }

  /// Actualizar curso (ADMIN)
  static Future<void> actualizarCurso({
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
    final body = <String, dynamic>{};

    if (nombre != null) body['nombre'] = nombre;
    if (descripcion != null) body['descripcion'] = descripcion;
    if (docenteId != null) body['docente_id'] = docenteId;
    if (cicloId != null) body['ciclo_id'] = cicloId;
    if (nivel != null) body['nivel'] = nivel;
    if (seccion != null) body['seccion'] = seccion;
    if (creditos != null) body['creditos'] = creditos;
    if (horario != null) body['horario'] = horario;
    if (activo != null) body['activo'] = activo;

    final response = await ApiService.patch(
      '${ApiConstants.cursosAdmin}/$cursoId',
      headers: ApiConstants.headersWithAuth(token),
      body: body,
    );

    ApiService.handleResponse(response);
  }

  /// Eliminar curso (ADMIN)
  static Future<void> eliminarCurso(String token, String cursoId) async {
    final response = await ApiService.delete(
      '${ApiConstants.cursosAdmin}/$cursoId',
      headers: ApiConstants.headersWithAuth(token),
    );

    // ✅ VALIDACIÓN: Capturar error 400 (curso con matrículas)
    if (response.statusCode == 400) {
      final data = json.decode(response.body);
      final errorMessage = data['error'] ?? 'No se puede eliminar este curso';
      throw Exception(errorMessage);
    }

    ApiService.handleResponse(response);
  }

  /// Activar curso (ADMIN)
  static Future<void> activarCurso(String token, String cursoId) async {
    final response = await ApiService.post(
      '${ApiConstants.cursosAdmin}/$cursoId/activar',
      headers: ApiConstants.headersWithAuth(token),
      body: {},
    );

    ApiService.handleResponse(response);
  }

  /// Desactivar curso (ADMIN)
  static Future<void> desactivarCurso(String token, String cursoId) async {
    final response = await ApiService.post(
      '${ApiConstants.cursosAdmin}/$cursoId/desactivar',
      headers: ApiConstants.headersWithAuth(token),
      body: {},
    );

    ApiService.handleResponse(response);
  }

  // ==================== OBTENER CURSOS POR ESTUDIANTE ✨ ====================
  
  /// Obtener cursos matriculados del estudiante
  static Future<List<Curso>> getCursosByEstudiante(
    String token,
    String estudianteId,
  ) async {
    final response = await ApiService.get(
      '/api/estudiantes/$estudianteId/cursos',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;
    return data.map((json) => Curso.fromJson(json)).toList();
  }
}