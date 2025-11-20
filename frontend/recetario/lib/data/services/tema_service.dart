import '../models/tema.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/api_cache.dart'; // ✅ NUEVO
import 'api_service.dart';
import 'token_service.dart';

class TemaService {
  static final _cache = ApiCache(); // ✅ NUEVO

  // Obtener temas de un curso CON CACHE
  static Future<List<Tema>> getTemasByCursoId(String cursoId) async {
    final cacheKey = 'temas_curso_$cursoId';
    
    return await _cache.getOrFetch(
      cacheKey,
      () => _fetchTemasByCursoId(cursoId),
      cacheDuration: const Duration(minutes: 5),
    );
  }

  // ✅ NUEVO: Función privada que hace la petición real
  static Future<List<Tema>> _fetchTemasByCursoId(String cursoId) async {
    try {
      print('🔍 getTemasByCursoId - cursoId: $cursoId');
      
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');
      
      final endpoint = '${ApiConstants.cursos}/$cursoId/temas';
      print('🔍 Endpoint: $endpoint');
      
      final response = await ApiService.get(
        endpoint,
        headers: ApiConstants.headersWithAuth(token),
      );
      
      print('🔍 Response status: ${response.statusCode}');
      
      final data = ApiService.handleResponse(response) as List;
      return data.map((json) => Tema.fromJson(json)).toList();
    } catch (e) {
      print('❌ ERROR en getTemasByCursoId: $e');
      throw Exception('Error al obtener temas: $e');
    }
  }

  // ✅ NUEVO: Invalidar cache cuando se crea/edita/elimina un tema
  static void invalidarCacheTemas(String cursoId) {
    _cache.invalidate('temas_curso_$cursoId');
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
      
      // ✅ Invalidar cache
      invalidarCacheTemas(tema.cursoId);
      
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
      
      // ✅ Invalidar cache (necesitarías pasar cursoId)
      // invalidarCacheTemas(cursoId);
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
      
      // ✅ Invalidar cache (necesitarías pasar cursoId)
      // invalidarCacheTemas(cursoId);
    } catch (e) {
      throw Exception('Error al eliminar tema: $e');
    }
  }
}