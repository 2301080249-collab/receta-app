import '../models/tarea.dart';
import '../models/entrega.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/api_cache.dart'; // ✅ AGREGAR
import 'api_service.dart';
import 'token_service.dart';

class TareaService {
  static final _cache = ApiCache(); // ✅ AGREGAR

  // Crear tarea (docente)
  static Future<Tarea> crearTarea(Tarea tarea) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.post(
        ApiConstants.tareas,
        headers: ApiConstants.headersWithAuth(token),
        body: tarea.toJson(),
      );

      final data = ApiService.handleResponse(response);
      
      // ✅ AGREGAR: Invalidar cache de temas
      if (tarea.temaId != null) {
        _cache.invalidate('temas_curso_${tarea.cursoId}');
        print('🗑️ Cache invalidado para curso ${tarea.cursoId}');
      }
      
      return Tarea.fromJson(data);
    } catch (e) {
      throw Exception('Error al crear tarea: $e');
    }
  }

  // Actualizar tarea (docente)
  static Future<void> actualizarTarea(String tareaId, Tarea tarea) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.put(
        '${ApiConstants.tareas}/$tareaId',
        headers: ApiConstants.headersWithAuth(token),
        body: tarea.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar tarea');
      }
      
      // ✅ AGREGAR: Invalidar cache
      _cache.invalidate('temas_curso_${tarea.cursoId}');
    } catch (e) {
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  // Eliminar tarea (docente)
  static Future<void> eliminarTarea(String tareaId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.delete(
        '${ApiConstants.tareas}/$tareaId',
        headers: ApiConstants.headersWithAuth(token),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar tarea');
      }
      
      // ✅ NOTA: Aquí necesitarías el cursoId, considera pasarlo como parámetro
      // _cache.invalidate('temas_curso_$cursoId');
    } catch (e) {
      throw Exception('Error al eliminar tarea: $e');
    }
  }

  // ... resto del código sin cambios
  
  // Listar tareas por tema
  static Future<List<Tarea>> getTareasByTemaId(String temaId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.get(
        '${ApiConstants.temas}/$temaId/tareas',
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response) as List;
      return data.map((json) => Tarea.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener tareas: $e');
    }
  }

  // Obtener entregas de una tarea (docente)
  static Future<List<Entrega>> getEntregasByTareaId(String tareaId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.get(
        '${ApiConstants.tareas}/$tareaId/entregas',
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response) as List;
      return data.map((json) => Entrega.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener entregas: $e');
    }
  }

  // Obtener mi entrega (estudiante)
  static Future<Entrega?> getMiEntrega(String tareaId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.get(
        '${ApiConstants.tareas}/$tareaId/mi-entrega',
        headers: ApiConstants.headersWithAuth(token),
      );

      if (response.statusCode == 404) {
        return null;
      }

      final data = ApiService.handleResponse(response);
      return Entrega.fromJson(data);
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Error al obtener mi entrega: $e');
    }
  }

  // Calificar entrega (docente)
  static Future<void> calificarEntrega({
    required String entregaId,
    required double calificacion,
    required String comentario,
  }) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final response = await ApiService.put(
        '${ApiConstants.entregas}/$entregaId/calificar',
        headers: ApiConstants.headersWithAuth(token),
        body: {
          'calificacion': calificacion,
          'comentario_docente': comentario,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al calificar entrega');
      }
    } catch (e) {
      throw Exception('Error al calificar entrega: $e');
    }
  }
}