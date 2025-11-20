import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modelo de análisis nutricional estructurado
class AnalisisNutricional {
  final String resumen;
  final String tipo;
  final List<String> puntosClave;

  AnalisisNutricional({
    required this.resumen,
    required this.tipo,
    required this.puntosClave,
  });

  factory AnalisisNutricional.fallback(String categoria) {
    return AnalisisNutricional(
      resumen: _getFallbackPorCategoria(categoria),
      tipo: 'neutral',
      puntosClave: [],
    );
  }

  static String _getFallbackPorCategoria(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    
    if (categoriaLower.contains('vegan') || categoriaLower.contains('vegetarian')) {
      return 'Esta receta es rica en fibra y antioxidantes de origen vegetal. Baja en grasas saturadas.\n\nRecomendación: Apta para todo tipo de dietas. Consumo recomendado: regular.';
    }
    
    if (categoriaLower.contains('dessert') || categoriaLower.contains('postres') || categoriaLower.contains('postre')) {
      return 'Esta receta es alta en azúcares y grasas saturadas. Alto contenido calórico.\n\nRecomendación: Evitar en dietas para diabetes o colesterol alto. Consumo recomendado: ocasional.';
    }
    
    if (categoriaLower.contains('seafood') || categoriaLower.contains('fish') || 
        categoriaLower.contains('mariscos') || categoriaLower.contains('pescado')) {
      return 'Esta receta es rica en Omega-3 y proteínas magras. Bajo contenido en grasas saturadas.\n\nRecomendación: Excelente para personas con diabetes o colesterol alto. Consumo recomendado: regular.';
    }
    
    if (categoriaLower.contains('chicken') || categoriaLower.contains('pollo')) {
      return 'Esta receta aporta proteínas magras de alta calidad. Moderada en grasas según la preparación.\n\nRecomendación: Apta para dietas de control de peso y diabetes. Consumo recomendado: regular.';
    }
    
    if (categoriaLower.contains('beef') || categoriaLower.contains('lamb') || 
        categoriaLower.contains('pork') || categoriaLower.contains('carne')) {
      return 'Esta receta es alta en proteínas pero también en grasas saturadas. Rica en hierro.\n\nRecomendación: Moderar consumo si tiene colesterol alto. Consumo recomendado: ocasional.';
    }
    
    if (categoriaLower.contains('pasta') || categoriaLower.contains('noodles')) {
      return 'Esta receta es rica en carbohidratos complejos. Moderada en calorías según la porción.\n\nRecomendación: Controlar porciones en dietas para diabetes. Consumo recomendado: regular con moderación.';
    }
    
    if (categoriaLower.contains('breakfast') || categoriaLower.contains('desayuno')) {
      return 'Esta receta aporta energía y nutrientes para comenzar el día. Balance de macronutrientes.\n\nRecomendación: Apta para todo tipo de dietas. Consumo recomendado: regular.';
    }
    
    return 'Esta receta tiene un balance nutricional moderado. Variedad de ingredientes.\n\nRecomendación: Apta para consumo regular. Moderar porciones según objetivos nutricionales.';
  }
}

class GeminiNutritionService {
  final String apiKey;
  final _cache = <String, AnalisisNutricional>{};

  GeminiNutritionService(this.apiKey) {
    print('🤖 [GEMINI] Servicio inicializado');
    if (apiKey.isEmpty) {
      print('❌ [GEMINI] API KEY VACÍA');
    } else {
      print('✅ [GEMINI] API KEY configurada - Usando gemini-2.0-flash');
    }
  }

