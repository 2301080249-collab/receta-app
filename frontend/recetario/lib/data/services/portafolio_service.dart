import '../models/portafolio.dart';
import '../repositories/portafolio_repository.dart';

/// Servicio para gestionar el portafolio (conectado al backend)
class PortafolioService {
  final PortafolioRepository _repository = PortafolioRepository();

  // ==================== CRUD RECETAS ====================

  /// Crear receta en portafolio
  Future<Portafolio> crear(CrearPortafolioRequest request) async {
    try {
      return await _repository.crear(request);
    } catch (e) {
      print('❌ [Service] Error creando receta: $e');
      rethrow;
    }
  }

  // ==================== ✨ NUEVO: ACTUALIZAR RECETA ====================
  /// Actualizar receta existente
  Future<Portafolio> actualizar(String id, dynamic request) async {
    try {
      return await _repository.actualizar(id, request);
    } catch (e) {
      print('❌ [Service] Error actualizando receta: $e');
      rethrow;
    }
  }

  /// Obtener mis recetas
  Future<List<Portafolio>> obtenerMisRecetas() async {
    try {
      return await _repository.obtenerMisRecetas();
    } catch (e) {
      print('❌ [Service] Error obteniendo mis recetas: $e');
      rethrow;
    }
  }

  /// Obtener recetas públicas
  Future<List<Portafolio>> obtenerPublicas() async {
    try {
      return await _repository.obtenerPublicas();
    } catch (e) {
      print('❌ [Service] Error obteniendo recetas públicas: $e');
      rethrow;
    }
  }

  /// Obtener receta por ID
  Future<Portafolio> obtenerPorId(String id) async {
    try {
      return await _repository.obtenerPorId(id);
    } catch (e) {
      print('❌ [Service] Error obteniendo receta: $e');
      rethrow;
    }
  }

  /// Eliminar receta
  Future<void> eliminar(String id) async {
    try {
      await _repository.eliminar(id);
    } catch (e) {
      print('❌ [Service] Error eliminando receta: $e');
      rethrow;
    }
  }

  // ==================== LIKES ====================

  /// Toggle like
  Future<Map<String, dynamic>> toggleLike(String portafolioId) async {
    try {
      return await _repository.toggleLike(portafolioId);
    } catch (e) {
      print('❌ [Service] Error en toggle like: $e');
      rethrow;
    }
  }

  /// Verificar si dio like
  Future<bool> yaDioLike(String portafolioId) async {
    try {
      return await _repository.yaDioLike(portafolioId);
    } catch (e) {
      print('❌ [Service] Error verificando like: $e');
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
      return await _repository.crearComentario(portafolioId, comentario);
    } catch (e) {
      print('❌ [Service] Error creando comentario: $e');
      rethrow;
    }
  }

  /// Obtener comentarios
  Future<List<ComentarioPortafolio>> obtenerComentarios(String portafolioId) async {
    try {
      return await _repository.obtenerComentarios(portafolioId);
    } catch (e) {
      print('❌ [Service] Error obteniendo comentarios: $e');
      rethrow;
    }
  }

  // ==================== CATEGORÍAS ====================

  /// Obtener categorías
  Future<List<Categoria>> obtenerCategorias() async {
    try {
      return await _repository.obtenerCategorias();
    } catch (e) {
      print('❌ [Service] Error obteniendo categorías: $e');
      rethrow;
    }
  }
}