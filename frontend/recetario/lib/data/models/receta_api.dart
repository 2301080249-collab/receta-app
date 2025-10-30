/// Modelo para recetas obtenidas de TheMealDB API
class RecetaApi {
  final String id;
  final String nombre;
  final String? categoria;
  final String? area;
  final String? instrucciones;
  final String? imagenUrl;
  final String? videoUrl;
  final Map<String, String> ingredientes; // ingrediente -> medida

  RecetaApi({
    required this.id,
    required this.nombre,
    this.categoria,
    this.area,
    this.instrucciones,
    this.imagenUrl,
    this.videoUrl,
    this.ingredientes = const {},
  });

  /// Parsear desde JSON de TheMealDB
  factory RecetaApi.fromJson(Map<String, dynamic> json) {
    // Extraer ingredientes dinámicamente (strIngredient1-20, strMeasure1-20)
    final ingredientes = <String, String>{};
    
    for (int i = 1; i <= 20; i++) {
      final ingrediente = json['strIngredient$i']?.toString().trim() ?? '';
      final medida = json['strMeasure$i']?.toString().trim() ?? '';
      
      if (ingrediente.isNotEmpty && ingrediente.toLowerCase() != 'null') {
        ingredientes[ingrediente] = medida.isNotEmpty ? medida : '';
      }
    }

    return RecetaApi(
      id: json['idMeal'] ?? '',
      nombre: json['strMeal'] ?? 'Sin nombre',
      categoria: json['strCategory'],
      area: json['strArea'],
      instrucciones: json['strInstructions'],
      imagenUrl: json['strMealThumb'],
      videoUrl: json['strYoutube'],
      ingredientes: ingredientes,
    );
  }

  /// Convertir a JSON (para guardar localmente)
  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': nombre,
      'strCategory': categoria,
      'strArea': area,
      'strInstructions': instrucciones,
      'strMealThumb': imagenUrl,
      'strYoutube': videoUrl,
      'ingredientes': ingredientes,
    };
  }

  /// Crear copia con campos modificados
  RecetaApi copyWith({
    String? id,
    String? nombre,
    String? categoria,
    String? area,
    String? instrucciones,
    String? imagenUrl,
    String? videoUrl,
    Map<String, String>? ingredientes,
  }) {
    return RecetaApi(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      area: area ?? this.area,
      instrucciones: instrucciones ?? this.instrucciones,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      ingredientes: ingredientes ?? this.ingredientes,
    );
  }
}