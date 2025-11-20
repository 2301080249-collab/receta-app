import '../models/receta_api.dart';
import 'themealdb_service.dart';
import 'translation_service.dart';

/// Servicio que envuelve TheMealDBService y traduce automáticamente
/// todas las recetas del inglés al español
class TranslatedTheMealDBService {
  final TheMealDBService _mealService = TheMealDBService();
  final TranslationService _translator = TranslationService();

  /// Buscar recetas por nombre (traducido al español)
  Future<List<RecetaApi>> buscarPorNombre(String nombre) async {
    try {
      print('🔍 Buscando recetas: "$nombre"...');
      
      // Obtener recetas en inglés
      final recetas = await _mealService.buscarPorNombre(nombre);
      
      if (recetas.isEmpty) {
        print('📭 No se encontraron recetas');
        return [];
      }
      
      print('✅ Encontradas ${recetas.length} recetas, traduciendo...');
      
      // Traducir todas las recetas
      final recetasTraducidas = await Future.wait(
        recetas.map((receta) => _traducirReceta(receta)),
      );
      
      print('✨ Traducción completada');
      return recetasTraducidas;
    } catch (e) {
      print('❌ Error buscando recetas: $e');
      return [];
    }
  }

  /// Obtener recetas por categoría (traducido al español)
  Future<List<RecetaApi>> obtenerPorCategoria(String categoria) async {
    try {
      print('🔍 Buscando recetas de categoría: "$categoria"...');
      
      // Obtener recetas en inglés
      final recetas = await _mealService.obtenerPorCategoria(categoria);
      
      if (recetas.isEmpty) {
        print('📭 No se encontraron recetas en esta categoría');
        return [];
      }
      
      print('✅ Encontradas ${recetas.length} recetas, traduciendo...');
      
      // Traducir todas las recetas
      final recetasTraducidas = await Future.wait(
        recetas.map((receta) => _traducirReceta(receta)),
      );
      
      print('✨ Traducción completada');
      return recetasTraducidas;
    } catch (e) {
      print('❌ Error obteniendo recetas por categoría: $e');
      return [];
    }
  }

  /// Obtener detalle completo de una receta (traducido al español)
  Future<RecetaApi?> obtenerDetallePorId(String id) async {
    try {
      print('🔍 Obteniendo detalle de receta: $id...');
      
      // Obtener receta en inglés
      final receta = await _mealService.obtenerDetallePorId(id);
      
      if (receta == null) {
        print('📭 Receta no encontrada');
        return null;
      }
      
      print('✅ Receta obtenida, traduciendo...');
      
      // Traducir la receta
      final recetaTraducida = await _traducirReceta(receta);
      
      print('✨ Traducción completada');
      return recetaTraducida;
    } catch (e) {
      print('❌ Error obteniendo detalle de receta: $e');
      return null;
    }
  }

  /// Obtener receta aleatoria (traducido al español)
  Future<RecetaApi?> obtenerRecetaAleatoria() async {
    try {
      print('🎲 Obteniendo receta aleatoria...');
      
      // Obtener receta en inglés
      final receta = await _mealService.obtenerRecetaAleatoria();
      
      if (receta == null) {
        print('📭 No se pudo obtener receta aleatoria');
        return null;
      }
      
      print('✅ Receta obtenida, traduciendo...');
      
      // Traducir la receta
      final recetaTraducida = await _traducirReceta(receta);
      
      print('✨ Traducción completada');
      return recetaTraducida;
    } catch (e) {
      print('❌ Error obteniendo receta aleatoria: $e');
      return null;
    }
  }

  /// Listar categorías disponibles (en español)
  Future<List<String>> obtenerCategorias() async {
    try {
      // Obtener categorías en inglés
      final categoriasEn = await _mealService.obtenerCategorias();
      
      // Usar traducciones manuales predefinidas (más precisas para categorías)
      return categoriasEn.map((catEn) {
        return TheMealDBService.categoriasTraducidas[catEn] ?? catEn;
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      // Retornar categorías por defecto en español
      return TheMealDBService.categoriasTraducidas.values.toList();
    }
  }

  /// Traducir una receta completa del inglés al español
  Future<RecetaApi> _traducirReceta(RecetaApi receta) async {
    try {
      // Preparar textos para traducir en paralelo
      final textos = <String>[
        receta.nombre,
        receta.categoria ?? '',
        receta.area ?? '',
        receta.instrucciones ?? '',
      ];
      
      // Traducir todos los textos en paralelo
      final traducidos = await _translator.traducirMultiple(textos);
      
      // Traducir ingredientes (más complejo porque es un Map)
      final ingredientesTraducidos = await _translator.traducirIngredientes(
        receta.ingredientes,
      );
      
      // Construir receta traducida
      return RecetaApi(
        id: receta.id,
        nombre: traducidos[0],
        categoria: traducidos[1].isNotEmpty ? traducidos[1] : null,
        area: traducidos[2].isNotEmpty ? traducidos[2] : null,
        instrucciones: traducidos[3].isNotEmpty ? traducidos[3] : null,
        imagenUrl: receta.imagenUrl, // URL no se traduce
        videoUrl: receta.videoUrl,   // URL no se traduce
        ingredientes: ingredientesTraducidos,
      );
    } catch (e) {
      print('⚠️ Error traduciendo receta, usando original: $e');
      // Si falla la traducción, retornar la receta original
      return receta;
    }
  }

  /// Limpiar caché de traducciones
  void limpiarCache() {
    _translator.limpiarCache();
  }

  /// Obtener tamaño del caché de traducciones
  int tamanoCache() {
    return _translator.tamanoCache();
  }
}