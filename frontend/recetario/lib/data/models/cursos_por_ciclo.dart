class CursosPorCiclo {
  final int ciclo;
  final String cicloLabel;
  final int totalCursos;
  final int totalAlumnos;
  final List<CursoDetalle> cursos;

  CursosPorCiclo({
    required this.ciclo,
    required this.cicloLabel,
    required this.totalCursos,
    required this.totalAlumnos,
    required this.cursos,
  });

  factory CursosPorCiclo.fromJson(Map<String, dynamic> json) {
    return CursosPorCiclo(
      ciclo: json['ciclo'],
      cicloLabel: json['ciclo_label'],
      totalCursos: json['total_cursos'],
      totalAlumnos: json['total_alumnos'],
      cursos: (json['cursos'] as List?)
              ?.map((e) => CursoDetalle.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CursoDetalle {
  final String id;
  final String nombre;
  final int alumnos;
  final String? docenteNombre;
  final String? seccion;

  CursoDetalle({
    required this.id,
    required this.nombre,
    required this.alumnos,
    this.docenteNombre,
    this.seccion,
  });

  factory CursoDetalle.fromJson(Map<String, dynamic> json) {
    return CursoDetalle(
      id: json['id'],
      nombre: json['nombre'],
      alumnos: json['alumnos'],
      docenteNombre: json['docente_nombre'],
      seccion: json['seccion'],
    );
  }
}