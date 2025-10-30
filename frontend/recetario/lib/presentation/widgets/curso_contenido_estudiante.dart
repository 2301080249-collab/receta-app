import 'package:flutter/material.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/tema.dart';
import '../../../data/repositories/tema_repository.dart';
import '../widgets/tema_card_estudiante.dart';

/// Widget del contenido del curso para estudiantes
/// Se usa dentro del CursoPersistentLayout
class CursoContenidoEstudiante extends StatefulWidget {
  final Curso curso;
  final List<Tema> temas; // ✅ Recibe los temas ya cargados
  final VoidCallback? onTemasActualizados; // ✅ Callback para notificar cambios
  
  const CursoContenidoEstudiante({
    Key? key,
    required this.curso,
    required this.temas,
    this.onTemasActualizados,
  }) : super(key: key);

  @override
  State<CursoContenidoEstudiante> createState() => _CursoContenidoEstudianteState();
}

class _CursoContenidoEstudianteState extends State<CursoContenidoEstudiante> {
  late TemaRepository _temaRepository;
  late List<Tema> _temas;
  Map<int, bool> _temasExpandidos = {};

  @override
  void initState() {
    super.initState();
    _temaRepository = TemaRepository();
    _temas = widget.temas; // ✅ Usar los temas recibidos
    
    // Inicializar todos los temas como colapsados
    for (int i = 1; i <= 16; i++) {
      _temasExpandidos[i] = false;
    }
  }

  @override
  void didUpdateWidget(CursoContenidoEstudiante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temas != widget.temas) {
      setState(() {
        _temas = widget.temas; // ✅ Actualizar si cambian
      });
    }
  }

  Future<void> _cargarTemas() async {
    // ✅ Notificar al layout persistente para que recargue los temas
    widget.onTemasActualizados?.call();
  }

  List<Tema> _obtenerTemasCon16() {
    List<Tema> temasCompletos = [];
    
    for (int i = 1; i <= 16; i++) {
      final temaExistente = _temas.firstWhere(
        (t) => t.orden == i,
        orElse: () => Tema(
          id: 'placeholder-$i',
          cursoId: widget.curso.id,
          titulo: 'Tema $i',
          descripcion: null,
          orden: i,
          activo: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          materiales: [],
          tareas: [],
        ),
      );
      temasCompletos.add(temaExistente);
    }
    
    return temasCompletos;
  }

  @override
  Widget build(BuildContext context) {
    final temasCon16 = _obtenerTemasCon16();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del curso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${widget.curso.nombre.toUpperCase()}-${widget.curso.nivelRomano}-${widget.curso.seccion ?? "A"}${widget.curso.nivel ?? ""}-${widget.curso.cicloNombre ?? "2023-I"}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.3,
                height: 1.2,
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          // Lista de temas (mismo diseño que docente)
          ...temasCon16.map((tema) {
            return TemaCardEstudiante(
              key: ValueKey(tema.id),
              tema: tema,
              onMaterialVisto: _cargarTemas,
            );
          }).toList(),
        ],
      ),
    );
  }
}