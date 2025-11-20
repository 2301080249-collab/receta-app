import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/tema.dart';
import '../../../data/repositories/tema_repository.dart';
import '../widgets/tema_card_docente.dart';

/// Widget del contenido del curso para docentes
/// ✅ OPTIMIZADO: Renderizado progresivo de temas
class CursoContenidoDocente extends StatefulWidget {
  final Curso curso;
  final List<Tema> temas;
  final VoidCallback? onTemasActualizados;
  
  const CursoContenidoDocente({
    Key? key,
    required this.curso,
    required this.temas,
    this.onTemasActualizados,
  }) : super(key: key);

  @override
  State<CursoContenidoDocente> createState() => _CursoContenidoDocenteState();
}

class _CursoContenidoDocenteState extends State<CursoContenidoDocente> {
  late TemaRepository _temaRepository;
  late List<Tema> _temas;
  int _temasVisibles = 5; // ✅ NUEVO: Mostrar primero 5 temas

  @override
  void initState() {
    super.initState();
    _temaRepository = TemaRepository();
    _temas = widget.temas;
    
    // ✅ OPTIMIZACIÓN: Cargar el resto de temas progresivamente
    _cargarTemasProgresivamente();
  }

  @override
  void didUpdateWidget(CursoContenidoDocente oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temas != widget.temas) {
      setState(() {
        _temas = widget.temas;
        _temasVisibles = 5; // Resetear
      });
      _cargarTemasProgresivamente();
    }
  }

  // ✅ NUEVO: Cargar temas de forma progresiva
  void _cargarTemasProgresivamente() {
    if (_temasVisibles >= 16) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _temasVisibles < 16) {
        setState(() {
          _temasVisibles = 16; // Mostrar todos
        });
      }
    });
  }

  Future<void> _cargarTemas() async {
    widget.onTemasActualizados?.call();
  }

  List<Tema> _obtenerTemasCon16() {
    List<Tema> temasCompletos = [];
    
    // ✅ Solo generar hasta _temasVisibles
    for (int i = 1; i <= _temasVisibles; i++) {
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

    return SingleChildScrollView(
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

          // ✅ Lista de temas (renderizado progresivo)
          ...temasCon16.map((tema) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: kIsWeb ? 0 : (isMobile ? 8.h : 12),
              ),
              child: TemaCardDocente(
                key: ValueKey(tema.id),
                tema: tema,
                cursoId: widget.curso.id,
                curso: widget.curso,
                onTemaActualizado: _cargarTemas,
              ),
            );
          }).toList(),

          // ✅ Indicador de carga si hay más temas
          if (_temasVisibles < 16)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}