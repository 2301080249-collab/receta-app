class Estudiante {
  final String id;
  final String usuarioId;
  final String? codigoEstudiante;
  final int cicloActual;
  final String? seccion;
  final String? telefono;
  final String? fechaNacimiento;

  Estudiante({
    required this.id,
    required this.usuarioId,
    this.codigoEstudiante,
    required this.cicloActual,
    this.seccion,
    this.telefono,
    this.fechaNacimiento,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'],
      usuarioId: json['usuario_id'],
      codigoEstudiante: json['codigo_estudiante'],
      cicloActual: json['ciclo_actual'] ?? 1,
      seccion: json['seccion'],
      telefono: json['telefono'],
      fechaNacimiento: json['fecha_nacimiento'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'codigo_estudiante': codigoEstudiante,
      'ciclo_actual': cicloActual,
      'seccion': seccion,
      'telefono': telefono,
      'fecha_nacimiento': fechaNacimiento,
    };
  }
}
