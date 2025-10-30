import '../models/tema.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';
import 'token_service.dart';

class TemaService {
  // Obtener temas de un curso
  static Future<List<Tema>> getTemasByCursoId(String cursoId) async {
    try {
      print('🔍 getTemasByCursoId - cursoId: $cursoId');
      
      // ✅ Obtener token
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');
      
      final endpoint = '${ApiConstants.cursos}/$cursoId/temas';
      print('🔍 Endpoint: $endpoint');
      
      final response = await ApiService.get(
        endpoint,
        headers: ApiConstants.headersWithAuth(token), // ✅ Envía token
      );
      
      print('🔍 Response status: ${response.statusCode}');
      
      final data = ApiService.handleResponse(response) as List;
      return data.map((json) => Tema.fromJson(json)).toList();
    } catch (e) {
      print('❌ ERROR en getTemasByCursoId: $e');
      throw Exception('Error al obtener temas: $e');
    }
  }

  // Crear tema (docente)
  static Future<Tema> crearTema(Tema tema) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');
      
      final response = await ApiService.post(
        ApiConstants.temas,
        headers: ApiConstants.headersWithAuth(token),
        body: tema.toJson(),
      );

      final data = ApiService.handleResponse(response);
      return Tema.fromJson(data);
    } catch (e) {
      throw Exception('Error al crear tema: $e');
    }
  }

  // Actualizar tema (docente)
  static Future<void> actualizarTema(String temaId, Map<String, dynamic> data) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');
      
      await ApiService.put(
        '${ApiConstants.temas}/$temaId',
        headers: ApiConstants.headersWithAuth(token),
        body: data,
      );
    } catch (e) {
      throw Exception('Error al actualizar tema: $e');
    }
  }

  // Eliminar tema (docente)
  static Future<void> eliminarTema(String temaId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');
      
      await ApiService.delete(
        '${ApiConstants.temas}/$temaId',
        headers: ApiConstants.headersWithAuth(token),
      );
    } catch (e) {
      throw Exception('Error al eliminar tema: $e');
    }
  }
}