/// Modelo de datos para Administrador
class Administrador {
  final String id;
  final String codigoAdmin;
  final String? departamento;
  final List<String> permisos;

  Administrador({
    required this.id,
    required this.codigoAdmin,
    this.departamento,
    this.permisos = const [],
  });

  /// Crear desde JSON (respuesta del backend)
  factory Administrador.fromJson(Map<String, dynamic> json) {
    return Administrador(
      id: json['_id'] ?? json['id'] ?? '',
      codigoAdmin: json['codigo'] ?? json['codigo_admin'] ?? '',
      departamento: json['departamento'],
      permisos: json['permisos'] != null
          ? List<String>.from(json['permisos'])
          : [],
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_admin': codigoAdmin,
      'departamento': departamento,
      'permisos': permisos,
    };
  }

  /// Copiar con modificaciones
  Administrador copyWith({
    String? id,
    String? codigoAdmin,
    String? departamento,
    List<String>? permisos,
  }) {
    return Administrador(
      id: id ?? this.id,
      codigoAdmin: codigoAdmin ?? this.codigoAdmin,
      departamento: departamento ?? this.departamento,
      permisos: permisos ?? this.permisos,
    );
  }

  /// Verificar si tiene un permiso específico
  bool tienePermiso(String permiso) {
    return permisos.contains(permiso);
  }

  @override
  String toString() {
    return 'Administrador(id: $id, codigo: $codigoAdmin, departamento: $departamento)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Administrador && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
