class Categoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final int orden;
  final bool activo;
  final DateTime? createdAt;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
    required this.orden,
    required this.activo,
    this.createdAt,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      orden: json['orden'] as int? ?? 0,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
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
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  String toString() => 'Categoria(id: $id, nombre: $nombre, orden: $orden)';
}