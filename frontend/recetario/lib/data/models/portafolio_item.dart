import 'receta_api.dart';

/// Modelo para recetas guardadas en el portafolio local
class PortafolioItem {
  final RecetaApi receta;
  final int likes;
  final bool likedByUser;
  final List<Comentario> comentarios;
  final DateTime fechaAgregado;
  final String? comentarioUsuario; // Comentario al agregar la receta

  PortafolioItem({
    required this.receta,
    this.likes = 0,
    this.likedByUser = false,
    this.comentarios = const [],
    required this.fechaAgregado,
    this.comentarioUsuario,
  });

  /// Parsear desde JSON (SharedPreferences)
  factory PortafolioItem.fromJson(Map<String, dynamic> json) {
    return PortafolioItem(
      receta: RecetaApi.fromJson(json['receta'] ?? {}),
      likes: json['likes'] ?? 0,
      likedByUser: json['likedByUser'] ?? false,
      comentarios: (json['comentarios'] as List?)
              ?.map((c) => Comentario.fromJson(c))
              .toList() ??
          [],
      fechaAgregado: DateTime.parse(
        json['fechaAgregado'] ?? DateTime.now().toIso8601String(),
      ),
      comentarioUsuario: json['comentarioUsuario'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'receta': receta.toJson(),
      'likes': likes,
      'likedByUser': likedByUser,
      'comentarios': comentarios.map((c) => c.toJson()).toList(),
      'fechaAgregado': fechaAgregado.toIso8601String(),
      'comentarioUsuario': comentarioUsuario,
    };
  }

  /// Crear copia con campos modificados
  PortafolioItem copyWith({
    RecetaApi? receta,
    int? likes,
    bool? likedByUser,
    List<Comentario>? comentarios,
    DateTime? fechaAgregado,
    String? comentarioUsuario,
  }) {
    return PortafolioItem(
      receta: receta ?? this.receta,
      likes: likes ?? this.likes,
      likedByUser: likedByUser ?? this.likedByUser,
      comentarios: comentarios ?? this.comentarios,
      fechaAgregado: fechaAgregado ?? this.fechaAgregado,
      comentarioUsuario: comentarioUsuario ?? this.comentarioUsuario,
    );
  }

  /// Toggle like
  PortafolioItem toggleLike() {
    return copyWith(
      likedByUser: !likedByUser,
      likes: likedByUser ? likes - 1 : likes + 1,
    );
  }

  /// Agregar comentario
  PortafolioItem agregarComentario(Comentario comentario) {
    return copyWith(
      comentarios: [...comentarios, comentario],
    );
  }
}

/// Modelo de comentario
class Comentario {
  final String id;
  final String usuario;
  final String texto;
  final DateTime fecha;

  Comentario({
    required this.id,
    required this.usuario,
    required this.texto,
    required this.fecha,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'] ?? '',
      usuario: json['usuario'] ?? 'Anónimo',
      texto: json['texto'] ?? '',
      fecha: DateTime.parse(
        json['fecha'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario': usuario,
      'texto': texto,
      'fecha': fecha.toIso8601String(),
    };
  }
}