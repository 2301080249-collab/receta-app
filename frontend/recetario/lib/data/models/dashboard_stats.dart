import 'package:recetario/data/models/cursos_por_ciclo.dart';

class DashboardStats {
  final int totalEstudiantes;
  final int totalDocentes;
  final int totalCursos;
  final int totalMatriculas;
  final int totalCiclos;
  final int cursosActivos;
  final int estudiantesNuevos;
  final int docentesActivos;
  final double matriculasOcupacion;
  final int matriculasPendientes;
  final CicloActual? cicloActual;
  final List<EstudiantesPorCiclo> estudiantesPorCiclo;
  final List<DocentesPorEspecialidad> docentesPorEspecialidad;
  final List<EstudiantesPorSeccion> estudiantesPorSeccion;
  final List<MatriculasPorCurso> matriculasPorCurso;
  final List<EvolucionMatriculas> evolucionMatriculas;
  final List<TimelineCiclo> timelineCiclos;
  final List<CursosPorCiclo> cursosPorCiclo;
  final List<DocenteCursos> docentesCursos; // ✅ NUEVO

  DashboardStats({
    required this.totalEstudiantes,
    required this.totalDocentes,
    required this.totalCursos,
    required this.totalMatriculas,
    required this.totalCiclos,
    required this.cursosActivos,
    required this.estudiantesNuevos,
    required this.docentesActivos,
    required this.matriculasOcupacion,
    required this.matriculasPendientes,
    this.cicloActual,
    this.estudiantesPorCiclo = const [],
    this.docentesPorEspecialidad = const [],
    this.estudiantesPorSeccion = const [],
    this.matriculasPorCurso = const [],
    this.evolucionMatriculas = const [],
    this.timelineCiclos = const [],
    this.cursosPorCiclo = const [],
    this.docentesCursos = const [], // ✅ NUEVO
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEstudiantes: json['total_estudiantes'] ?? 0,
      totalDocentes: json['total_docentes'] ?? 0,
      totalCursos: json['total_cursos'] ?? 0,
      totalMatriculas: json['total_matriculas'] ?? 0,
      totalCiclos: json['total_ciclos'] ?? 0,
      cursosActivos: json['cursos_activos'] ?? 0,
      estudiantesNuevos: json['estudiantes_nuevos'] ?? 0,
      docentesActivos: json['docentes_activos'] ?? 0,
      matriculasOcupacion: (json['matriculas_ocupacion'] ?? 0).toDouble(),
      matriculasPendientes: json['matriculas_pendientes'] ?? 0,
      cicloActual: json['ciclo_actual'] != null
          ? CicloActual.fromJson(json['ciclo_actual'])
          : null,
      estudiantesPorCiclo: (json['estudiantes_por_ciclo'] as List?)
              ?.map((e) => EstudiantesPorCiclo.fromJson(e))
              .toList() ??
          [],
      docentesPorEspecialidad: (json['docentes_por_especialidad'] as List?)
              ?.map((e) => DocentesPorEspecialidad.fromJson(e))
              .toList() ??
          [],
      estudiantesPorSeccion: (json['estudiantes_por_seccion'] as List?)
              ?.map((e) => EstudiantesPorSeccion.fromJson(e))
              .toList() ??
          [],
      matriculasPorCurso: (json['matriculas_por_curso'] as List?)
              ?.map((e) => MatriculasPorCurso.fromJson(e))
              .toList() ??
          [],
      evolucionMatriculas: (json['evolucion_matriculas'] as List?)
              ?.map((e) => EvolucionMatriculas.fromJson(e))
              .toList() ??
          [],
      timelineCiclos: (json['timeline_ciclos'] as List?)
              ?.map((e) => TimelineCiclo.fromJson(e))
              .toList() ??
          [],
      cursosPorCiclo: (json['cursos_por_ciclo'] as List?)
              ?.map((e) => CursosPorCiclo.fromJson(e))
              .toList() ??
          [],
      docentesCursos: (json['docentes_cursos'] as List?) // ✅ NUEVO
              ?.map((e) => DocenteCursos.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CicloActual {
  final String id;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;
  final int duracionSemanas;
  final int semanaActual;
  final int diasRestantes;
  final double porcentajeAvance;

  CicloActual({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.duracionSemanas,
    required this.semanaActual,
    required this.diasRestantes,
    required this.porcentajeAvance,
  });

  factory CicloActual.fromJson(Map<String, dynamic> json) {
    return CicloActual(
      id: json['id'],
      nombre: json['nombre'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      duracionSemanas: json['duracion_semanas'],
      semanaActual: json['semana_actual'],
      diasRestantes: json['dias_restantes'],
      porcentajeAvance: (json['porcentaje_avance'] ?? 0).toDouble(),
    );
  }
}

class EstudiantesPorCiclo {
  final int ciclo;
  final String cicloLabel;
  final int cantidad;
  final double porcentaje;

  EstudiantesPorCiclo({
    required this.ciclo,
    required this.cicloLabel,
    required this.cantidad,
    required this.porcentaje,
  });

  factory EstudiantesPorCiclo.fromJson(Map<String, dynamic> json) {
    return EstudiantesPorCiclo(
      ciclo: json['ciclo'],
      cicloLabel: json['ciclo_label'],
      cantidad: json['cantidad'],
      porcentaje: (json['porcentaje'] ?? 0).toDouble(),
    );
  }
}

class DocentesPorEspecialidad {
  final String especialidad;
  final int cantidad;

  DocentesPorEspecialidad({
    required this.especialidad,
    required this.cantidad,
  });

  factory DocentesPorEspecialidad.fromJson(Map<String, dynamic> json) {
    return DocentesPorEspecialidad(
      especialidad: json['especialidad'],
      cantidad: json['cantidad'],
    );
  }
}

class EstudiantesPorSeccion {
  final int ciclo;
  final String seccion;
  final int cantidad;

  EstudiantesPorSeccion({
    required this.ciclo,
    required this.seccion,
    required this.cantidad,
  });

  factory EstudiantesPorSeccion.fromJson(Map<String, dynamic> json) {
    return EstudiantesPorSeccion(
      ciclo: json['ciclo'],
      seccion: json['seccion'],
      cantidad: json['cantidad'],
    );
  }
}

class MatriculasPorCurso {
  final String cursoId;
  final String cursoNombre;
  final int matriculados;
  final int capacidad;
  final double porcentaje;
  final String docenteNombre;
  final String seccion;

  MatriculasPorCurso({
    required this.cursoId,
    required this.cursoNombre,
    required this.matriculados,
    required this.capacidad,
    required this.porcentaje,
    required this.docenteNombre,
    required this.seccion,
  });

  factory MatriculasPorCurso.fromJson(Map<String, dynamic> json) {
    return MatriculasPorCurso(
      cursoId: json['curso_id'],
      cursoNombre: json['curso_nombre'],
      matriculados: json['matriculados'],
      capacidad: json['capacidad'],
      porcentaje: (json['porcentaje'] ?? 0).toDouble(),
      docenteNombre: json['docente_nombre'],
      seccion: json['seccion'] ?? '',
    );
  }
}

class EvolucionMatriculas {
  final String cicloId;
  final String cicloNombre;
  final int cantidad;
  final String fecha;

  EvolucionMatriculas({
    required this.cicloId,
    required this.cicloNombre,
    required this.cantidad,
    required this.fecha,
  });

  factory EvolucionMatriculas.fromJson(Map<String, dynamic> json) {
    return EvolucionMatriculas(
      cicloId: json['ciclo_id'],
      cicloNombre: json['ciclo_nombre'],
      cantidad: json['cantidad'],
      fecha: json['fecha'],
    );
  }
}

class TimelineCiclo {
  final String id;
  final String nombre;
  final String fechaInicio;
  final String fechaFin;
  final bool activo;
  final double porcentajeAvance;
  final String estado;
  final int diasRestantes;

  TimelineCiclo({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
    required this.porcentajeAvance,
    required this.estado,
    required this.diasRestantes,
  });

  factory TimelineCiclo.fromJson(Map<String, dynamic> json) {
    return TimelineCiclo(
      id: json['id'],
      nombre: json['nombre'],
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      activo: json['activo'],
      porcentajeAvance: (json['porcentaje_avance'] ?? 0).toDouble(),
      estado: json['estado'],
      diasRestantes: json['dias_restantes'],
    );
  }
}

// ✅ NUEVO: Modelo para carga de trabajo de docentes
class DocenteCursos {
  final String docenteId;
  final String docenteNombre;
  final int totalCursos;
  final int totalEstudiantes;

  DocenteCursos({
    required this.docenteId,
    required this.docenteNombre,
    required this.totalCursos,
    required this.totalEstudiantes,
  });

  factory DocenteCursos.fromJson(Map<String, dynamic> json) {
    return DocenteCursos(
      docenteId: json['docente_id'] ?? '',
      docenteNombre: json['docente_nombre'] ?? 'Sin nombre',
      totalCursos: json['total_cursos'] ?? 0,
      totalEstudiantes: json['total_estudiantes'] ?? 0,
    );
  }
}