class Matricula {
  final String id;
  final String estudianteId;
  final String cursoId;
  final String cicloId;
  final String estado;
  final double? notaFinal;
  final String? observaciones;        // ✅ NUEVO
  final DateTime? fechaMatricula;     // ✅ NUEVO
  final DateTime createdAt;

  // Datos del estudiante (anidados)
  final String? nombreEstudiante;
  final String? codigoEstudiante;
  final int? cicloActualEstudiante;
  final String? seccionEstudiante;

  // Datos del curso (anidados)
  final String? nombreCurso;
  final int? nivelCurso;
  final String? seccionCurso;
  final String? nombreDocente;

  // Datos del ciclo académico
  final String? nombreCiclo;

  Matricula({
    required this.id,
    required this.estudianteId,
    required this.cursoId,
    required this.cicloId,
    required this.estado,
    this.notaFinal,
    this.observaciones,              // ✅ NUEVO
    this.fechaMatricula,             // ✅ NUEVO
    required this.createdAt,
    this.nombreEstudiante,
    this.codigoEstudiante,
    this.cicloActualEstudiante,
    this.seccionEstudiante,
    this.nombreCurso,
    this.nivelCurso,
    this.seccionCurso,
    this.nombreDocente,
    this.nombreCiclo,
  });

  factory Matricula.fromJson(Map<String, dynamic> json) {
    // Extraer datos del estudiante
    String? nombreEstudiante;
    String? codigoEstudiante;
    int? cicloActualEstudiante;
    String? seccionEstudiante;

    // ✅ PLURAL: estudiantes
    if (json['estudiantes'] != null) {
      final estudiante = json['estudiantes'];
      codigoEstudiante = estudiante['codigo_estudiante'];
      cicloActualEstudiante = estudiante['ciclo_actual'];
      seccionEstudiante = estudiante['seccion'];

      // ✅ PLURAL: usuarios
      if (estudiante['usuarios'] != null) {
        nombreEstudiante = estudiante['usuarios']['nombre_completo'];
      }
    }

    // Extraer datos del curso
    String? nombreCurso;
    int? nivelCurso;
    String? seccionCurso;
    String? nombreDocente;

    // ✅ PLURAL: cursos
    if (json['cursos'] != null) {
      final curso = json['cursos'];
      nombreCurso = curso['nombre'];
      nivelCurso = curso['nivel'];
      seccionCurso = curso['seccion'];

      // ✅ PLURAL: docentes y usuarios
      if (curso['docentes'] != null && curso['docentes']['usuarios'] != null) {
        nombreDocente = curso['docentes']['usuarios']['nombre_completo'];
      }
    }

    // Extraer nombre del ciclo
    String? nombreCiclo;
    // ✅ PLURAL: ciclos
    if (json['ciclos'] != null) {
      nombreCiclo = json['ciclos']['nombre'];
    }

    return Matricula(
      id: json['id'] ?? '',
      estudianteId: json['estudiante_id'] ?? '',
      cursoId: json['curso_id'] ?? '',
      cicloId: json['ciclo_id'] ?? '',
      estado: json['estado'] ?? 'activo',
      notaFinal: json['nota_final']?.toDouble(),
      observaciones: json['observaciones'],  // ✅ NUEVO
      fechaMatricula: json['fecha_matricula'] != null 
          ? DateTime.parse(json['fecha_matricula']) 
          : null,  // ✅ NUEVO
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      nombreEstudiante: nombreEstudiante,
      codigoEstudiante: codigoEstudiante,
      cicloActualEstudiante: cicloActualEstudiante,
      seccionEstudiante: seccionEstudiante,
      nombreCurso: nombreCurso,
      nivelCurso: nivelCurso,
      seccionCurso: seccionCurso,
      nombreDocente: nombreDocente,
      nombreCiclo: nombreCiclo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estudiante_id': estudianteId,
      'curso_id': cursoId,
      'ciclo_id': cicloId,
      'estado': estado,
      'nota_final': notaFinal,
      'observaciones': observaciones,  // ✅ NUEVO
      'fecha_matricula': fechaMatricula?.toIso8601String(),  // ✅ NUEVO
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ==================== HELPERS ====================

  String get estadoLabel {
    switch (estado) {
      case 'activo':
        return 'Activo';
      case 'retirado':
        return 'Retirado';
      case 'completado':
        return 'Completado';
      default:
        return estado;
    }
  }

  String get estadoEmoji {
    switch (estado) {
      case 'activo':
        return '✅';
      case 'retirado':
        return '⚠️';
      case 'completado':
        return '🎓';
      default:
        return '❓';
    }
  }

  // Convertir nivel del curso a romano
  String get nivelRomano {
    if (nivelCurso == null) return '--';
    return _intToRoman(nivelCurso!);
  }

  // Convertir ciclo actual del estudiante a romano
  String get cicloActualRomano {
    if (cicloActualEstudiante == null) return '--';
    return _intToRoman(cicloActualEstudiante!);
  }

  // Función auxiliar para convertir entero a romano
  String _intToRoman(int num) {
    const romanNumerals = [
      'I', 'II', 'III', 'IV', 'V', 
      'VI', 'VII', 'VIII', 'IX', 'X'
    ];
    if (num >= 1 && num <= 10) {
      return romanNumerals[num - 1];
    }
    return num.toString();
  }

  bool get estaActivo => estado == 'activo';
  bool get estaCompletado => estado == 'completado';
  bool get estaRetirado => estado == 'retirado';
}

// Request para crear matrícula
class CrearMatriculaRequest {
  final String estudianteId;
  final String cursoId;
  final String cicloId;
  final String? estado;           // ✅ NUEVO (opcional)
  final String? observaciones;    // ✅ NUEVO (opcional)

  CrearMatriculaRequest({
    required this.estudianteId,
    required this.cursoId,
    required this.cicloId,
    this.estado,                  // ✅ NUEVO
    this.observaciones,           // ✅ NUEVO
  });

  Map<String, dynamic> toJson() {
    final data = {
      'estudiante_id': estudianteId,
      'curso_id': cursoId,
      'ciclo_id': cicloId,
    };
    
    if (estado != null) data['estado'] = estado!;
    if (observaciones != null) data['observaciones'] = observaciones!;
    
    return data;
  }
}

// Request para matrícula masiva
class MatriculaMasivaRequest {
  final List<String> estudiantesIds;
  final String cursoId;
  final String cicloId;
  final String? estado;           // ✅ NUEVO (opcional)
  final String? observaciones;    // ✅ NUEVO (opcional)

  MatriculaMasivaRequest({
    required this.estudiantesIds,
    required this.cursoId,
    required this.cicloId,
    this.estado,                  // ✅ NUEVO
    this.observaciones,           // ✅ NUEVO
  });

  Map<String, dynamic> toJson() {
    final data = {
      'estudiantes_ids': estudiantesIds,
      'curso_id': cursoId,
      'ciclo_id': cicloId,
    };
    
    if (estado != null) data['estado'] = estado!;
    if (observaciones != null) data['observaciones'] = observaciones!;
    
    return data;
  }
}

// Request para actualizar matrícula
class ActualizarMatriculaRequest {
  final String? estado;
  final double? notaFinal;
  final String? observaciones;    // ✅ NUEVO

  ActualizarMatriculaRequest({
    this.estado, 
    this.notaFinal,
    this.observaciones,           // ✅ NUEVO
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (estado != null) data['estado'] = estado;
    if (notaFinal != null) data['nota_final'] = notaFinal;
    if (observaciones != null) data['observaciones'] = observaciones;  // ✅ NUEVO
    return data;
  }
}