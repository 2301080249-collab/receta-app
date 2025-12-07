import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/tema.dart';
import '../../../data/repositories/tema_repository.dart';
import '../widgets/tema_card_estudiante.dart';

/// Widget del contenido del curso para estudiantes
/// Se usa dentro del CursoPersistentLayout
class CursoContenidoEstudiante extends StatefulWidget {
  final Curso curso;
  final List<Tema> temas;
  final VoidCallback? onTemasActualizados;
  
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
    _temas = widget.temas;
    
    for (int i = 1; i <= 16; i++) {
      _temasExpandidos[i] = false;
    }
  }

  @override
  void didUpdateWidget(CursoContenidoEstudiante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temas != widget.temas) {
      setState(() {
        _temas = widget.temas;
      });
    }
  }

  // ✅ FUNCIÓN CORREGIDA: Ya no usa caché, solo recarga
  Future<void> _cargarTemas() async {
    try {
      // Recargar temas desde el backend con las entregas actualizadas
      final temasActualizados = await _temaRepository.getTemasByCursoId(widget.curso.id);
      
      if (mounted) {
        setState(() {
          _temas = temasActualizados;
        });
        
        // Notificar al padre (CursoPersistentLayout) para que también actualice
        widget.onTemasActualizados?.call();
      }
    } catch (e) {
      print('Error recargando temas: $e');
      // Aún así notificar al padre por si tiene su propia lógica de recarga
      widget.onTemasActualizados?.call();
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return RefreshIndicator(
      onRefresh: _cargarTemas, // ✅ SIMPLIFICADO: Solo llama a _cargarTemas
      child: SingleChildScrollView(
        padding: EdgeInsets.all(kIsWeb ? 24 : (isMobile ? 12.w : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del curso
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 24 : (isMobile ? 16.w : 20),
                vertical: kIsWeb ? 28 : (isMobile ? 16.h : 20),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${widget.curso.nombre.toUpperCase()} ${widget.curso.nivelRomano}-${widget.curso.seccion ?? "A"} ${widget.curso.cicloNombre ?? "2023-I"}',
                style: TextStyle(
                  fontSize: kIsWeb ? 32 : (isMobile ? 18.sp : 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
              ),
            ),
            
            SizedBox(height: kIsWeb ? 32 : (isMobile ? 16.h : 24)),

            // Lista de temas
            ...temasCon16.map((tema) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: kIsWeb ? 0 : (isMobile ? 8.h : 12),
                ),
                child: TemaCardEstudiante(
                  key: ValueKey(tema.id),
                  tema: tema,
                  onMaterialVisto: _cargarTemas, // ✅ Recarga directamente
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}