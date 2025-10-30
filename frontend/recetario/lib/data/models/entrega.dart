class Entrega {
  final String id;
  final String tareaId;
  final String estudianteId;
  final String titulo;
  final String? descripcion;
  final DateTime fechaEntrega;
  final int diasRetraso;
  final double penalizacionAplicada;
  final double? calificacion;
  final String? comentarioDocente;
  final String estado; // pendiente, evaluada, rechazada
  final bool entregaTardia;
  final DateTime createdAt;
  final List<ArchivoEntrega>? archivos;
  final EstudianteInfo? estudiante;

  Entrega({
    required this.id,
    required this.tareaId,
    required this.estudianteId,
    required this.titulo,
    this.descripcion,
    required this.fechaEntrega,
    required this.diasRetraso,
    required this.penalizacionAplicada,
    this.calificacion,
    this.comentarioDocente,
    required this.estado,
    required this.entregaTardia,
    required this.createdAt,
    this.archivos,
    this.estudiante,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) {
    return Entrega(
      id: json['id'],
      tareaId: json['tarea_id'],
      estudianteId: json['estudiante_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      diasRetraso: json['dias_retraso'] ?? 0,
      penalizacionAplicada: json['penalizacion_aplicada']?.toDouble() ?? 0,
      calificacion: json['calificacion']?.toDouble(),
      comentarioDocente: json['comentario_docente'],
      estado: json['estado'] ?? 'pendiente',
      entregaTardia: json['entrega_tardia'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      archivos: json['archivos'] != null
          ? (json['archivos'] as List)
              .map((a) => ArchivoEntrega.fromJson(a))
              .toList()
          : null,
      estudiante: json['estudiante'] != null
          ? EstudianteInfo.fromJson(json['estudiante'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tarea_id': tareaId,
      'titulo': titulo,
      'descripcion': descripcion,
    };
  }

  bool get estaCalificada => calificacion != null;
  bool get estaPendiente => estado == 'pendiente';
  
  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente de calificación';
      case 'evaluada':
        return 'Calificada';
      case 'rechazada':
        return 'Rechazada';
      default:
        return estado;
    }
  }
}

class ArchivoEntrega {
  final String id;
  final String entregaId;
  final String nombreArchivo;
  final String urlArchivo;
  final String? tipoArchivo;
  final double? tamanoMb;
  final DateTime uploadedAt;

  ArchivoEntrega({
    required this.id,
    required this.entregaId,
    required this.nombreArchivo,
    required this.urlArchivo,
    this.tipoArchivo,
    this.tamanoMb,
    required this.uploadedAt,
  });

  factory ArchivoEntrega.fromJson(Map<String, dynamic> json) {
    return ArchivoEntrega(
      id: json['id'],
      entregaId: json['entrega_id'],
      nombreArchivo: json['nombre_archivo'],
      urlArchivo: json['url_archivo'],
      tipoArchivo: json['tipo_archivo'],
      tamanoMb: json['tamano_mb']?.toDouble(),
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  String get extension {
    return nombreArchivo.split('.').last.toLowerCase();
  }

  bool get esImagen {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  bool get esVideo {
    return ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
  }

  bool get esPdf {
    return extension == 'pdf';
  }

  String get tamanoFormateado {
    if (tamanoMb == null) return '';
    if (tamanoMb! < 1) return '${(tamanoMb! * 1024).toStringAsFixed(0)} KB';
    return '${tamanoMb!.toStringAsFixed(1)} MB';
  }

  String get iconoTipo {
    if (esImagen) return '🖼️';
    if (esVideo) return '🎥';
    if (esPdf) return '📄';
    return '📎';
  }
}

class EstudianteInfo {
  final String usuarioId;
  final String? codigoEstudiante;
  // final String grado; // ← ELIMINAR
  final String? seccion;
  final String nombreCompleto;
  final String email;
  final String? avatarUrl;

  EstudianteInfo({
    required this.usuarioId,
    this.codigoEstudiante,
    // required this.grado, // ← ELIMINAR
    this.seccion,
    required this.nombreCompleto,
    required this.email,
    this.avatarUrl,
  });

  factory EstudianteInfo.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] ?? {};
    
    return EstudianteInfo(
      usuarioId: json['usuario_id'] ?? '',
      codigoEstudiante: json['codigo_estudiante'],
      // grado: json['grado'] ?? '', // ← ELIMINAR
      seccion: json['seccion'],
      nombreCompleto: usuario['nombre_completo'] ?? '',
      email: usuario['email'] ?? '',
      avatarUrl: usuario['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'codigo_estudiante': codigoEstudiante,
      // 'grado': grado, // ← ELIMINAR
      'seccion': seccion,
      'usuario': {
        'nombre_completo': nombreCompleto,
        'email': email,
        'avatar_url': avatarUrl,
      }
    };
  }
}