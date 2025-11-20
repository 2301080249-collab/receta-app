import 'package:flutter/material.dart';
import '../data/models/portafolio.dart';
import '../data/models/receta_api.dart';
import '../data/services/portafolio_service.dart';
import '../data/services/translation_themealdb_service.dart';
import '../data/services/themealdb_service.dart';

/// Provider para gestionar el estado del portafolio
class PortafolioProvider with ChangeNotifier {
  final PortafolioService _service = PortafolioService();
  final TranslatedTheMealDBService _apiService = TranslatedTheMealDBService();

  // ==================== ESTADO ====================
  List<Portafolio> _misRecetas = [];
  List<Portafolio> _recetasPublicas = [];
  List<RecetaApi> _resultadosBusqueda = [];
  List<Categoria> _categorias = [];
  List<String> _categoriasAPI = [];
  String? _categoriaSeleccionada;
  bool _isLoading = false;
  String? _error;

  // Likes cache (para UI optimista)
  Map<String, bool> _likesCache = {};

  // ==================== GETTERS ====================
  List<Portafolio> get misRecetas => _misRecetas;
  List<Portafolio> get recetasPublicas => _recetasPublicas;
  List<RecetaApi> get resultadosBusqueda => _resultadosBusqueda;
  List<Categoria> get categorias => _categorias;
  List<String> get categoriasAPI => _categoriasAPI;
  String? get categoriaSeleccionada => _categoriaSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Mis recetas filtradas por categoría
  List<Portafolio> get misRecetasFiltradas {
    if (_categoriaSeleccionada == null || _categoriaSeleccionada == 'Todas') {
      return _misRecetas;
    }

    return _misRecetas.where((receta) {
      return receta.categoriaId == _categoriaSeleccionada;
    }).toList();
  }

  /// Recetas públicas filtradas por categoría
  List<Portafolio> get recetasPublicasFiltradas {
    if (_categoriaSeleccionada == null || _categoriaSeleccionada == 'Todas') {
      return _recetasPublicas;
    }

    return _recetasPublicas.where((receta) {
      return receta.categoriaId == _categoriaSeleccionada;
    }).toList();
  }

  // ==================== INICIALIZACIÓN ====================

