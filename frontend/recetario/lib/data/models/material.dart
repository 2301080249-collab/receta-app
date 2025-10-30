class Material {
  final String id;
  final String temaId;
  final String titulo;
  final String tipo; // pdf, video, link, documento, imagen
  final String urlArchivo;
  final double? tamanoMb;
  final int? duracionMinutos;
  final String? descripcion;
  final int orden;
  final bool activo;
  final DateTime createdAt;
  
  // Para estudiante
  final bool? vistoPorMi;
  
  // Para docente
  final int? cantidadVistos;
  final int? totalEstudiantes;

  Material({
    required this.id,
    required this.temaId,
    required this.titulo,
    required this.tipo,
    required this.urlArchivo,
    this.tamanoMb,
    this.duracionMinutos,
    this.descripcion,
    required this.orden,
    required this.activo,
    required this.createdAt,
    this.vistoPorMi,
    this.cantidadVistos,
    this.totalEstudiantes,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id'],
      temaId: json['tema_id'],
      titulo: json['titulo'],
      tipo: json['tipo'],
      urlArchivo: json['url_archivo'],
      tamanoMb: json['tamano_mb']?.toDouble(),
      duracionMinutos: json['duracion_minutos'],
      descripcion: json['descripcion'],
      orden: json['orden'],
      activo: json['activo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      vistoPorMi: json['visto_por_mi'],
      cantidadVistos: json['cantidad_vistos'],
      totalEstudiantes: json['total_estudiantes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tema_id': temaId,
      'titulo': titulo,
      'tipo': tipo,
      'url_archivo': urlArchivo,
      'tamano_mb': tamanoMb,
      'duracion_minutos': duracionMinutos,
      'descripcion': descripcion,
      'orden': orden,
    };
  }

  String get tipoIcono {
    switch (tipo) {
      case 'pdf':
        return '📄';
      case 'video':
        return '🎥';
      case 'link':
        return '🔗';
      case 'imagen':
        return '🖼️';
      default:
        return '📎';
    }
  }

  String get duracionFormateada {
    if (duracionMinutos == null) return '';
    if (duracionMinutos! < 60) return '${duracionMinutos}min';
    final horas = duracionMinutos! ~/ 60;
    final mins = duracionMinutos! % 60;
    return '${horas}h ${mins}min';
  }

  String get tamanoFormateado {
    if (tamanoMb == null) return '';
    if (tamanoMb! < 1) return '${(tamanoMb! * 1024).toStringAsFixed(0)} KB';
    return '${tamanoMb!.toStringAsFixed(1)} MB';
  }
}