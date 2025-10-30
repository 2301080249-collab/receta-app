class Curso {
  final String id;
  final String nombre;
  final String? descripcion;
  final String docenteId;
  final String cicloId;
  final int? nivel;
  final String? seccion;
  final int creditos;
  final String? horario;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Opcional: información del docente (si se incluye en la query)
  final String? docenteNombre;
  final String? cicloNombre;

  Curso({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.docenteId,
    required this.cicloId,
    this.nivel,
    this.seccion,
    required this.creditos,
    this.horario,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    this.docenteNombre,
    this.cicloNombre,
  });

  factory Curso.fromJson(Map<String, dynamic> json) {
    String? cicloNombre;
    String? docenteNombre;
    
    // ✅ LOG TEMPORAL
    print('🔍 [Curso.fromJson] json completo: $json');
    print('🔍 [Curso.fromJson] json[ciclos]: ${json['ciclos']}');
    print('🔍 [Curso.fromJson] json[docentes]: ${json['docentes']}'); // ✅ NUEVO LOG
    
    // Intentar obtener de 'ciclos' (viene del JOIN con la tabla ciclos)
    if (json['ciclos'] != null && json['ciclos'] is Map) {
      final ciclosMap = json['ciclos'] as Map<String, dynamic>;
      if (ciclosMap['nombre'] != null) {
        cicloNombre = ciclosMap['nombre'].toString().trim();
      }
    }

    // ✅ CORREGIDO: Obtener nombre del docente de la estructura anidada
    if (json['docentes'] != null && json['docentes'] is Map) {
      final docentesMap = json['docentes'] as Map<String, dynamic>;
      if (docentesMap['usuarios'] != null && docentesMap['usuarios'] is Map) {
        final usuariosMap = docentesMap['usuarios'] as Map<String, dynamic>;
        if (usuariosMap['nombre_completo'] != null) {
          docenteNombre = usuariosMap['nombre_completo'].toString().trim();
        }
      }
    }

    print('✅ [Curso.fromJson] docenteNombre extraído: $docenteNombre'); // ✅ LOG

    return Curso(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      docenteId: json['docente_id'],
      cicloId: json['ciclo_id'],
      nivel: json['nivel'] is int 
          ? json['nivel'] 
          : (json['nivel'] != null ? int.tryParse(json['nivel'].toString()) : null),
      seccion: json['seccion'],
      creditos: json['creditos'] ?? 3,
      horario: json['horario'],
      activo: json['activo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      docenteNombre: docenteNombre, // ✅ CORREGIDO
      cicloNombre: cicloNombre,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'docente_id': docenteId,
      'ciclo_id': cicloId,
      'nivel': nivel,
      'seccion': seccion,
      'creditos': creditos,
      'horario': horario,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper para mostrar el estado
  String get estadoTexto {
    return activo ? 'Activo' : 'Inactivo';
  }

  // Helper para convertir nivel a romano
  String get nivelRomano {
    const mapa = {
      1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
      6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X',
    };
    return nivel != null ? mapa[nivel] ?? '-' : '-';
  }

  // Helper para mostrar información completa
  String get infoCompleta {
    final parts = <String>[];
    if (nivel != null) parts.add('Ciclo $nivelRomano');
    if (seccion != null && seccion!.isNotEmpty) parts.add('Sección $seccion');
    if (creditos > 0) parts.add('$creditos créditos');
    if (horario != null && horario!.isNotEmpty) parts.add(horario!);
    return parts.join(' • ');
  }

  // CopyWith para actualizaciones inmutables
  Curso copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? docenteId,
    String? cicloId,
    int? nivel,
    String? seccion,
    int? creditos,
    String? horario,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? docenteNombre,
    String? cicloNombre,
  }) {
    return Curso(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      docenteId: docenteId ?? this.docenteId,
      cicloId: cicloId ?? this.cicloId,
      nivel: nivel ?? this.nivel,
      seccion: seccion ?? this.seccion,
      creditos: creditos ?? this.creditos,
      horario: horario ?? this.horario,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      docenteNombre: docenteNombre ?? this.docenteNombre,
      cicloNombre: cicloNombre ?? this.cicloNombre,
    );
  }
}