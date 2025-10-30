import 'package:flutter/material.dart';
import '../data/models/portafolio_item.dart';
import '../data/models/receta_api.dart';
import '../data/services/portafolio_storage_service.dart';
import '../data/services/themealdb_service.dart';

/// Provider para gestionar el estado del portafolio
class PortafolioProvider with ChangeNotifier {
  final PortafolioStorageService _storageService = PortafolioStorageService();
  final TheMealDBService _apiService = TheMealDBService();

  // ==================== ESTADO ====================
  List<PortafolioItem> _portafolio = [];
  List<RecetaApi> _resultadosBusqueda = [];
  List<String> _categorias = [];
  String? _categoriaSeleccionada;
  bool _isLoading = false;
  String? _error;

  // ==================== GETTERS ====================
  List<PortafolioItem> get portafolio => _portafolio;
  List<RecetaApi> get resultadosBusqueda => _resultadosBusqueda;
  List<String> get categorias => _categorias;
  String? get categoriaSeleccionada => _categoriaSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Portafolio filtrado por búsqueda
  List<PortafolioItem> get portafolioFiltrado {
    if (_categoriaSeleccionada == null || _categoriaSeleccionada == 'Todas') {
      return _portafolio;
    }
    
    return _portafolio.where((item) {
      return item.receta.categoria?.toLowerCase() == 
             _categoriaSeleccionada?.toLowerCase();
    }).toList();
  }

  // ==================== INICIALIZACIÓN ====================
  
  /// Cargar portafolio desde storage
  Future<void> cargarPortafolio() async {
    _setLoading(true);
    try {
      _portafolio = await _storageService.obtenerPortafolio();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar el portafolio: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar categorías disponibles
  Future<void> cargarCategorias() async {
    try {
      _categorias = await _apiService.obtenerCategorias();
      notifyListeners();
    } catch (e) {
      print('Error cargando categorías: $e');
      // Usar categorías hardcodeadas como fallback
      _categorias = [
        'Beef',
        'Chicken',
        'Dessert',
        'Lamb',
        'Pasta',
        'Pork',
        'Seafood',
        'Vegetarian',
      ];
      notifyListeners();
    }
  }

  // ==================== BÚSQUEDA DE API ====================
  
  /// Buscar recetas por nombre en TheMealDB
  Future<void> buscarRecetas(String query) async {
    if (query.trim().isEmpty) {
      _resultadosBusqueda = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _resultadosBusqueda = await _apiService.buscarPorNombre(query);
      _error = null;
    } catch (e) {
      _error = 'Error al buscar recetas: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Buscar recetas por categoría
  Future<void> buscarPorCategoria(String categoria) async {
    _setLoading(true);
    try {
      _resultadosBusqueda = await _apiService.obtenerPorCategoria(categoria);
      _error = null;
    } catch (e) {
      _error = 'Error al buscar por categoría: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener detalle completo de una receta
  Future<RecetaApi?> obtenerDetalleReceta(String id) async {
    try {
      return await _apiService.obtenerDetallePorId(id);
    } catch (e) {
      print('Error obteniendo detalle: $e');
      return null;
    }
  }

  // ==================== GESTIÓN DE PORTAFOLIO ====================
  
  /// Agregar receta al portafolio
  Future<bool> agregarReceta(
    RecetaApi receta, {
    String? comentarioUsuario,
  }) async {
    try {
      // Verificar si ya existe
      final existe = await _storageService.existeReceta(receta.id);
      if (existe) {
        _error = 'Esta receta ya está en tu portafolio';
        notifyListeners();
        return false;
      }

      // Agregar
      final success = await _storageService.agregarReceta(
        receta,
        comentarioUsuario: comentarioUsuario,
      );

      if (success) {
        // Recargar portafolio
        await cargarPortafolio();
        _error = null;
        return true;
      }

      return false;
    } catch (e) {
      _error = 'Error al agregar receta: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Eliminar receta del portafolio
  Future<bool> eliminarReceta(String recetaId) async {
    try {
      final success = await _storageService.eliminarReceta(recetaId);
      
      if (success) {
        await cargarPortafolio();
        _error = null;
        return true;
      }

      return false;
    } catch (e) {
      _error = 'Error al eliminar receta: $e';
      print(_error);
      notifyListeners();
      return false;
    }
  }

  /// Verificar si una receta está en el portafolio
  Future<bool> existeEnPortafolio(String recetaId) async {
    try {
      return await _storageService.existeReceta(recetaId);
    } catch (e) {
      print('Error verificando receta: $e');
      return false;
    }
  }

  // ==================== LIKES Y COMENTARIOS ====================
  
  /// Toggle like en una receta
  Future<bool> toggleLike(String recetaId) async {
    try {
      final success = await _storageService.toggleLike(recetaId);
      
      if (success) {
        // Actualizar localmente sin recargar todo
        final index = _portafolio.indexWhere((item) => item.receta.id == recetaId);
        if (index != -1) {
          _portafolio[index] = _portafolio[index].toggleLike();
          notifyListeners();
        }
        return true;
      }

      return false;
    } catch (e) {
      print('Error al dar like: $e');
      return false;
    }
  }

  /// Agregar comentario a una receta
  Future<bool> agregarComentario(
    String recetaId,
    String texto,
    String nombreUsuario,
  ) async {
    try {
      final comentario = Comentario(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        usuario: nombreUsuario,
        texto: texto,
        fecha: DateTime.now(),
      );

      final success = await _storageService.agregarComentario(
        recetaId,
        comentario,
      );

      if (success) {
        // Actualizar localmente
        final index = _portafolio.indexWhere((item) => item.receta.id == recetaId);
        if (index != -1) {
          _portafolio[index] = _portafolio[index].agregarComentario(comentario);
          notifyListeners();
        }
        return true;
      }

      return false;
    } catch (e) {
      print('Error al agregar comentario: $e');
      return false;
    }
  }

  /// Obtener item específico del portafolio
  PortafolioItem? obtenerItem(String recetaId) {
    try {
      return _portafolio.firstWhere((item) => item.receta.id == recetaId);
    } catch (e) {
      return null;
    }
  }

  // ==================== FILTROS ====================
  
  /// Cambiar categoría seleccionada
  void setCategoria(String? categoria) {
    _categoriaSeleccionada = categoria;
    notifyListeners();
  }

  /// Limpiar búsqueda
  void limpiarBusqueda() {
    _resultadosBusqueda = [];
    notifyListeners();
  }

  // ==================== UTILIDADES ====================
  
  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Obtener estadísticas
  Future<Map<String, int>> obtenerEstadisticas() async {
    return await _storageService.obtenerEstadisticas();
  }

  /// Limpiar todo el portafolio (solo para testing)
  Future<void> limpiarTodo() async {
    await _storageService.limpiarPortafolio();
    await cargarPortafolio();
  }
}