  Future<AnalisisNutricional> analizarReceta({
    required String recetaId,
    required String nombreReceta,
    required String categoria,
    required List<String> ingredientes,
  }) async {
    print('\n🔍 [GEMINI] ════════════════════════════════════════');
    print('📋 Iniciando análisis: $nombreReceta');
    print('📂 Categoría: $categoria');
    print('🥘 Ingredientes: ${ingredientes.take(5).join(", ")}...');

    if (_cache.containsKey(recetaId)) {
      print('✅ Encontrado en caché');
      print('🔍 [GEMINI] ════════════════════════════════════════\n');
      return _cache[recetaId]!;
    }

    if (apiKey.isEmpty || apiKey.length < 20) {
      print('❌ API KEY inválida - Usando fallback');
      print('🔍 [GEMINI] ════════════════════════════════════════\n');
      return AnalisisNutricional.fallback(categoria);
    }

    try {
      final prompt = _construirPrompt(
        nombreReceta: nombreReceta,
        categoria: categoria,
        ingredientes: ingredientes,
      );

      print('📤 Enviando solicitud a Gemini API...');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 150,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'}
          ]
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏰ TIMEOUT');
          throw Exception('Timeout');
        },
      );

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (!data.containsKey('candidates') || 
            data['candidates'] == null || 
            data['candidates'].isEmpty) {
          print('⚠️ Sin candidates - Usando fallback');
          print('🔍 [GEMINI] ════════════════════════════════════════\n');
          return AnalisisNutricional.fallback(categoria);
        }

        final candidate = data['candidates'][0];
        
        if (candidate.containsKey('finishReason')) {
          print('🏁 Finish Reason: ${candidate['finishReason']}');
        }
        
        if (candidate.containsKey('finishReason') && 
            (candidate['finishReason'] == 'SAFETY' || 
             candidate['finishReason'] == 'RECITATION')) {
          print('🚫 Bloqueado por: ${candidate['finishReason']}');
          print('🔍 [GEMINI] ════════════════════════════════════════\n');
          return AnalisisNutricional.fallback(categoria);
        }
        
        if (!candidate.containsKey('content') || 
            candidate['content'] == null ||
            !candidate['content'].containsKey('parts') ||
            candidate['content']['parts'] == null ||
            candidate['content']['parts'].isEmpty) {
          print('⚠️ Content inválido - Usando fallback');
          print('🔍 [GEMINI] ════════════════════════════════════════\n');
          return AnalisisNutricional.fallback(categoria);
        }

        final text = candidate['content']['parts'][0]['text'];
        
        if (text == null || text.toString().trim().isEmpty) {
          print('⚠️ Text vacío - Usando fallback');
          print('🔍 [GEMINI] ════════════════════════════════════════\n');
          return AnalisisNutricional.fallback(categoria);
        }
        
        print('✅ Respuesta recibida:');
        print('─────────────────────────────────────────────────────');
        print(text.trim());
        print('─────────────────────────────────────────────────────');
        
        final analisis = _parsearRespuesta(text.trim(), categoria);
        _cache[recetaId] = analisis;
        
        print('💾 Guardado en caché');
        print('🔍 [GEMINI] ════════════════════════════════════════\n');
        
        return analisis;
      } else {
        print('❌ Error: ${response.statusCode}');
        print('Body: ${response.body}');
        print('🔍 [GEMINI] ════════════════════════════════════════\n');
        return AnalisisNutricional.fallback(categoria);
      }
    } catch (e) {
      print('❌ Excepción: $e');
      print('🔍 [GEMINI] ════════════════════════════════════════\n');
      return AnalisisNutricional.fallback(categoria);
    }
  }

  String _construirPrompt({
  required String nombreReceta,
  required String categoria,
  required List<String> ingredientes,
}) {
  final ingredientesTexto = ingredientes.take(10).join(', ');

  return '''Analiza ESPECÍFICAMENTE estos ingredientes de "$nombreReceta": $ingredientesTexto

Responde en este formato EXACTO:

Evaluación:
- Proteínas: [Alto/Medio/Bajo]
- Grasas: [Alto/Medio/Bajo - tipo]
- Carbohidratos: [Alto/Medio/Bajo]
- Calorías: [Alto/Medio/Bajo]

Recomendación:
- Recomendable para: [tipo de personas/dietas]
- No recomendable para: [condiciones/objetivos]
- Consumo sugerido: [regular/ocasional/moderar]

Sin íconos. Sin markdown. Texto simple.''';
}
  AnalisisNutricional _parsearRespuesta(String respuesta, String categoria) {
    try {
      String tipo = 'neutral';
      String resumen = respuesta.trim();

      // Limpiar cualquier markdown
      resumen = resumen
          .replaceAll('**', '')
          .replaceAll('*', '')
          .replaceAll('##', '')
          .replaceAll('#', '')
          .trim();

      // Detectar tipo según contenido
      final respuestaLower = resumen.toLowerCase();
      if (respuestaLower.contains('evitar') ||
          respuestaLower.contains('no apta') ||
          respuestaLower.contains('alto en azúcar') ||
          respuestaLower.contains('alta en grasas saturadas') ||
          respuestaLower.contains('alto en grasas')) {
        tipo = 'advertencia';
      } else if (respuestaLower.contains('apta para') ||
                 respuestaLower.contains('excelente para') ||
                 respuestaLower.contains('saludable') ||
                 respuestaLower.contains('rica en omega')) {
        tipo = 'beneficio';
      } else {
        tipo = 'neutral';
      }

      if (resumen.length < 50) {
        resumen = AnalisisNutricional._getFallbackPorCategoria(categoria);
      }

      return AnalisisNutricional(
        resumen: resumen,
        tipo: tipo,
        puntosClave: [],
      );
    } catch (e) {
      return AnalisisNutricional.fallback(categoria);
    }
  }

  void limpiarCache() {
    _cache.clear();
    print('🗑️ Caché limpiado');
  }
}