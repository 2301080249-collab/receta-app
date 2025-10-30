import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portafolio_item.dart';
import '../models/receta_api.dart';

/// Servicio para gestionar el almacenamiento local del portafolio
class PortafolioStorageService {
  static const String _keyPortafolio = 'portafolio_recetas';

  /// Obtener todas las recetas del portafolio
  Future<List<PortafolioItem>> obtenerPortafolio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPortafolio);

      if (jsonString == null) return [];

      final Map<String, dynamic> data = json.decode(jsonString);
      final List<PortafolioItem> items = [];

      data.forEach((key, value) {
        items.add(PortafolioItem.fromJson(value));
      });

      // Ordenar por fecha (más recientes primero)
      items.sort((a, b) => b.fechaAgregado.compareTo(a.fechaAgregado));

      return items;
    } catch (e) {
      print('Error obteniendo portafolio: $e');
      return [];
    }
  }

  /// Agregar receta al portafolio
  Future<bool> agregarReceta(
    RecetaApi receta, {
    String? comentarioUsuario,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final portafolio = await _obtenerMapaPortafolio();

      // Crear nuevo item
      final nuevoItem = PortafolioItem(
        receta: receta,
        fechaAgregado: DateTime.now(),
        comentarioUsuario: comentarioUsuario,
        likes: 0,
        likedByUser: false,
        comentarios: [],
      );

      // Guardar con ID de receta como key
      portafolio[receta.id] = nuevoItem.toJson();

      // Persistir
      await prefs.setString(_keyPortafolio, json.encode(portafolio));
      return true;
    } catch (e) {
      print('Error agregando receta: $e');
      return false;
    }
  }

  /// Verificar si una receta ya está en el portafolio
  Future<bool> existeReceta(String recetaId) async {
    try {
      final portafolio = await _obtenerMapaPortafolio();
      return portafolio.containsKey(recetaId);
    } catch (e) {
      print('Error verificando receta: $e');
      return false;
    }
  }

  /// Eliminar receta del portafolio
  Future<bool> eliminarReceta(String recetaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final portafolio = await _obtenerMapaPortafolio();

      portafolio.remove(recetaId);

      await prefs.setString(_keyPortafolio, json.encode(portafolio));
      return true;
    } catch (e) {
      print('Error eliminando receta: $e');
      return false;
    }
  }

  /// Toggle like en una receta
  Future<bool> toggleLike(String recetaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final portafolio = await _obtenerMapaPortafolio();

      if (!portafolio.containsKey(recetaId)) return false;

      final item = PortafolioItem.fromJson(portafolio[recetaId]);
      final itemActualizado = item.toggleLike();

      portafolio[recetaId] = itemActualizado.toJson();

      await prefs.setString(_keyPortafolio, json.encode(portafolio));
      return true;
    } catch (e) {
      print('Error haciendo toggle like: $e');
      return false;
    }
  }

  /// Agregar comentario a una receta
  Future<bool> agregarComentario(
    String recetaId,
    Comentario comentario,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final portafolio = await _obtenerMapaPortafolio();

      if (!portafolio.containsKey(recetaId)) return false;

      final item = PortafolioItem.fromJson(portafolio[recetaId]);
      final itemActualizado = item.agregarComentario(comentario);

      portafolio[recetaId] = itemActualizado.toJson();

      await prefs.setString(_keyPortafolio, json.encode(portafolio));
      return true;
    } catch (e) {
      print('Error agregando comentario: $e');
      return false;
    }
  }

  /// Obtener una receta específica del portafolio
  Future<PortafolioItem?> obtenerReceta(String recetaId) async {
    try {
      final portafolio = await _obtenerMapaPortafolio();

      if (!portafolio.containsKey(recetaId)) return null;

      return PortafolioItem.fromJson(portafolio[recetaId]);
    } catch (e) {
      print('Error obteniendo receta: $e');
      return null;
    }
  }

  /// Limpiar todo el portafolio (útil para testing)
  Future<bool> limpiarPortafolio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPortafolio);
      return true;
    } catch (e) {
      print('Error limpiando portafolio: $e');
      return false;
    }
  }

  /// Método privado para obtener el mapa del portafolio
  Future<Map<String, dynamic>> _obtenerMapaPortafolio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPortafolio);

      if (jsonString == null) return {};

      return json.decode(jsonString);
    } catch (e) {
      print('Error obteniendo mapa portafolio: $e');
      return {};
    }
  }

  /// Obtener estadísticas del portafolio
  Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final items = await obtenerPortafolio();

      int totalLikes = 0;
      int totalComentarios = 0;

      for (var item in items) {
        totalLikes += item.likes;
        totalComentarios += item.comentarios.length;
      }

      return {
        'totalRecetas': items.length,
        'totalLikes': totalLikes,
        'totalComentarios': totalComentarios,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'totalRecetas': 0,
        'totalLikes': 0,
        'totalComentarios': 0,
      };
    }
  }
}