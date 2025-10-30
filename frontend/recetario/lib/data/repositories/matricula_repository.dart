import '../models/matricula.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class MatriculaRepository {
  // ==================== CREAR MATRÍCULA ====================

  Future<Matricula> crearMatricula({
    required String token,
    required CrearMatriculaRequest request,
  }) async {
    final response = await ApiService.post(
      ApiConstants.crearMatricula,
      headers: ApiConstants.headersWithAuth(token),
      body: request.toJson(),
    );

    final data = ApiService.handleResponse(response);
    return Matricula.fromJson(data['matricula']);
  }

  // ==================== CREAR MATRÍCULA MASIVA ====================

  Future<Map<String, dynamic>> crearMatriculaMasiva({
    required String token,
    required MatriculaMasivaRequest request,
  }) async {
    final response = await ApiService.post(
      ApiConstants.crearMatriculaMasiva,
      headers: ApiConstants.headersWithAuth(token),
      body: request.toJson(),
    );

    final data = ApiService.handleResponse(response);

    final matriculas =
        (data['matriculas'] as List?)
            ?.map((m) => Matricula.fromJson(m))
            .toList() ??
        [];

    return {
      'matriculas': matriculas,
      'exitosos': data['exitosos'] ?? data['total'] ?? matriculas.length,
      'fallidos': data['fallidos'] ?? 0,
      'errores': data['errores'] ?? [],
      'message': data['message'] ?? 'Proceso completado',
    };
  }

  // ==================== LISTAR TODAS LAS MATRÍCULAS ==================== ✅ NUEVO

 // ==================== LISTAR TODAS LAS MATRÍCULAS ==================== ✅ NUEVO

Future<List<Matricula>> listarTodasLasMatriculas({
  required String token,
}) async {
  // 🔍 DEBUG
  print('=== 🚀 REPOSITORY: listarTodasLasMatriculas ===');
  print('URL: ${ApiConstants.matriculas}');
  print('Token presente: ${token.isNotEmpty}');
  
  final response = await ApiService.get(
    ApiConstants.matriculas,
    headers: ApiConstants.headersWithAuth(token),
  );

  print('=== 📦 RESPONSE RECIBIDO ===');
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
  print('===========================');

  final data = ApiService.handleResponse(response);
  
  print('=== 🔄 PARSEANDO MATRÍCULAS ===');
  
  if (data is! List) {
    print('❌ ERROR: data NO es List, es ${data.runtimeType}');
    throw Exception('La respuesta no es una lista');
  }
  
  print('Total items a parsear: ${data.length}');
  
  final matriculas = <Matricula>[];
  
  for (var i = 0; i < data.length; i++) {
    try {
      print('--- Parseando item $i ---');
      final matricula = Matricula.fromJson(data[i]);
      matriculas.add(matricula);
      print('✅ Item $i parseado correctamente');
      print('   Estudiante: ${matricula.nombreEstudiante}');
      print('   Curso: ${matricula.nombreCurso}');
    } catch (e) {
      print('❌ ERROR parseando item $i: $e');
      print('   JSON: ${data[i]}');
    }
  }
  
  print('Total matrículas parseadas: ${matriculas.length}');
  print('================================');
  
  return matriculas;
}
  // ==================== LISTAR MATRÍCULAS POR CURSO ====================

  Future<List<Matricula>> listarMatriculasPorCurso({
    required String token,
    required String cursoId,
  }) async {
    final response = await ApiService.get(
      '${ApiConstants.matriculas}/curso/$cursoId',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;

    // 🔍 DEBUG: Ver qué trae el backend
    // NOTE: evitar prints en producción; usar un logger si es necesario.
    if (data.isNotEmpty) {
      // Log the first record if necessary
      // logger.info('Primer registro: ${data[0]}');
    }

    return data.map((json) => Matricula.fromJson(json)).toList();
  }

  // ==================== LISTAR MATRÍCULAS POR ESTUDIANTE ====================

  Future<List<Matricula>> listarMatriculasPorEstudiante({
    required String token,
    required String estudianteId,
  }) async {
    final response = await ApiService.get(
      '${ApiConstants.matriculas}/estudiante/$estudianteId',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;
    return data.map((json) => Matricula.fromJson(json)).toList();
  }

  // ==================== LISTAR ESTUDIANTES DISPONIBLES ====================

  Future<List<Usuario>> listarEstudiantesDisponibles({
    required String token,
    required String cursoId,
    required String cicloId,
  }) async {
    final response = await ApiService.get(
      '${ApiConstants.estudiantesDisponibles}?curso_id=$cursoId&ciclo_id=$cicloId',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;
    return data.map((json) => Usuario.fromJson(json)).toList();
  }

  // ==================== ACTUALIZAR MATRÍCULA ====================

  Future<void> actualizarMatricula({
    required String token,
    required String matriculaId,
    required ActualizarMatriculaRequest request,
  }) async {
    final response = await ApiService.patch(
      '${ApiConstants.matriculas}/$matriculaId',
      headers: ApiConstants.headersWithAuth(token),
      body: request.toJson(),
    );

    ApiService.handleResponse(response);
  }

  // ==================== ELIMINAR MATRÍCULA ====================

  Future<void> eliminarMatricula({
    required String token,
    required String matriculaId,
  }) async {
    final response = await ApiService.delete(
      '${ApiConstants.matriculas}/$matriculaId',
      headers: ApiConstants.headersWithAuth(token),
    );

    ApiService.handleResponse(response);
  }
}