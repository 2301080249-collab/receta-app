import 'entrega.dart';

class Tarea {
  final String id;
  final String cursoId;
  final String? temaId;
  final String titulo;
  final String? descripcion;
  final int? semana;
  final DateTime fechaPublicacion;
  final DateTime fechaLimite;
  final double puntajeMaximo;
  final bool permiteEntregaTardia;
  final double penalizacionPorDia;
  final int diasTolerancia;
  final String tipo; // practica, evaluacion, proyecto
  final bool activo;
  final DateTime createdAt;
  
  // Stats para docente
  final int? totalEntregas;
  final int? entregasSinCalificar;
  final int? entregasCalificadas;
  final int? entregasPendientes;
  
  // Para estudiante
  final Entrega? miEntrega;
  final String? tiempoRestante;
  final bool? estaVencida;

  Tarea({
    required this.id,
    required this.cursoId,
    this.temaId,
    required this.titulo,
    this.descripcion,
    this.semana,
    required this.fechaPublicacion,
    required this.fechaLimite,
    required this.puntajeMaximo,
    required this.permiteEntregaTardia,
    required this.penalizacionPorDia,
    required this.diasTolerancia,
    required this.tipo,
    required this.activo,
    required this.createdAt,
    this.totalEntregas,
    this.entregasSinCalificar,
    this.entregasCalificadas,
    this.entregasPendientes,
    this.miEntrega,
    this.tiempoRestante,
    this.estaVencida,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'],
      cursoId: json['curso_id'],
      temaId: json['tema_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      semana: json['semana'],
      fechaPublicacion: DateTime.parse(json['fecha_publicacion']),
      fechaLimite: DateTime.parse(json['fecha_limite']),
      puntajeMaximo: json['puntaje_maximo'].toDouble(),
      permiteEntregaTardia: json['permite_entrega_tardia'] ?? false,
      penalizacionPorDia: json['penalizacion_por_dia']?.toDouble() ?? 0,
      diasTolerancia: json['dias_tolerancia'] ?? 0,
      tipo: json['tipo'] ?? 'practica',
      activo: json['activo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      totalEntregas: json['total_entregas'],
      entregasSinCalificar: json['entregas_sin_calificar'],
      entregasCalificadas: json['entregas_calificadas'],
      entregasPendientes: json['entregas_pendientes'],
      miEntrega: json['mi_entrega'] != null
          ? Entrega.fromJson(json['mi_entrega'])
          : null,
      tiempoRestante: json['tiempo_restante'],
      estaVencida: json['esta_vencida'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curso_id': cursoId,
      'tema_id': temaId,
      'titulo': titulo,
      'descripcion': descripcion,
      'semana': semana,
      'fecha_publicacion': fechaPublicacion.toUtc().toIso8601String(), // ✅ UTC
      'fecha_limite': fechaLimite.toUtc().toIso8601String(), // ✅ UTC
      'puntaje_maximo': puntajeMaximo,
      'permite_entrega_tardia': permiteEntregaTardia,
      'penalizacion_por_dia': penalizacionPorDia,
      'dias_tolerancia': diasTolerancia,
      'tipo': tipo,
    };
  }

  bool get yaEntregue => miEntrega != null;
  bool get estaCalificada => miEntrega?.calificacion != null;
  bool get estaPendiente => yaEntregue && !estaCalificada;
  
  String get estadoTexto {
    if (!yaEntregue) {
      if (DateTime.now().isAfter(fechaLimite)) return 'Vencida';
      return 'Pendiente de entrega';
    }
    if (estaCalificada) return 'Calificada';
    return 'Pendiente de calificación';
  }

  Duration? get tiempoHastaVencimiento {
    if (DateTime.now().isAfter(fechaLimite)) return null;
    return fechaLimite.difference(DateTime.now());
  }

  String get tiempoHastaVencimientoTexto {
    final tiempo = tiempoHastaVencimiento;
    if (tiempo == null) return 'Vencida';
    
    if (tiempo.inDays > 0) return 'Quedan ${tiempo.inDays} días';
    if (tiempo.inHours > 0) return 'Quedan ${tiempo.inHours} horas';
    return 'Quedan ${tiempo.inMinutes} minutos';
  }
}