/// Modelo de Portafolio desde el backend
class Portafolio {
  final String id;
  final String estudianteId;
  final String titulo;
  final String? descripcion;
  final String ingredientes;
  final String preparacion;
  final List<String> fotos;
  final String? videoUrl;
  final String categoriaId;
  final String tipoReceta; // 'propia' o 'api'
  final String? fuenteApiId;
  final String visibilidad; // 'publica' o 'privada'
  final String? nivelAlcanzado;
  final int likes;
  final int vistas;
  final bool esDestacada;
  final bool esCertificada;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos adicionales cuando viene con info del estudiante
  final String? nombreEstudiante;
  final String? avatarEstudiante;
  final String? codigoEstudiante;

  Portafolio({
    required this.id,
    required this.estudianteId,
    required this.titulo,
    this.descripcion,
    required this.ingredientes,
    required this.preparacion,
    required this.fotos,
    this.videoUrl,
    required this.categoriaId,
    required this.tipoReceta,
    this.fuenteApiId,
    required this.visibilidad,
    this.nivelAlcanzado,
    required this.likes,
    required this.vistas,
    required this.esDestacada,
    required this.esCertificada,
    required this.createdAt,
    required this.updatedAt,
    this.nombreEstudiante,
    this.avatarEstudiante,
    this.codigoEstudiante,
  });

  factory Portafolio.fromJson(Map<String, dynamic> json) {
    return Portafolio(
      id: json['id'] ?? '',
      estudianteId: json['estudiante_id'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      ingredientes: json['ingredientes'] ?? '',
      preparacion: json['preparacion'] ?? '',
      fotos: json['fotos'] != null 
          ? List<String>.from(json['fotos'])
          : [],
      videoUrl: json['video_url'],
      categoriaId: json['categoria_id'] ?? '',
      tipoReceta: json['tipo_receta'] ?? 'propia',
      fuenteApiId: json['fuente_api_id'],
      visibilidad: json['visibilidad'] ?? 'publica',
      nivelAlcanzado: json['nivel_alcanzado'],
      likes: json['likes'] ?? 0,
      vistas: json['vistas'] ?? 0,
      esDestacada: json['es_destacada'] ?? false,
      esCertificada: json['es_certificada'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      nombreEstudiante: json['nombre_estudiante'],
      avatarEstudiante: json['avatar_estudiante'],
      codigoEstudiante: json['codigo_estudiante'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estudiante_id': estudianteId,
      'titulo': titulo,
      'descripcion': descripcion,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
      'fotos': fotos,
      'video_url': videoUrl,
      'categoria_id': categoriaId,
      'tipo_receta': tipoReceta,
      'fuente_api_id': fuenteApiId,
      'visibilidad': visibilidad,
      'nivel_alcanzado': nivelAlcanzado,
      'likes': likes,
      'vistas': vistas,
      'es_destacada': esDestacada,
      'es_certificada': esCertificada,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'nombre_estudiante': nombreEstudiante,
      'avatar_estudiante': avatarEstudiante,
      'codigo_estudiante': codigoEstudiante,
    };
  }

  Portafolio copyWith({
    String? id,
    String? estudianteId,
    String? titulo,
    String? descripcion,
    String? ingredientes,
    String? preparacion,
    List<String>? fotos,
    String? videoUrl,
    String? categoriaId,
    String? tipoReceta,
    String? fuenteApiId,
    String? visibilidad,
    String? nivelAlcanzado,
    int? likes,
    int? vistas,
    bool? esDestacada,
    bool? esCertificada,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nombreEstudiante,
    String? avatarEstudiante,
    String? codigoEstudiante,
  }) {
    return Portafolio(
      id: id ?? this.id,
      estudianteId: estudianteId ?? this.estudianteId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      ingredientes: ingredientes ?? this.ingredientes,
      preparacion: preparacion ?? this.preparacion,
      fotos: fotos ?? this.fotos,
      videoUrl: videoUrl ?? this.videoUrl,
      categoriaId: categoriaId ?? this.categoriaId,
      tipoReceta: tipoReceta ?? this.tipoReceta,
      fuenteApiId: fuenteApiId ?? this.fuenteApiId,
      visibilidad: visibilidad ?? this.visibilidad,
      nivelAlcanzado: nivelAlcanzado ?? this.nivelAlcanzado,
      likes: likes ?? this.likes,
      vistas: vistas ?? this.vistas,
      esDestacada: esDestacada ?? this.esDestacada,
      esCertificada: esCertificada ?? this.esCertificada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nombreEstudiante: nombreEstudiante ?? this.nombreEstudiante,
      avatarEstudiante: avatarEstudiante ?? this.avatarEstudiante,
      codigoEstudiante: codigoEstudiante ?? this.codigoEstudiante,
    );
  }
}

/// Request para crear receta
class CrearPortafolioRequest {
  final String titulo;
  final String? descripcion;
  final String ingredientes;
  final String preparacion;
  final List<String> fotos;
  final String? videoUrl;
  final String categoriaId;
  final String tipoReceta;
  final String? fuenteApiId;
  final String visibilidad;

  CrearPortafolioRequest({
    required this.titulo,
    this.descripcion,
    required this.ingredientes,
    required this.preparacion,
    required this.fotos,
    this.videoUrl,
    required this.categoriaId,
    required this.tipoReceta,
    this.fuenteApiId,
    this.visibilidad = 'publica',
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
      'fotos': fotos,
      'video_url': videoUrl,
      'categoria_id': categoriaId,
      'tipo_receta': tipoReceta,
      'fuente_api_id': fuenteApiId,
      'visibilidad': visibilidad,
    };
  }
}

/// Modelo de Comentario desde backend
class ComentarioPortafolio {
  final String id;
  final String portafolioId;
  final String usuarioId;
  final String comentario;
  final DateTime createdAt;
  
  // Campos adicionales cuando viene con info del usuario
  final String? nombreUsuario;
  final String? avatarUsuario;

  ComentarioPortafolio({
    required this.id,
    required this.portafolioId,
    required this.usuarioId,
    required this.comentario,
    required this.createdAt,
    this.nombreUsuario,
    this.avatarUsuario,
  });

  factory ComentarioPortafolio.fromJson(Map<String, dynamic> json) {
    return ComentarioPortafolio(
      id: json['id'] ?? '',
      portafolioId: json['portafolio_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      comentario: json['comentario'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      nombreUsuario: json['nombre_usuario'],
      avatarUsuario: json['avatar_usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portafolio_id': portafolioId,
      'usuario_id': usuarioId,
      'comentario': comentario,
      'created_at': createdAt.toIso8601String(),
      'nombre_usuario': nombreUsuario,
      'avatar_usuario': avatarUsuario,
    };
  }
}

/// Modelo de Categoría
class Categoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final int orden;
  final bool activo;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
    required this.orden,
    required this.activo,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      icono: json['icono'],
      orden: json['orden'] ?? 0,
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'icono': icono,
      'orden': orden,
      'activo': activo,
    };
  }
}