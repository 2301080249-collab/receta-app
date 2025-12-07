/// Modelo para representar un bloque de horario de un curso
class HorarioItem {
  final String cursoId;
  final String nombreCurso;
  final String cicloNombre;
  final int? nivel;
  final String? seccion;
  final String? horario;
  final String? docenteNombre;

  HorarioItem({
    required this.cursoId,
    required this.nombreCurso,
    required this.cicloNombre,
    this.nivel,
    this.seccion,
    this.horario,
    this.docenteNombre,
  });

  factory HorarioItem.fromJson(Map<String, dynamic> json) {
    // ✅ DEBUG: Ver JSON completo
    print('🔍 [HorarioItem] JSON RECIBIDO: $json');
    
    String? docenteNombre;
    
    // ✅ PRIMERO: Intentar obtener desde 'docente_nombre' (directo del backend)
    if (json['docente_nombre'] != null) {
      print('✅ [HorarioItem] Encontrado docente_nombre: ${json['docente_nombre']}');
      if (json['docente_nombre'] is String) {
        docenteNombre = json['docente_nombre'];
        print('✅ [HorarioItem] Asignado docenteNombre desde campo directo: $docenteNombre');
      }
    }
    // ✅ SEGUNDO: Si no existe, intentar desde la estructura anidada
    else if (json['docentes'] != null && json['docentes'] is Map) {
      print('✅ [HorarioItem] Intentando extraer desde docentes anidado');
      final docentes = json['docentes'] as Map<String, dynamic>;
      if (docentes['usuarios'] != null && docentes['usuarios'] is Map) {
        final usuarios = docentes['usuarios'] as Map<String, dynamic>;
        docenteNombre = usuarios['nombre_completo'];
        print('✅ [HorarioItem] Asignado docenteNombre desde estructura anidada: $docenteNombre');
      }
    } else {
      print('❌ [HorarioItem] NO se encontró docente_nombre en ningún formato');
    }

    final item = HorarioItem(
      cursoId: json['curso_id'] ?? json['id'],
      nombreCurso: json['nombre'] ?? '',
      cicloNombre: json['ciclo_nombre'] ?? json['ciclos']?['nombre'] ?? '',
      nivel: json['nivel'],
      seccion: json['seccion'],
      horario: json['horario'],
      docenteNombre: docenteNombre,
    );
    
    // ✅ DEBUG: Ver el objeto creado
    print('📦 [HorarioItem] OBJETO CREADO:');
    print('   - Curso: ${item.nombreCurso}');
    print('   - Docente: ${item.docenteNombre}');
    print('   - Sección: ${item.seccion}');
    
    return item;
  }

  // Helper para mostrar información del curso
  String get infoCompleta {
    final parts = <String>[];
    if (nivel != null) {
      const mapa = {
        1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
        6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X',
      };
      parts.add(mapa[nivel] ?? 'Ciclo $nivel');
    }
    if (seccion != null && seccion!.isNotEmpty) {
      parts.add('Sección $seccion');
    }
    return parts.join('-');
  }
}