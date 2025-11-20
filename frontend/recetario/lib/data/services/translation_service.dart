import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio de traducción usando Google Translate (API gratuita vía proxy público)
class TranslationService {
  // API gratuita de Google Translate
  static const String _baseUrl = 'https://translate.googleapis.com/translate_a/single';
  
  // Cache de traducciones para evitar llamadas repetidas
  static final Map<String, String> _cache = {};
  
  /// Traducir texto del inglés al español
  /// 
  /// Usa caché para no traducir el mismo texto dos veces
  Future<String> traducir(String texto) async {
    // Si el texto está vacío o es null, retornarlo tal cual
    if (texto.trim().isEmpty) return texto;
    
    // Revisar en caché primero
    final cacheKey = texto.toLowerCase().trim();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    try {
      // Construir URL con parámetros de Google Translate
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'client': 'gtx',
        'sl': 'en',
        'tl': 'es',
        'dt': 't',
        'q': texto,
      });
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Timeout en traducción, usando texto original');
          return http.Response('[[["$texto"]]]', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Google Translate devuelve: [[[traducción, original, ...]]]
        String traduccion = '';
        if (data is List && data.isNotEmpty && data[0] is List) {
          for (var item in data[0]) {
            if (item is List && item.isNotEmpty) {
              traduccion += item[0].toString();
            }
          }
        }
        
        if (traduccion.isEmpty) {
          traduccion = texto;
        }
        
        // Guardar en caché
        _cache[cacheKey] = traduccion;
        
        return traduccion;
      } else {
        print('⚠️ Error en traducción (${response.statusCode}), usando original');
        return texto;
      }
    } catch (e) {
      print('⚠️ Error traduciendo: $e');
      return texto;
    }
  }
  
  /// Traducir múltiples textos con delay para evitar sobrecarga
  Future<List<String>> traducirMultiple(List<String> textos) async {
    final resultados = <String>[];
    
    for (var texto in textos) {
      final traduccion = await traducir(texto);
      resultados.add(traduccion);
      
      // Pequeño delay solo si no está en caché
      if (!_cache.containsKey(texto.toLowerCase().trim())) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    
    return resultados;
  }
  
  /// Traducir un Map de ingredientes (ingrediente -> medida)
  Future<Map<String, String>> traducirIngredientes(
    Map<String, String> ingredientes,
  ) async {
    final resultado = <String, String>{};
    
    for (var entry in ingredientes.entries) {
      final ingrediente = entry.key;
      final medida = entry.value;
      
      // Traducir ingrediente y medida
      final ingredienteTraducido = await traducir(ingrediente);
      await Future.delayed(const Duration(milliseconds: 50));
      
      final medidaTraducida = await traducir(medida);
      await Future.delayed(const Duration(milliseconds: 50));
      
      resultado[ingredienteTraducido] = medidaTraducida;
    }
    
    return resultado;
  }
  
  /// Limpiar caché de traducciones
  void limpiarCache() {
    _cache.clear();
    print('🗑️ Caché de traducciones limpiado');
  }
  
  /// Obtener tamaño del caché
  int tamanoCache() {
    return _cache.length;
  }
}