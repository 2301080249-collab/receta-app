import 'package:flutter/material.dart';
import '../../../data/models/curso.dart';
import '../../layouts/curso_persistent_layout.dart';
import '../../widgets/curso_contenido_docente.dart';
import 'participantes_tab.dart';

/// Pantalla de detalle del curso para docentes
/// Usa el CursoPersistentLayout para mantener fijos header, pestañas y sidebar
class CursoDetalleDocenteScreen extends StatelessWidget {
  final Curso curso;

  const CursoDetalleDocenteScreen({
    Key? key,
    required this.curso,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CursoPersistentLayout(
      curso: curso,
      userRole: 'docente',
      // Contenido de la pestaña "Curso"
      contenidoCursoBuilder: (context, curso, temas, onRecargarTemas) {
        return CursoContenidoDocente(
          curso: curso,
          temas: temas,
          onTemasActualizados: onRecargarTemas, // ✅ Pasar callback
        );
      },
      // Contenido de la pestaña "Participantes"
      contenidoParticipantesBuilder: (context, curso) {
        return ParticipantesTab(curso: curso);
      },
    );
  }
}