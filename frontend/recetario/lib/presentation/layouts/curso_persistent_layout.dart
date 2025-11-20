import 'package:flutter/material.dart';
import '../../data/models/curso.dart';
import '../../data/models/tema.dart';
import '../../data/repositories/tema_repository.dart';
import '../widgets/CursoSidebarWidget.dart';
import '../widgets/custom_app_header.dart';

/// Layout persistente para mantener fijos el header, pestañas y sidebar
/// ✅ OPTIMIZADO: Evita llamadas API duplicadas
class CursoPersistentLayout extends StatefulWidget {
  final Curso curso;
  final String userRole;
  final Widget Function(BuildContext context, Curso curso, List<Tema> temas,
      VoidCallback onRecargarTemas) contenidoCursoBuilder;
  final Widget Function(BuildContext context, Curso curso)
      contenidoParticipantesBuilder;

  const CursoPersistentLayout({
    Key? key,
    required this.curso,
    required this.userRole,
    required this.contenidoCursoBuilder,
    required this.contenidoParticipantesBuilder,
  }) : super(key: key);

  @override
  State<CursoPersistentLayout> createState() => _CursoPersistentLayoutState();
}

class _CursoPersistentLayoutState extends State<CursoPersistentLayout>
    with SingleTickerProviderStateMixin {
  late TemaRepository _temaRepository;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  List<Tema> _temas = [];
  bool _isLoadingTemas = false; // ✅ Cambio: false por defecto
  bool _temasYaCargados = false; // ✅ NUEVO: Flag para evitar recargas
  String _tabSeleccionada = 'curso';
  Map<int, bool> _temasExpandidos = {};
  bool _sidebarVisible = true;
  int? _temaSeleccionado;

  @override
  void initState() {
    super.initState();
    _temaRepository = TemaRepository();

    // ✅ Animación suave para el sidebar
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Inicializar el mapa de temas expandidos
    for (int i = 1; i <= 16; i++) {
      _temasExpandidos[i] = false;
    }

    // ✅ Iniciar con sidebar visible
    _animationController.value = 1.0;

    // ✅ OPTIMIZACIÓN: Cargar UNA SOLA VEZ después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_temasYaCargados) {
        _cargarTemasOptimizado();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ En móvil, iniciar con sidebar oculto
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 768 && _sidebarVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _sidebarVisible = false;
            _animationController.value = 0.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ OPTIMIZADO: Carga UNA SOLA VEZ con protección
  Future<void> _cargarTemasOptimizado() async {
    // ✅ Protección: Si ya está cargando o ya cargó, no hace nada
    if (_isLoadingTemas || _temasYaCargados) {
      print('⏭️ Ya está cargando o ya cargó temas, saltando...');
      return;
    }
    
    if (!mounted) return;
    
    print('🚀 Iniciando carga de temas...');
    setState(() => _isLoadingTemas = true);
    
    try {
      final temas = await _temaRepository.getTemasByCursoId(widget.curso.id);
      
      if (mounted) {
        setState(() {
          _temas = temas;
          _isLoadingTemas = false;
          _temasYaCargados = true; // ✅ MARCAR COMO CARGADO
        });
        print('✅ Temas cargados exitosamente: ${temas.length} temas');
      }
    } catch (e) {
      print('❌ Error al cargar temas: $e');
      if (mounted) {
        setState(() {
          _isLoadingTemas = false;
          _temasYaCargados = true; // ✅ Marcar como intentado
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar temas: $e')),
        );
      }
    }
  }

  // ✅ Función para recargar manualmente (cuando se crea/edita un tema)
  Future<void> _cargarTemas() async {
    print('🔄 Recarga manual solicitada...');
    setState(() {
      _temasYaCargados = false; // Permitir recarga
      _isLoadingTemas = false;
    });
    await _cargarTemasOptimizado();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarVisible = !_sidebarVisible;
      if (_sidebarVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleTema(int orden) {
    setState(() {
      _temasExpandidos[orden] = !(_temasExpandidos[orden] ?? false);
    });
  }

  void _seleccionarTema(int orden) {
    setState(() {
      _temaSeleccionado = orden;
    });
  }

  void _cambiarTab(String tab) {
    setState(() {
      _tabSeleccionada = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ✅ Header fijo (NUNCA SE MUEVE)
          const CustomAppHeader(selectedMenu: 'cursos'),

          // ✅ Pestañas fijas (NUNCA SE MUEVEN)
          _buildTabs(isMobile),

          // ✅ Contenido con sidebar
          Expanded(
            child: Row(
              children: [
                // ✅ SIDEBAR - Con animación suave
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 280 * _animation.value,
                      child: _animation.value > 0
                          ? CursoSidebarWidget(
                              curso: widget.curso,
                              temas: _temas,
                              isLoading: _isLoadingTemas,
                              isVisible: _sidebarVisible,
                              temasExpandidos: _temasExpandidos,
                              temaSeleccionado: _temaSeleccionado,
                              onClose: _toggleSidebar,
                              onTemaToggle: _toggleTema,
                              onTemaSeleccionado: _seleccionarTema,
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),

                // ✅ CONTENIDO - Se adapta al espacio disponible
                Expanded(
                  child: Stack(
                    children: [
                      // Contenido principal
                      _buildContenidoSegunTab(),

                      // ✅ Botón flotante cuando sidebar está oculto
                      if (!_sidebarVisible)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF455A64),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: _toggleSidebar,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF37474F),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12 : 120,
          4,
          isMobile ? 12 : 16,
          4,
        ),
        child: Row(
          children: [
            _buildTab('Curso', 'curso', isMobile),
            SizedBox(width: isMobile ? 4 : 8),
            _buildTab('Participantes', 'participantes', isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String titulo, String valor, bool isMobile) {
    final isSelected = _tabSeleccionada == valor;

    return InkWell(
      onTap: () => _cambiarTab(valor),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF455A64) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        child: Text(
          titulo,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoSegunTab() {
    switch (_tabSeleccionada) {
      case 'curso':
        return widget.contenidoCursoBuilder(
            context, widget.curso, _temas, _cargarTemas);
      case 'participantes':
        return widget.contenidoParticipantesBuilder(context, widget.curso);
      default:
        return widget.contenidoCursoBuilder(
            context, widget.curso, _temas, _cargarTemas);
    }
  }
}