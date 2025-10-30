/// Modelo de datos para Docente
class Docente {
  final String id;
  final String codigoDocente;
  final String especialidad;
  final String? gradoAcademico;
  final String? departamento;

  Docente({
    required this.id,
    required this.codigoDocente,
    required this.especialidad,
    this.gradoAcademico,
    this.departamento,
  });

  /// Crear desde JSON (respuesta del backend)
  factory Docente.fromJson(Map<String, dynamic> json) {
    return Docente(
      id: json['_id'] ?? json['id'] ?? '',
      codigoDocente: json['codigo'] ?? json['codigo_docente'] ?? '',
      especialidad: json['especialidad'] ?? '',
      gradoAcademico: json['grado_academico'],
      departamento: json['departamento'],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_docente': codigoDocente,
      'especialidad': especialidad,
      'grado_academico': gradoAcademico,
      'departamento': departamento,
    };
  }

  /// Copiar con modificaciones
  Docente copyWith({
    String? id,
    String? codigoDocente,
    String? especialidad,
    String? gradoAcademico,
    String? departamento,
  }) {
    return Docente(
      id: id ?? this.id,
      codigoDocente: codigoDocente ?? this.codigoDocente,
      especialidad: especialidad ?? this.especialidad,
      gradoAcademico: gradoAcademico ?? this.gradoAcademico,
      departamento: departamento ?? this.departamento,
    );
  }

  @override
  String toString() {
    return 'Docente(id: $id, codigo: $codigoDocente, especialidad: $especialidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Docente && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