  /// Cargar mis recetas desde backend
  Future<void> cargarMisRecetas() async {
    _setLoading(true);
    try {
      _misRecetas = await _service.obtenerMisRecetas();
      _error = null;
      print('✅ Cargadas ${_misRecetas.length} recetas propias');
    } catch (e) {
      _error = 'Error al cargar tus recetas: $e';
      print('❌ $_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar recetas públicas (feed)
  Future<void> cargarRecetasPublicas() async {
    _setLoading(true);
    try {
      _recetasPublicas = await _service.obtenerPublicas();
      _error = null;
      print('✅ Cargadas ${_recetasPublicas.length} recetas públicas');
    } catch (e) {
      _error = 'Error al cargar recetas públicas: $e';
      print('❌ $_error');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar categorías desde BACKEND
  Future<void> cargarCategorias() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('📥 Cargando categorías desde BACKEND...');
      _categorias = await _service.obtenerCategorias();
      
      if (_categorias.isEmpty) {
        print('⚠️ No hay categorías en el backend');
        throw Exception('No hay categorías disponibles');
      }
      
      print('✅ Cargadas ${_categorias.length} categorías del backend:');
      for (var cat in _categorias) {
        print('   - ${cat.id}: ${cat.nombre}');
      }
      
      _error = null;
      
    } catch (e) {
      print('❌ Error cargando categorías: $e');
      _error = 'Error cargando categorías: $e';
      _categorias = [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar categorías de TheMealDB
  Future<void> cargarCategoriasAPI() async {
    try {
      print('📥 Cargando categorías desde TheMealDB API...');
      _categoriasAPI = await _apiService.obtenerCategorias();
      print('✅ Cargadas ${_categoriasAPI.length} categorías de API (en español)');
      notifyListeners();
    } catch (e) {
      print('❌ Error cargando categorías de API: $e');
    }
  }

  /// Limpiar categorías
  void limpiarCategorias() {
    _categorias = [];
    notifyListeners();
  }

  // ==================== BÚSQUEDA DE API (TheMealDB) ====================

  /// Buscar recetas por nombre en TheMealDB (con traducción automática)
  Future<void> buscarRecetas(String query) async {
    if (query.trim().isEmpty) {
      _resultadosBusqueda = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final queryEnIngles = _traducirQueryAIngles(query);
      print('🔍 Buscando "$query" → traducido a "$queryEnIngles"');
      
      _resultadosBusqueda = await _apiService.buscarPorNombre(queryEnIngles);
      _error = null;
      print('✅ Encontradas ${_resultadosBusqueda.length} recetas en TheMealDB');
    } catch (e) {
      _error = 'Error al buscar recetas: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  String _traducirQueryAIngles(String queryEs) {
    final query = queryEs.toLowerCase().trim();
    
    final traducciones = {
      'pollo': 'chicken',
      'res': 'beef',
      'carne': 'beef',
      'cerdo': 'pork',
      'puerco': 'pork',
      'pescado': 'fish',
      'camarón': 'shrimp',
      'camarones': 'shrimp',
      'mariscos': 'seafood',
      'cordero': 'lamb',
      'cabra': 'goat',
      'papa': 'potato',
      'papas': 'potato',
      'patata': 'potato',
      'patatas': 'potato',
      'tomate': 'tomato',
      'tomates': 'tomato',
      'cebolla': 'onion',
      'cebollas': 'onion',
      'zanahoria': 'carrot',
      'zanahorias': 'carrot',
      'lechuga': 'lettuce',
      'espinaca': 'spinach',
      'espinacas': 'spinach',
      'champiñón': 'mushroom',
      'champiñones': 'mushroom',
      'hongos': 'mushroom',
      'sopa': 'soup',
      'ensalada': 'salad',
      'postre': 'dessert',
      'pastel': 'cake',
      'tarta': 'tart',
      'pan': 'bread',
      'pizza': 'pizza',
      'pasta': 'pasta',
      'arroz': 'rice',
      'hamburguesa': 'burger',
      'sándwich': 'sandwich',
      'sandwich': 'sandwich',
      'empanada': 'pie',
      'galleta': 'cookie',
      'galletas': 'cookies',
      'asado': 'roasted',
      'frito': 'fried',
      'horneado': 'baked',
      'cocido': 'cooked',
      'hervido': 'boiled',
      'a la parrilla': 'grilled',
      'al horno': 'baked',
      'huevo': 'egg',
      'huevos': 'eggs',
      'tocino': 'bacon',
      'panqueque': 'pancake',
      'panqueques': 'pancakes',
      'waffle': 'waffle',
      'waffles': 'waffles',
      'dulce': 'sweet',
      'picante': 'spicy',
      'agrio': 'sour',
      'salado': 'salty',
      'queso': 'cheese',
      'leche': 'milk',
      'mantequilla': 'butter',
      'crema': 'cream',
    };
    
    if (traducciones.containsKey(query)) {
      return traducciones[query]!;
    }
    
    final palabras = query.split(' ');
    for (var palabra in palabras) {
      if (traducciones.containsKey(palabra)) {
        return traducciones[palabra]!;
      }
    }
    
    return query;
  }

  /// Buscar recetas por categoría en TheMealDB
  Future<void> buscarPorCategoria(String categoria) async {
    _setLoading(true);
    try {
      final categoriaEn = _convertirCategoriaAIngles(categoria);
      _resultadosBusqueda = await _apiService.obtenerPorCategoria(categoriaEn);
      _error = null;
      print('✅ Encontradas ${_resultadosBusqueda.length} recetas de $categoria');
    } catch (e) {
      _error = 'Error al buscar por categoría: $e';
      print('❌ $_error');
    } finally {
      _setLoading(false);
    }
  }

  String _convertirCategoriaAIngles(String categoriaEs) {
    final mapInvertido = <String, String>{};
    TheMealDBService.categoriasTraducidas.forEach((en, es) {
      mapInvertido[es] = en;
    });
    
    return mapInvertido[categoriaEs] ?? categoriaEs;
  }

  /// Obtener detalle completo de una receta de TheMealDB
  Future<RecetaApi?> obtenerDetalleReceta(String id) async {
    try {
      return await _apiService.obtenerDetallePorId(id);
    } catch (e) {
      print('❌ Error obteniendo detalle: $e');
      return null;
    }
  }

  // ==================== CRUD RECETAS PROPIAS ====================

  /// Crear receta propia
  Future<bool> crearReceta(CrearPortafolioRequest request) async {
    _setLoading(true);
    try {
      final receta = await _service.crear(request);
      _misRecetas.insert(0, receta);
      _error = null;
      print('✅ Receta creada: ${receta.titulo}');
      return true;
    } catch (e) {
      _error = 'Error al crear receta: $e';
      print('❌ $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== ✨ NUEVO: ACTUALIZAR RECETA ====================
  /// Actualizar receta existente
  Future<bool> actualizarReceta(String id, dynamic request) async {
    _setLoading(true);
    try {
      final recetaActualizada = await _service.actualizar(id, request);
      
      // Actualizar en la lista de mis recetas
      final index = _misRecetas.indexWhere((r) => r.id == id);
      if (index != -1) {
        _misRecetas[index] = recetaActualizada;
      }
      
      // Actualizar en recetas públicas si está ahí
      final publicIndex = _recetasPublicas.indexWhere((r) => r.id == id);
      if (publicIndex != -1) {
        _recetasPublicas[publicIndex] = recetaActualizada;
      }
      
      _error = null;
      print('✅ Receta actualizada: ${recetaActualizada.titulo}');
      return true;
    } catch (e) {
      _error = 'Error al actualizar receta: $e';
      print('❌ $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Publicar receta desde TheMealDB
  Future<bool> publicarDesdeAPI(
    RecetaApi receta,
    String categoriaId, {
    String? comentario,
  }) async {
    try {
      String ingredientesTexto = '';
      receta.ingredientes.forEach((ingrediente, medida) {
        if (medida.isNotEmpty) {
          ingredientesTexto += '• $medida de $ingrediente\n';
        } else {
          ingredientesTexto += '• $ingrediente\n';
        }
      });

      if (ingredientesTexto.isEmpty) {
        ingredientesTexto = 'Ver receta original para ingredientes';
      }

      List<String> fotos = [];
      if (receta.imagenUrl != null && receta.imagenUrl!.isNotEmpty) {
        fotos = [receta.imagenUrl!];
      }

      final request = CrearPortafolioRequest(
        titulo: receta.nombre,
        descripcion: comentario,
        ingredientes: ingredientesTexto.trim(),
        preparacion: receta.instrucciones ?? 'Ver video para instrucciones',
        fotos: fotos,
        videoUrl: receta.videoUrl,
        categoriaId: categoriaId,
        tipoReceta: 'api',
        fuenteApiId: receta.id,
        visibilidad: 'publica',
      );

      return await crearReceta(request);
    } catch (e) {
      _error = 'Error al publicar receta: $e';
      print('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// Obtener receta por ID
  Future<Portafolio?> obtenerRecetaPorId(String id) async {
    try {
      return await _service.obtenerPorId(id);
    } catch (e) {
      print('❌ Error obteniendo receta: $e');
      return null;
    }
  }

  // ==================== ✨ MODIFICADO: ELIMINAR RECETA ====================
  /// Eliminar receta (incluyendo imágenes del Storage)
  Future<bool> eliminarReceta(String id) async {
    _setLoading(true);
    try {
      await _service.eliminar(id);
      _misRecetas.removeWhere((r) => r.id == id);
      _recetasPublicas.removeWhere((r) => r.id == id);
      _error = null;
      print('✅ Receta eliminada');
      return true;
    } catch (e) {
      _error = 'Error al eliminar receta: $e';
      print('❌ $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== LIKES ====================

  /// Toggle like (UI optimista)
  Future<bool> toggleLike(String portafolioId) async {
    try {
      final recetaIndex = _recetasPublicas.indexWhere(
        (r) => r.id == portafolioId,
      );
      if (recetaIndex != -1) {
        final receta = _recetasPublicas[recetaIndex];
        final yaLeDioLike = _likesCache[portafolioId] ?? false;

        _likesCache[portafolioId] = !yaLeDioLike;
        _recetasPublicas[recetaIndex] = receta.copyWith(
          likes: yaLeDioLike ? receta.likes - 1 : receta.likes + 1,
        );
        notifyListeners();
      }

      final result = await _service.toggleLike(portafolioId);
      final liked = result['liked'] ?? false;

      _likesCache[portafolioId] = liked;

      print('✅ Like ${liked ? "agregado" : "removido"}');
      return true;
    } catch (e) {
      print('❌ Error en toggle like: $e');
      await cargarRecetasPublicas();
      return false;
    }
  }

  /// Verificar si el usuario dio like
  Future<bool> yaDioLike(String portafolioId) async {
    if (_likesCache.containsKey(portafolioId)) {
      return _likesCache[portafolioId]!;
    }

    try {
      final liked = await _service.yaDioLike(portafolioId);
      _likesCache[portafolioId] = liked;
      return liked;
    } catch (e) {
      print('❌ Error verificando like: $e');
      return false;
    }
  }

  // ==================== COMENTARIOS ====================

  /// Crear comentario
  Future<bool> crearComentario(String portafolioId, String comentario) async {
    try {
      await _service.crearComentario(portafolioId, comentario);
      print('✅ Comentario agregado');
      return true;
    } catch (e) {
      _error = 'Error al agregar comentario: $e';
      print('❌ $_error');
      notifyListeners();
      return false;
    }
  }

  /// Obtener comentarios de una receta
  Future<List<ComentarioPortafolio>> obtenerComentarios(
    String portafolioId,
  ) async {
    try {
      return await _service.obtenerComentarios(portafolioId);
    } catch (e) {
      print('❌ Error obteniendo comentarios: $e');
      return [];
    }
  }

  // ==================== FILTROS ====================

  /// Cambiar categoría seleccionada
  void setCategoria(String? categoriaId) {
    _categoriaSeleccionada = categoriaId;
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

  /// Refrescar todo
  Future<void> refrescarTodo() async {
    _setLoading(true);
    try {
      await Future.wait([
        cargarMisRecetas().catchError((e) {
          print('⚠️ Error cargando mis recetas: $e');
          return null;
        }),
        cargarRecetasPublicas().catchError((e) {
          print('⚠️ Error cargando recetas públicas: $e');
          return null;
        }),
        cargarCategorias().catchError((e) {
          print('⚠️ Error cargando categorías: $e');
          return null;
        }),
      ]);
    } finally {
      _setLoading(false);
    }
  }

  /// Limpiar cache de likes
  void limpiarCacheLikes() {
    _likesCache.clear();
  }

  /// Limpiar caché de traducciones
  void limpiarCacheTraduccion() {
    _apiService.limpiarCache();
    print('🗑️ Caché de traducciones limpiado');
  }

  /// Obtener tamaño del caché de traducciones
  int tamanoCacheTraduccion() {
    return _apiService.tamanoCache();
  }
}