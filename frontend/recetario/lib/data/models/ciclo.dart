class Ciclo {
  final String id;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;
  final int duracionSemanas;
  final bool activo;
  final DateTime createdAt;

  Ciclo({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.duracionSemanas,
    required this.activo,
    required this.createdAt,
  });

  factory Ciclo.fromJson(Map<String, dynamic> json) {
    return Ciclo(
      id: json['id'],
      nombre: json['nombre'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      duracionSemanas: json['duracion_semanas'] ?? 16,
      activo: json['activo'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'duracion_semanas': duracionSemanas,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper para mostrar el rango de fechas
  String get rangoFechas {
    return '$fechaInicio - $fechaFin';
  }

  // Helper para el badge de estado
  String get estadoTexto {
    return activo ? 'Activo' : 'Inactivo';
  }

  // CopyWith para actualizaciones inmutables
  Ciclo copyWith({
    String? id,
    String? nombre,
    String? fechaInicio,
    String? fechaFin,
    int? duracionSemanas,
    bool? activo,
    DateTime? createdAt,
  }) {
    return Ciclo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      duracionSemanas: duracionSemanas ?? this.duracionSemanas,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
