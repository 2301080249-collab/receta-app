import 'package:flutter/material.dart';

/// Clase para parsear horarios en formato texto
class HorarioParser {
  /// Mapeo de días de la semana (soporta diferentes formatos)
  static final Map<String, String> _diasNormalizados = {
    'lunes': 'Lunes',
    'lun': 'Lunes',
    'lu': 'Lunes',
    'martes': 'Martes',
    'mar': 'Martes',
    'ma': 'Martes',
    'miércoles': 'Miércoles',
    'miercoles': 'Miércoles', // ✅ SIN TILDE
    'mié': 'Miércoles',
    'mie': 'Miércoles',
    'mi': 'Miércoles',
    'jueves': 'Jueves',
    'jue': 'Jueves',
    'ju': 'Jueves',
    'viernes': 'Viernes',
    'vie': 'Viernes',
    'vi': 'Viernes',
    'sábado': 'Sábado',
    'sabado': 'Sábado',
    'sáb': 'Sábado',
    'sab': 'Sábado',
    'sa': 'Sábado',
    'domingo': 'Domingo',
    'dom': 'Domingo',
    'do': 'Domingo',
  };

  /// Parsear horario en formato texto
  /// Ejemplos:
  /// - "Lunes-Miércoles 8am-12am"
  /// - "Lun - Miércoles - Viernes : 8:00 pm a 10:00 pm"
  /// - "Martes 14:00-16:00"
  static List<BloqueCurso> parsear(String horarioTexto) {
    List<BloqueCurso> bloques = [];
    
    if (horarioTexto.isEmpty) return bloques;

    try {
      // Limpiar el texto
      String texto = horarioTexto.toLowerCase().trim();
      
      // Separar por días y horas
      List<String> dias = [];
      String? horaInicio;
      String? horaFin;

      // Intentar diferentes patrones
      
      // Patrón 1: "Lunes-Miércoles 8am-12am"
      if (texto.contains('-') && (texto.contains('am') || texto.contains('pm') || texto.contains(':'))) {
        final partes = texto.split(RegExp(r'\s+'));
        
        // Extraer días (primera parte)
        if (partes.isNotEmpty) {
          final diasTexto = partes[0];
          dias = diasTexto.split('-').map((d) => d.trim()).toList();
        }

        // Extraer horas
        final horasMatch = RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm)?\s*[-a]\s*(\d{1,2}):?(\d{2})?\s*(am|pm)?')
            .firstMatch(texto);
        
        if (horasMatch != null) {
          horaInicio = _normalizarHora(
            horasMatch.group(1)!,
            horasMatch.group(2),
            horasMatch.group(3),
          );
          horaFin = _normalizarHora(
            horasMatch.group(4)!,
            horasMatch.group(5),
            horasMatch.group(6),
          );
        }
      }
      
      // Patrón 2: "Lun - Miércoles - Viernes : 8:00 pm a 10:00 pm"
      else if (texto.contains(':')) {
        // Separar por ':'
        final partesDivididas = texto.split(':');
        
        if (partesDivididas.length >= 2) {
          // Días antes de ':'
          final diasTexto = partesDivididas[0];
          dias = diasTexto.split(RegExp(r'[-,]')).map((d) => d.trim()).toList();
          
          // Horas después de ':'
          final horasTexto = partesDivididas.sublist(1).join(':');
          final horasMatch = RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm)?\s*[a-]\s*(\d{1,2}):?(\d{2})?\s*(am|pm)?')
              .firstMatch(horasTexto);
          
          if (horasMatch != null) {
            horaInicio = _normalizarHora(
              horasMatch.group(1)!,
              horasMatch.group(2),
              horasMatch.group(3),
            );
            horaFin = _normalizarHora(
              horasMatch.group(4)!,
              horasMatch.group(5),
              horasMatch.group(6),
            );
          }
        }
      }

      // Normalizar días
      List<String> diasNormalizados = [];
      for (var dia in dias) {
        final diaNormalizado = _normalizarDia(dia.trim());
        if (diaNormalizado != null) {
          diasNormalizados.add(diaNormalizado);
        }
      }

      // Crear bloques para cada día
      if (horaInicio != null && horaFin != null) {
        for (var dia in diasNormalizados) {
          bloques.add(BloqueCurso(
            dia: dia,
            horaInicio: horaInicio,
            horaFin: horaFin,
          ));
        }
      }

    } catch (e) {
      debugPrint('❌ Error parseando horario "$horarioTexto": $e');
    }

    return bloques;
  }

  /// Normalizar nombre del día
  static String? _normalizarDia(String dia) {
    final diaLimpio = dia.toLowerCase().trim();
    return _diasNormalizados[diaLimpio];
  }

  /// Normalizar hora a formato 24h (HH:mm)
  static String _normalizarHora(String hora, String? minutos, String? periodo) {
    int h = int.parse(hora);
    int m = minutos != null ? int.parse(minutos) : 0;

    // Convertir a formato 24h si hay am/pm
    if (periodo != null) {
      final periodoLower = periodo.toLowerCase();
      
      // ✅ CORRECCIÓN: 12am = mediodía (12:00), no medianoche
      if (periodoLower == 'am') {
        // 12am en formato común significa mediodía (aunque técnicamente incorrecto)
        // Lo dejamos como está: 12am = 12:00
        if (h == 12) {
          // No cambiamos nada, 12am = 12:00
        }
      } else if (periodoLower == 'pm') {
        if (h < 12) {
          h += 12;
        }
        // 12pm = 12:00 (mediodía)
      }
    }

    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Verificar si una hora está dentro de un rango
  static bool estaEnRango(String hora, String horaInicio, String horaFin) {
    try {
      final horaParts = hora.split(':');
      final inicioParts = horaInicio.split(':');
      final finParts = horaFin.split(':');

      final horaMinutos = int.parse(horaParts[0]) * 60 + int.parse(horaParts[1]);
      final inicioMinutos = int.parse(inicioParts[0]) * 60 + int.parse(inicioParts[1]);
      final finMinutos = int.parse(finParts[0]) * 60 + int.parse(finParts[1]);

      return horaMinutos >= inicioMinutos && horaMinutos < finMinutos;
    } catch (e) {
      return false;
    }
  }
}

/// Representa un bloque de curso en el calendario
class BloqueCurso {
  final String dia;
  final String horaInicio;
  final String horaFin;

  BloqueCurso({
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
  });

  @override
  String toString() => '$dia $horaInicio-$horaFin';
}