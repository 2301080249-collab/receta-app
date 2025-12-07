
import '../../core/constants/api_constants.dart';
import '../../core/utils/token_manager.dart';
import '../models/portafolio.dart';
import '../services/api_service.dart';

class PortafolioRepository {
  
  // ==================== CRUD RECETAS ====================
  
  /// Crear receta en portafolio
  Future<Portafolio> crear(CrearPortafolioRequest request) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.post(
        ApiConstants.crearPortafolio,
        body: request.toJson(),
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      return Portafolio.fromJson(data);
    } catch (e) {
      print('❌ Error creando receta: $e');
      throw Exception('Error al crear receta: $e');
    }
  }

  // ==================== ✨ NUEVO: ACTUALIZAR RECETA ====================
  /// Actualizar receta existente
  Future<Portafolio> actualizar(String id, dynamic request) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.put(
        ApiConstants.actualizarPortafolio(id),
        body: request.toJson(),
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      return Portafolio.fromJson(data);
    } catch (e) {
      print('❌ Error actualizando receta: $e');
      throw Exception('Error al actualizar receta: $e');
    }
  }

  /// Obtener mis recetas (portafolio personal)
  Future<List<Portafolio>> obtenerMisRecetas() async {
    try {
      final token = await TokenManager.getToken();
      
      print('════════════════════════════════════');
      print('🔑 TOKEN EXISTE: ${token != null}');
      if (token != null) {
        print('🔑 TOKEN LENGTH: ${token.length}');
        print('🔑 PRIMEROS 100 CHARS: ${token.substring(0, token.length > 100 ? 100 : token.length)}');
      } else {
        print('❌ TOKEN ES NULL - NO HAY TOKEN GUARDADO');
      }
      print('📡 BACKEND URL: ${ApiService.baseUrl}');
      print('📡 ENDPOINT: ${ApiConstants.misRecetas}');
      print('📡 FULL URL: ${ApiService.baseUrl}${ApiConstants.misRecetas}');
      print('════════════════════════════════════');
      
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.get(
        ApiConstants.misRecetas,
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      
      if (data is List) {
        return data.map((json) => Portafolio.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error obteniendo mis recetas: $e');
      throw Exception('Error al obtener recetas: $e');
    }
  }

  /// Obtener recetas públicas (feed general)
  Future<List<Portafolio>> obtenerPublicas() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.get(
        ApiConstants.recetasPublicas,
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      
      if (data is List) {
        return data.map((json) => Portafolio.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error obteniendo recetas públicas: $e');
      throw Exception('Error al obtener recetas públicas: $e');
    }
  }

  /// Obtener detalle de una receta
Future<Portafolio> obtenerPorId(String id) async {
  try {
    final token = await TokenManager.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final response = await ApiService.get(
      ApiConstants.portafolioDetalle(id),
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response);
    
    // ✅ AGREGAR ESTOS LOGS
    print('═══════════════════════════════════════');
    print('📥 RESPUESTA COMPLETA DEL BACKEND:');
    print(data);
    print('───────────────────────────────────────');
    print('🔍 CAMPOS DE USUARIO:');
    print('nombre_estudiante: ${data['nombre_estudiante']}');
    print('avatar_estudiante: ${data['avatar_estudiante']}');
    print('codigo_estudiante: ${data['codigo_estudiante']}');
    print('═══════════════════════════════════════');
    
    return Portafolio.fromJson(data);
  } catch (e) {
    print('❌ Error obteniendo receta: $e');
    throw Exception('Error al obtener receta: $e');
  }
}

  /// Eliminar receta
  Future<void> eliminar(String id) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.delete(
        ApiConstants.eliminarPortafolio(id),
        headers: ApiConstants.headersWithAuth(token),
      );

      ApiService.handleResponse(response);
    } catch (e) {
      print('❌ Error eliminando receta: $e');
      throw Exception('Error al eliminar receta: $e');
    }
  }

  // ==================== LIKES ====================

  /// Toggle like (dar o quitar)
  Future<Map<String, dynamic>> toggleLike(String portafolioId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.post(
        ApiConstants.toggleLike(portafolioId),
        body: {},
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      return {
        'liked': data['liked'] ?? false,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      print('❌ Error en toggle like: $e');
      throw Exception('Error al dar/quitar like: $e');
    }
  }

  /// Verificar si ya dio like
  Future<bool> yaDioLike(String portafolioId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.get(
        ApiConstants.yaDioLike(portafolioId),
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      return data['ya_dio_like'] ?? false;
    } catch (e) {
      print('❌ Error verificando like: $e');
      return false;
    }
  }

  // ==================== COMENTARIOS ====================

  /// Crear comentario
  Future<ComentarioPortafolio> crearComentario(
    String portafolioId,
    String comentario,
  ) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.post(
        ApiConstants.crearComentario(portafolioId),
        body: {'comentario': comentario},
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      return ComentarioPortafolio.fromJson(data);
    } catch (e) {
      print('❌ Error creando comentario: $e');
      throw Exception('Error al crear comentario: $e');
    }
  }

  /// Obtener comentarios de una receta
  Future<List<ComentarioPortafolio>> obtenerComentarios(String portafolioId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.get(
        ApiConstants.obtenerComentarios(portafolioId),
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      
      if (data is List) {
        return data.map((json) => ComentarioPortafolio.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error obteniendo comentarios: $e');
      throw Exception('Error al obtener comentarios: $e');
    }
  }

  // ==================== CATEGORÍAS ====================

  /// Obtener categorías
  Future<List<Categoria>> obtenerCategorias() async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await ApiService.get(
        ApiConstants.categorias,
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      
      if (data is List) {
        return data.map((json) => Categoria.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      throw Exception('Error al obtener categorías: $e');
    }
  }
}