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
    print('🔑 [GEMINI] API KEY length: ${apiKey.length}');
    print('🔑 [GEMINI] API KEY primeros 10 chars: ${apiKey.length >= 10 ? apiKey.substring(0, 10) : apiKey}...');
    if (apiKey.isEmpty) {
      print('❌ [GEMINI] API KEY VACÍA');
    } else {
      print('✅ [GEMINI] API KEY configurada - Usando gemini-2.5-flash');
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
    print('🥘 Ingredientes (${ingredientes.length}): ${ingredientes.take(3).join(", ")}...');

    if (_cache.containsKey(recetaId)) {
      print('✅ Encontrado en caché');
      print('🔍 [GEMINI] ════════════════════════════════════════\n');
      return _cache[recetaId]!;
    }

    if (apiKey.isEmpty || apiKey.length < 20) {
      print('❌ API KEY inválida (length: ${apiKey.length}) - Usando fallback');
      print('🔍 [GEMINI] ════════════════════════════════════════\n');
      return AnalisisNutricional.fallback(categoria);
    }

    const maxIntentos = 2;
    for (int intento = 1; intento <= maxIntentos; intento++) {
      try {
        final prompt = _construirPromptMejorado(
          nombreReceta: nombreReceta,
          categoria: categoria,
          ingredientes: ingredientes,
        );

        print('📤 Enviando solicitud a Gemini API (intento $intento/$maxIntentos)...');
        print('📊 Tokens máximos: 2000');

        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'
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
              'temperature': 0.4,
              'maxOutputTokens': 2000,
              'topP': 0.95,
              'topK': 40,
            },
            'safetySettings': [
              {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'}
            ]
          }),
        ).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('⏰ TIMEOUT después de 20 segundos');
            throw Exception('Timeout');
          },
        );

        print('📥 Status Code: ${response.statusCode}');

        if (response.statusCode == 429) {
          print('⚠️ RATE LIMIT (429) alcanzado');
          if (intento < maxIntentos) {
            print('⏳ Esperando 35 segundos antes de reintentar...');
            await Future.delayed(const Duration(seconds: 35));
            continue;
          } else {
            print('❌ Rate limit persistente después de $maxIntentos intentos');
            print('🔄 Usando análisis de respaldo');
            print('🔍 [GEMINI] ════════════════════════════════════════\n');
            return AnalisisNutricional.fallback(categoria);
          }
        }

        if (response.statusCode == 400) {
          print('❌ ERROR 400 - Bad Request');
          print('📦 Response body: ${response.body}');
          print('🔍 [GEMINI] ════════════════════════════════════════\n');
          return AnalisisNutricional.fallback(categoria);
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          print('❌ ERROR ${response.statusCode} - API KEY INVÁLIDA O SIN PERMISOS');
          print('📦 Response body: ${response.body}');
          print('🔍 [GEMINI] ════════════════════════════════════════\n');
          return AnalisisNutricional.fallback(categoria);
        }

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // 🆕 LOG COMPLETO DE LA RESPUESTA
          print('📦 ═══ RESPUESTA COMPLETA DE GEMINI ═══');
          print(json.encode(data));
          print('📦 ═════════════════════════════════════\n');
          
          if (!data.containsKey('candidates') || 
              data['candidates'] == null || 
              data['candidates'].isEmpty) {
            print('⚠️ Sin candidates en la respuesta - Usando fallback');
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
            print('🚫 Contenido bloqueado por: ${candidate['finishReason']}');
            if (candidate.containsKey('safetyRatings')) {
              print('🛡️ Safety Ratings: ${candidate['safetyRatings']}');
            }
            print('🔍 [GEMINI] ════════════════════════════════════════\n');
            return AnalisisNutricional.fallback(categoria);
          }
          
          try {
            final content = candidate['content'];
            
            if (content == null) {
              print('⚠️ Content es null - Usando fallback');
              print('🔍 [GEMINI] ════════════════════════════════════════\n');
              return AnalisisNutricional.fallback(categoria);
            }
            
            dynamic text;
            
            if (content.containsKey('parts') && content['parts'] != null && content['parts'].isNotEmpty) {
              text = content['parts'][0]['text'];
              print('✅ Text extraído de content.parts[0].text');
            } else if (content.containsKey('text')) {
              text = content['text'];
              print('✅ Text extraído de content.text');
            } else {
              print('⚠️ No se encontró texto en content');
              print('📦 Content structure: ${content.keys}');
              print('🔍 [GEMINI] ════════════════════════════════════════\n');
              return AnalisisNutricional.fallback(categoria);
            }
            
            if (text == null || text.toString().trim().isEmpty) {
              print('⚠️ Text es null o vacío - Usando fallback');
              print('🔍 [GEMINI] ════════════════════════════════════════\n');
              return AnalisisNutricional.fallback(categoria);
            }
            
            print('✅ Respuesta recibida exitosamente');
            print('📏 Longitud: ${text.toString().length} caracteres');
            print('📄 Primeros 100 chars: ${text.toString().substring(0, text.toString().length > 100 ? 100 : text.toString().length)}...');
            
            final analisis = _parsearRespuesta(text.trim(), categoria);
            _cache[recetaId] = analisis;
            
            print('💾 Análisis guardado en caché');
            print('🎯 Tipo detectado: ${analisis.tipo}');
            print('🔍 [GEMINI] ════════════════════════════════════════\n');
            
            return analisis;
          } catch (e) {
            print('❌ Error procesando content: $e');
            print('🔍 [GEMINI] ════════════════════════════════════════\n');
            return AnalisisNutricional.fallback(categoria);
          }
        } else {
          print('❌ Status Code inesperado: ${response.statusCode}');
          print('📦 Response body: ${response.body}');
          
          if (intento < maxIntentos) {
            print('🔄 Reintentando en 2 segundos...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          
          print('🔍 [GEMINI] ════════════════════════════════════════\n');
          return AnalisisNutricional.fallback(categoria);
        }
      } catch (e, stackTrace) {
        print('❌ Excepción capturada (intento $intento/$maxIntentos)');
        print('💥 Error: $e');
        print('📚 Stack trace: $stackTrace');
        
        if (intento < maxIntentos) {
          print('🔄 Reintentando después de error en 2 segundos...');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        
        print('🔍 [GEMINI] ════════════════════════════════════════\n');
        return AnalisisNutricional.fallback(categoria);
      }
    }

    print('❌ Todos los intentos fallaron - Retornando fallback');
    return AnalisisNutricional.fallback(categoria);
  }

  String _construirPromptMejorado({
    required String nombreReceta,
    required String categoria,
    required List<String> ingredientes,
  }) {
    final ingredientesTexto = ingredientes.take(10).join(', ');

    return '''Eres un nutricionista. Analiza esta receta de forma BREVE Y CONCISA:

RECETA: "$nombreReceta"
INGREDIENTES: $ingredientesTexto

Responde en MÁXIMO 120 palabras usando este formato EXACTO:

ANÁLISIS NUTRICIONAL:
- Calorías: [cantidad aproximada] kcal por porción
- Proteínas: [cantidad]g - [fuente principal]
- Grasas: [cantidad]g - [tipo: saturadas/insaturadas]
- Carbohidratos: [cantidad]g - [simples/complejos]

RECOMENDACIÓN:
[2-3 líneas sobre para quién es ideal, precauciones y frecuencia sugerida]

RESPONDE EN ESPAÑOL. SIN MARKDOWN. MÁXIMO 120 PALABRAS. SÉ DIRECTO Y PRECISO.''';
  }

  AnalisisNutricional _parsearRespuesta(String respuesta, String categoria) {
    try {
      String tipo = 'neutral';
      String resumen = respuesta.trim();

      resumen = resumen
          .replaceAll('**', '')
          .replaceAll('##', '')
          .replaceAll('#', '')
          .trim();

      final respuestaLower = resumen.toLowerCase();
      if (respuestaLower.contains('evitar') ||
          respuestaLower.contains('no recomendable') ||
          respuestaLower.contains('alto riesgo') ||
          respuestaLower.contains('precaución') ||
          respuestaLower.contains('alta en grasas saturadas') ||
          respuestaLower.contains('alto en azúcar')) {
        tipo = 'advertencia';
      } else if (respuestaLower.contains('recomendable para') ||
                 respuestaLower.contains('excelente para') ||
                 respuestaLower.contains('beneficios') ||
                 respuestaLower.contains('saludable') ||
                 respuestaLower.contains('rica en omega') ||
                 respuestaLower.contains('alto en proteínas')) {
        tipo = 'beneficio';
      } else {
        tipo = 'neutral';
      }

      if (resumen.length < 100) {
        print('⚠️ Respuesta muy corta (${resumen.length} chars) - Usando fallback');
        resumen = AnalisisNutricional._getFallbackPorCategoria(categoria);
      }

      return AnalisisNutricional(
        resumen: resumen,
        tipo: tipo,
        puntosClave: [],
      );
    } catch (e) {
      print('❌ Error parseando respuesta: $e');
      return AnalisisNutricional.fallback(categoria);
    }
  }

  void limpiarCache() {
    _cache.clear();
    print('🗑️ Caché limpiado');
  }
}