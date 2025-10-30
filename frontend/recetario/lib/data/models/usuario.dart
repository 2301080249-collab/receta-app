class Usuario {
  final String id;
  final String email;
  final String nombreCompleto;
  final String rol;
  final String? codigo;
  final String? telefono;
  final String? ciclo;
  final bool primeraVez;
  final String? avatarUrl;
  final bool activo;
  
  // ✅ Info del estudiante (si existe)
  final int? cicloActual;
  final String? seccion;

  Usuario({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
    this.codigo,
    this.telefono,
    this.ciclo,
    required this.primeraVez,
    this.avatarUrl,
    required this.activo,
    this.cicloActual,
    this.seccion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    int? cicloActual;
    String? seccion;
    
    // ✅ CORREGIDO: Parsear datos del estudiante (Supabase lo devuelve como ARRAY)
    if (json['estudiantes'] != null) {
      if (json['estudiantes'] is List && (json['estudiantes'] as List).isNotEmpty) {
        // Es una lista, tomar el primer elemento
        final estudianteData = (json['estudiantes'] as List).first;
        cicloActual = estudianteData['ciclo_actual'];
        seccion = estudianteData['seccion'];
      } else if (json['estudiantes'] is Map) {
        // Es un mapa directo (por si acaso)
        final estudianteMap = json['estudiantes'] as Map<String, dynamic>;
        cicloActual = estudianteMap['ciclo_actual'];
        seccion = estudianteMap['seccion'];
      }
    }
    
    return Usuario(
      id: json['id'],
      email: json['email'],
      nombreCompleto: json['nombre_completo'],
      rol: json['rol'],
      codigo: json['codigo'],
      telefono: json['telefono'],
      ciclo: json['ciclo'],
      primeraVez: json['primera_vez'] ?? true,
      avatarUrl: json['avatar_url'],
      activo: json['activo'] ?? true,
      cicloActual: cicloActual,
      seccion: seccion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre_completo': nombreCompleto,
      'rol': rol,
      'codigo': codigo,
      'primera_vez': primeraVez,
      'avatar_url': avatarUrl,
      'activo': activo,
    };
  }

  // ✅ Helper para mostrar ciclo en romano
  String get cicloRomano {
    if (cicloActual == null) return '-';
    const mapa = {
      1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
      6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X',
    };
    return mapa[cicloActual] ?? cicloActual.toString();
  }

  // ✅ Helper para mostrar ciclo y sección completo
  String get cicloSeccionCompleto {
    if (cicloActual == null) return 'Sin ciclo asignado';
    final cicloTexto = 'Ciclo $cicloRomano';
    if (seccion != null && seccion!.isNotEmpty) {
      return '$cicloTexto - Sección $seccion';
    }
    return cicloTexto;
  }

  Usuario copyWith({
    String? id,
    String? email,
    String? nombreCompleto,
    String? rol,
    String? codigo,
    bool? primeraVez,
    String? avatarUrl,
    bool? activo,
    int? cicloActual,
    String? seccion,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      rol: rol ?? this.rol,
      codigo: codigo ?? this.codigo,
      primeraVez: primeraVez ?? this.primeraVez,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      activo: activo ?? this.activo,
      cicloActual: cicloActual ?? this.cicloActual,
      seccion: seccion ?? this.seccion,
    );
  }
}