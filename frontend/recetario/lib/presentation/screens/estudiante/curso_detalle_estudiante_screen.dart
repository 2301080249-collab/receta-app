import 'package:flutter/material.dart';
import '../../../data/models/curso.dart';
import '../../layouts/curso_persistent_layout.dart';
import '../../widgets/curso_contenido_estudiante.dart';
import 'participantes_estudiante_tab.dart';

/// Pantalla de detalle del curso para estudiantes
/// Usa el CursoPersistentLayout para mantener fijos header, pestañas y sidebar
class CursoDetalleEstudianteScreen extends StatelessWidget {
  final Curso curso;

  const CursoDetalleEstudianteScreen({
    Key? key,
    required this.curso,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CursoPersistentLayout(
      curso: curso,
      userRole: 'estudiante',
      // Contenido de la pestaña "Curso"
      contenidoCursoBuilder: (context, curso, temas, onRecargarTemas) {
        return CursoContenidoEstudiante(
          curso: curso,
          temas: temas,
          onTemasActualizados: onRecargarTemas, // ✅ Pasar callback
        );
      },
      // Contenido de la pestaña "Participantes"
      contenidoParticipantesBuilder: (context, curso) {
        return ParticipantesEstudianteTab(curso: curso);
      },
    );
  }
}