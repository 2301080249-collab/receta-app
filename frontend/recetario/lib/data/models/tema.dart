import 'material.dart';
import 'tarea.dart';

class Tema {
  final String id;
  final String cursoId;
  final String titulo;
  final String? descripcion;
  final int orden;
  final DateTime? fechaDesbloqueo;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Material>? materiales;
  final List<Tarea>? tareas;

  Tema({
    required this.id,
    required this.cursoId,
    required this.titulo,
    this.descripcion,
    required this.orden,
    this.fechaDesbloqueo,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    this.materiales,
    this.tareas,
  });

  factory Tema.fromJson(Map<String, dynamic> json) {
    return Tema(
      id: json['id'],
      cursoId: json['curso_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      orden: json['orden'],
      fechaDesbloqueo: json['fecha_desbloqueo'] != null
          ? DateTime.parse(json['fecha_desbloqueo'])
          : null,
      activo: json['activo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      materiales: json['materiales'] != null
          ? (json['materiales'] as List)
              .map((m) => Material.fromJson(m))
              .toList()
          : null,
      tareas: json['tareas'] != null
          ? (json['tareas'] as List).map((t) => Tarea.fromJson(t)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curso_id': cursoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'orden': orden,
      'fecha_desbloqueo': fechaDesbloqueo?.toIso8601String(),
    };
  }

  bool get estaBloqueado {
    if (fechaDesbloqueo == null) return false;
    return DateTime.now().isBefore(fechaDesbloqueo!);
  }
}