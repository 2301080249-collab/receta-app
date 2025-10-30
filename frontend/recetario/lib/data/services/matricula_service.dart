import '../models/matricula.dart';
import '../models/usuario.dart';
import '../repositories/matricula_repository.dart';

/// Servicio para operaciones con matrículas
class MatriculaService {
  static final MatriculaRepository _repository = MatriculaRepository();

  // ==================== CREAR MATRÍCULA ====================

  static Future<Matricula> crearMatricula({
    required String token,
    required String estudianteId,
    required String cursoId,
    required String cicloId,
    String? estado,           // ✅ NUEVO
    String? observaciones,    // ✅ NUEVO
  }) async {
    final request = CrearMatriculaRequest(
      estudianteId: estudianteId,
      cursoId: cursoId,
      cicloId: cicloId,
      estado: estado,           // ✅ NUEVO
      observaciones: observaciones,  // ✅ NUEVO
    );

    return await _repository.crearMatricula(token: token, request: request);
  }

  // ==================== CREAR MATRÍCULA MASIVA ====================

  static Future<Map<String, dynamic>> crearMatriculaMasiva({
    required String token,
    required List<String> estudiantesIds,
    required String cursoId,
    required String cicloId,
    String? estado,           // ✅ NUEVO
    String? observaciones,    // ✅ NUEVO
  }) async {
    final request = MatriculaMasivaRequest(
      estudiantesIds: estudiantesIds,
      cursoId: cursoId,
      cicloId: cicloId,
      estado: estado,           // ✅ NUEVO
      observaciones: observaciones,  // ✅ NUEVO
    );

    return await _repository.crearMatriculaMasiva(
      token: token,
      request: request,
    );
  }

  // ==================== LISTAR TODAS LAS MATRÍCULAS ====================

  static Future<List<Matricula>> listarTodasLasMatriculas({
    required String token,
  }) async {
    try {
      // 🔍 DEBUG: Antes de llamar al repository
      print('=== 🚀 INICIANDO PETICIÓN DE MATRÍCULAS ===');
      
      final matriculas = await _repository.listarTodasLasMatriculas(token: token);
      
      // 🔍 DEBUG: Después de recibir respuesta
      print('=== ✅ MATRÍCULAS RECIBIDAS ===');
      print('Total: ${matriculas.length}');
      if (matriculas.isNotEmpty) {
        print('Primera matrícula: ${matriculas[0].toJson()}');
        print('Nombre estudiante: ${matriculas[0].nombreEstudiante}');
        print('Nombre curso: ${matriculas[0].nombreCurso}');
        print('Observaciones: ${matriculas[0].observaciones}');  // ✅ NUEVO DEBUG
      }
      print('================================');
      
      return matriculas;
    } catch (e, stackTrace) {
      print('❌ ERROR EN SERVICE: $e');
      print('❌ STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  // ==================== LISTAR MATRÍCULAS POR CURSO ====================

  static Future<List<Matricula>> listarMatriculasPorCurso({
    required String token,
    required String cursoId,
  }) async {
    return await _repository.listarMatriculasPorCurso(
      token: token,
      cursoId: cursoId,
    );
  }

  // ==================== LISTAR MATRÍCULAS POR ESTUDIANTE ====================

  static Future<List<Matricula>> listarMatriculasPorEstudiante({
    required String token,
    required String estudianteId,
  }) async {
    return await _repository.listarMatriculasPorEstudiante(
      token: token,
      estudianteId: estudianteId,
    );
  }

  // ==================== LISTAR ESTUDIANTES DISPONIBLES ====================

  static Future<List<Usuario>> listarEstudiantesDisponibles({
    required String token,
    required String cursoId,
    required String cicloId,
  }) async {
    return await _repository.listarEstudiantesDisponibles(
      token: token,
      cursoId: cursoId,
      cicloId: cicloId,
    );
  }

  // ==================== ACTUALIZAR MATRÍCULA ====================

  static Future<void> actualizarMatricula({
    required String token,
    required String matriculaId,
    String? estado,
    double? notaFinal,
    String? observaciones,    // ✅ NUEVO
  }) async {
    final request = ActualizarMatriculaRequest(
      estado: estado,
      notaFinal: notaFinal,
      observaciones: observaciones,  // ✅ NUEVO
    );

    await _repository.actualizarMatricula(
      token: token,
      matriculaId: matriculaId,
      request: request,
    );
  }

  // ==================== ELIMINAR MATRÍCULA ====================

  static Future<void> eliminarMatricula({
    required String token,
    required String matriculaId,
  }) async {
    await _repository.eliminarMatricula(token: token, matriculaId: matriculaId);
  }
}