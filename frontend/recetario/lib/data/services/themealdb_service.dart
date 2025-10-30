import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/receta_api.dart';

/// Servicio para interactuar con TheMealDB API
class TheMealDBService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  /// Buscar recetas por nombre
  Future<List<RecetaApi>> buscarPorNombre(String nombre) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search.php?s=$nombre'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;

        if (meals == null) return [];

        return meals.map((meal) => RecetaApi.fromJson(meal)).toList();
      }

      return [];
    } catch (e) {
      print('Error buscando recetas: $e');
      return [];
    }
  }

  /// Obtener recetas por categoría
  Future<List<RecetaApi>> obtenerPorCategoria(String categoria) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/filter.php?c=$categoria'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;

        if (meals == null) return [];

        // filter.php solo retorna id, nombre e imagen, hay que obtener detalles
        final recetasSimplificadas = meals.map((meal) {
          return RecetaApi(
            id: meal['idMeal'] ?? '',
            nombre: meal['strMeal'] ?? 'Sin nombre',
            imagenUrl: meal['strMealThumb'],
            categoria: categoria,
          );
        }).toList();

        return recetasSimplificadas;
      }

      return [];
    } catch (e) {
      print('Error obteniendo recetas por categoría: $e');
      return [];
    }
  }

  /// Obtener detalle completo de una receta por ID
  Future<RecetaApi?> obtenerDetallePorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lookup.php?i=$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;

        if (meals == null || meals.isEmpty) return null;

        return RecetaApi.fromJson(meals.first);
      }

      return null;
    } catch (e) {
      print('Error obteniendo detalle de receta: $e');
      return null;
    }
  }

  /// Obtener receta aleatoria
  Future<RecetaApi?> obtenerRecetaAleatoria() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/random.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;

        if (meals == null || meals.isEmpty) return null;

        return RecetaApi.fromJson(meals.first);
      }

      return null;
    } catch (e) {
      print('Error obteniendo receta aleatoria: $e');
      return null;
    }
  }

  /// Listar categorías disponibles
  Future<List<String>> obtenerCategorias() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/list.php?c=list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories = data['meals'] as List?;

        if (categories == null) return [];

        return categories
            .map((cat) => cat['strCategory'] as String)
            .toList();
      }

      return _categoriasDefault;
    } catch (e) {
      print('Error obteniendo categorías: $e');
      return _categoriasDefault;
    }
  }

  /// Categorías por defecto (fallback)
  static const List<String> _categoriasDefault = [
    'Beef',
    'Chicken',
    'Dessert',
    'Lamb',
    'Miscellaneous',
    'Pasta',
    'Pork',
    'Seafood',
    'Side',
    'Starter',
    'Vegan',
    'Vegetarian',
    'Breakfast',
    'Goat',
  ];

  /// Obtener categorías con traducción al español
  static const Map<String, String> categoriasTraducidas = {
    'Beef': 'Res',
    'Chicken': 'Pollo',
    'Dessert': 'Postres',
    'Lamb': 'Cordero',
    'Miscellaneous': 'Varios',
    'Pasta': 'Pasta',
    'Pork': 'Cerdo',
    'Seafood': 'Mariscos',
    'Side': 'Acompañamientos',
    'Starter': 'Entradas',
    'Vegan': 'Vegano',
    'Vegetarian': 'Vegetariano',
    'Breakfast': 'Desayuno',
    'Goat': 'Cabra',
  };
}