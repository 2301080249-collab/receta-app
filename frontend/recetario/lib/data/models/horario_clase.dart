// lib/data/models/horario_clase.dart

class HorarioClase {
  final String dia;
  final String horaInicio;
  final String horaFin;
  final String nombreCurso;
  final String? seccion;
  final int? nivel;
  final String cursoId;

  HorarioClase({
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.nombreCurso,
    this.seccion,
    this.nivel,
    required this.cursoId,
  });

  int get diaNumero {
    const dias = {
      'lunes': 1,
      'martes': 2,
      'miércoles': 3,
      'miercoles': 3,
      'jueves': 4,
      'viernes': 5,
      'sábado': 6,
      'sabado': 6,
      'domingo': 7,
    };
    return dias[dia.toLowerCase()] ?? 0;
  }

  bool get esHoy {
    final hoy = DateTime.now().weekday;
    return diaNumero == hoy;
  }

  int _horaAMinutos(String hora) {
    try {
      final parts = hora.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  bool get yaPaso {
    if (!esHoy) return false;
    
    final ahora = DateTime.now();
    final minutosActuales = ahora.hour * 60 + ahora.minute;
    final minutosFin = _horaAMinutos(horaFin);
    
    return minutosActuales > minutosFin;
  }

  bool get enCurso {
    if (!esHoy) return false;
    
    final ahora = DateTime.now();
    final minutosActuales = ahora.hour * 60 + ahora.minute;
    final minutosInicio = _horaAMinutos(horaInicio);
    final minutosFin = _horaAMinutos(horaFin);
    
    return minutosActuales >= minutosInicio && minutosActuales <= minutosFin;
  }

  String get cursoCompleto {
    final parts = <String>[nombreCurso];
    if (nivel != null) {
      const mapa = {
        1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
        6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X',
      };
      parts.add(mapa[nivel] ?? '');
    }
    if (seccion != null && seccion!.isNotEmpty) {
      parts.add(seccion!);
    }
    return parts.join('-');
  }

  String get horarioFormateado {
    return '$horaInicio - $horaFin';
  }
}

class HorarioParser {
  static List<HorarioClase> parse(String? horarioStr, String nombreCurso, String cursoId, int? nivel, String? seccion) {
    if (horarioStr == null || horarioStr.trim().isEmpty) {
      return [];
    }

    final horarios = <HorarioClase>[];
    final bloques = horarioStr.split(',');
    
    for (final bloque in bloques) {
      final trimmed = bloque.trim();
      if (trimmed.isEmpty) continue;

      try {
        final regex = RegExp(r'(\w+)\s+(\d{1,2}:\d{2})-(\d{1,2}:\d{2})');
        final match = regex.firstMatch(trimmed);

        if (match != null) {
          final dia = match.group(1)!;
          final horaInicio = match.group(2)!;
          final horaFin = match.group(3)!;

          horarios.add(HorarioClase(
            dia: dia,
            horaInicio: horaInicio,
            horaFin: horaFin,
            nombreCurso: nombreCurso,
            seccion: seccion,
            nivel: nivel,
            cursoId: cursoId,
          ));
        }
      } catch (e) {
        print('Error parseando horario: $trimmed - $e');
      }
    }

    horarios.sort((a, b) => a.diaNumero.compareTo(b.diaNumero));
    return horarios;
  }

  static List<HorarioClase> parseCursos(List<dynamic> cursos) {
    final todosHorarios = <HorarioClase>[];

    for (final curso in cursos) {
      final horarios = parse(
        curso.horario,
        curso.nombre,
        curso.id,
        curso.nivel,
        curso.seccion,
      );
      todosHorarios.addAll(horarios);
    }

    todosHorarios.sort((a, b) {
      final compareDia = a.diaNumero.compareTo(b.diaNumero);
      if (compareDia != 0) return compareDia;
      return a.horaInicio.compareTo(b.horaInicio);
    });

    return todosHorarios;
  }

  static List<HorarioClase> filtrarHoy(List<HorarioClase> horarios) {
    return horarios.where((h) => h.esHoy).toList();
  }

  static Map<String, List<HorarioClase>> agruparPorDia(List<HorarioClase> horarios) {
    final agrupados = <String, List<HorarioClase>>{};
    
    for (final horario in horarios) {
      if (!agrupados.containsKey(horario.dia)) {
        agrupados[horario.dia] = [];
      }
      agrupados[horario.dia]!.add(horario);
    }

    return agrupados;
  }
}