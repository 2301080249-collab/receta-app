import 'package:flutter/material.dart';
import '../../../data/models/curso.dart';
import '../../../data/repositories/curso_repository.dart';
import '../../widgets/curso_card.dart';
import '../../widgets/custom_app_header.dart';
import 'curso_detalle_docente_screen.dart';

class HomeDocenteScreen extends StatefulWidget {
  final bool showHeader;
  
  const HomeDocenteScreen({
    Key? key,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<HomeDocenteScreen> createState() => _HomeDocenteScreenState();
}

class _HomeDocenteScreenState extends State<HomeDocenteScreen> {
  final CursoRepository _cursoRepository = CursoRepository();
  List<Curso> _cursos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('🟢 DOCENTE: initState() ejecutado');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🟢 DOCENTE: PostFrameCallback - cargando cursos');
      if (mounted) {
        _cargarCursos();
      }
    });
  }

  Future<void> _cargarCursos() async {
    print('🔄 DOCENTE: Iniciando carga de cursos...');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 DOCENTE: Llamando a getCursosByDocente()...');
      final cursos = await _cursoRepository.getCursosByDocente();
      
      print('✅ DOCENTE: Cursos obtenidos: ${cursos.length}');
      
      if (mounted) {
        setState(() {
          _cursos = cursos;
          _isLoading = false;
        });
        print('✅ DOCENTE: Estado actualizado con ${_cursos.length} cursos');
      }
    } catch (e) {
      print('❌ DOCENTE: Error al cargar cursos: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          if (widget.showHeader)
            const CustomAppHeader(selectedMenu: 'cursos'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar cursos',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarCursos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_cursos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes cursos asignados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Contacta al administrador para que te asigne cursos',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // ✅ RESPONSIVE: Detectar tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    // ✅ RESPONSIVE: Columnas según el tamaño
    int crossAxisCount = 3; // Desktop por defecto
    if (isMobile) {
      crossAxisCount = 1; // 1 columna en móvil
    } else if (isTablet) {
      crossAxisCount = 2; // 2 columnas en tablet
    }

    // ✅ RESPONSIVE: Aspect ratio según el tamaño
    double childAspectRatio = 1.4; // Desktop
    if (isMobile) {
      childAspectRatio = 2.0; // Más ancho que alto en móvil
    } else if (isTablet) {
      childAspectRatio = 1.6;
    }

    // ✅ RESPONSIVE: Padding según el tamaño
    final containerPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final outerPadding = isMobile ? 16.0 : 24.0;

    // ✅ RESPONSIVE: Spacing según el tamaño
    final spacing = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);

    return RefreshIndicator(
      onRefresh: _cargarCursos,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎯 TÍTULO ALINEADO CON EL CONTAINER
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1100 : double.infinity,
                  ),
                  width: double.infinity,
                  child: Text(
                    'Mis cursos asignados',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isMobile ? 16 : 24),
              
              // CONTAINER DE CURSOS
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1100 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(containerPadding),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: isDesktop 
                        ? (_cursos.length > 9 ? 9 : _cursos.length)
                        : _cursos.length,
                    itemBuilder: (context, index) {
                      final curso = _cursos[index];
                      return CursoCard(
                        curso: curso,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CursoDetalleDocenteScreen(
                                curso: curso,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              
              if (isDesktop && _cursos.length > 9) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Mostrando 9 de ${_cursos.length} cursos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}