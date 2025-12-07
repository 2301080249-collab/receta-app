import 'package:flutter/material.dart';
import 'package:recetario/data/models/dashboard_stats.dart';
import 'package:recetario/data/models/ciclo.dart';
import 'package:recetario/data/services/dashboard_service.dart';
import 'package:recetario/data/services/dashboard_pdf_service.dart';
import 'package:recetario/core/mixins/auth_token_mixin.dart';
import 'package:recetario/presentation/widgets/dashboard/kpi_card_animated.dart';
import 'package:recetario/presentation/widgets/dashboard/ciclo_selector_card.dart';
import 'package:recetario/presentation/widgets/dashboard/donut_chart_ciclos.dart';
import 'package:recetario/presentation/widgets/dashboard/bar_chart_secciones.dart';
import 'package:recetario/presentation/widgets/dashboard/cursos_por_ciclo_accordion.dart';
import 'package:recetario/presentation/widgets/dashboard/line_chart_evolucion.dart';
import 'package:recetario/presentation/widgets/dashboard/bar_chart_docentes.dart';

class DashboardAnalyticsScreen extends StatefulWidget {
  const DashboardAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<DashboardAnalyticsScreen> createState() =>
      _DashboardAnalyticsScreenState();
}

class _DashboardAnalyticsScreenState extends State<DashboardAnalyticsScreen>
    with AuthTokenMixin {
  final DashboardService _service = DashboardService();

  DashboardStats? _stats;
  List<Ciclo> _ciclos = [];
  bool _isLoadingCiclos = true;
  bool _isLoadingStats = false;
  String? _error;

  String? _cicloIdSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCiclos();
  }

  Future<void> _cargarCiclos() async {
    setState(() {
      _isLoadingCiclos = true;
      _error = null;
    });

    try {
      final token = getTokenSafe();
      if (token == null) throw Exception('No hay token');

      final ciclos = await _service.obtenerTodosCiclos(token: token);

      if (mounted) {
        setState(() {
          _ciclos = ciclos;
          _isLoadingCiclos = false;
          _cicloIdSeleccionado = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando ciclos: $e';
          _isLoadingCiclos = false;
        });
      }
    }
  }

  Future<void> _cargarDatos() async {
    if (_cicloIdSeleccionado == null) return;

    setState(() {
      _isLoadingStats = true;
      _error = null;
    });

    try {
      final token = getTokenSafe();
      if (token == null) throw Exception('No hay token');

      final stats = await _service.obtenerEstadisticas(
        token: token,
        cicloId: _cicloIdSeleccionado,
        estado: 'todos',
      );

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _exportarPDF() async {
    try {
      print('=== DEBUG EXPORTAR PDF ===');
      print('📊 Total cursosPorCiclo: ${_stats!.cursosPorCiclo.length}');
      
      for (var ciclo in _stats!.cursosPorCiclo) {
        print('  ${ciclo.cicloLabel}:');
        print('    - Total cursos: ${ciclo.totalCursos}');
        print('    - Total alumnos: ${ciclo.totalAlumnos}');
        for (var curso in ciclo.cursos) {
          print('      • ${curso.nombre} (${curso.alumnos} alumnos) - ${curso.docenteNombre}');
        }
      }
      print('========================');

      final cicloNombre = _ciclos
          .firstWhere((c) => c.id == _cicloIdSeleccionado)
          .nombre;

      await DashboardPdfService.exportarDashboard(
        stats: _stats!,
        cicloNombre: cicloNombre,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF generado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    if (_isLoadingCiclos) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando ciclos académicos...'),
            ],
          ),
        ),
      );
    }

    if (_error != null && _ciclos.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: $_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargarCiclos,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 24),
            CicloSelectorCard(
              ciclos: _ciclos,
              cicloIdSeleccionado: _cicloIdSeleccionado,
              onCicloChanged: (nuevoId) {
                setState(() => _cicloIdSeleccionado = nuevoId);
                _cargarDatos();
              },
            ),
            SizedBox(height: isMobile ? 16 : 24),
            if (_cicloIdSeleccionado == null)
              _buildEstadoVacio(isMobile)
            else if (_isLoadingStats)
              _buildLoadingStats(isMobile)
            else if (_stats != null) ...[
              _buildKPICards(isMobile, isTablet, isDesktop),
              SizedBox(height: isMobile ? 20 : 32),
              _buildGraficos(isMobile, isTablet, isDesktop),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Dashboard Analytics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Análisis completo del sistema académico',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (_stats != null && _cicloIdSeleccionado != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportarPDF,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Exportar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Dashboard Analytics',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Análisis completo del sistema académico',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_stats != null && _cicloIdSeleccionado != null)
            ElevatedButton.icon(
              onPressed: _exportarPDF,
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              label: const Text('Exportar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildEstadoVacio(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 32 : 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: isMobile ? 60 : 80,
                color: Colors.grey[300],
              ),
              SizedBox(height: isMobile ? 16 : 24),
              Text(
                'Seleccione un ciclo académico',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                'Los gráficos y estadísticas se cargarán automáticamente',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStats(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 40 : 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: isMobile ? 16 : 24),
              Text(
                'Cargando estadísticas...',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards(bool isMobile, bool isTablet, bool isDesktop) {
    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (isMobile) {
      crossAxisCount = 5;
      childAspectRatio = 0.75; // ✅ CAMBIADO de 0.75 a 1.0 (más altura)
      spacing = 6;
    } else if (isTablet) {
      crossAxisCount = 3;
      childAspectRatio = 1.3;
      spacing = 14;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 1.4;
      spacing = 16;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: [
        KpiCardAnimated(
          title: 'Estudiantes',
          value: _stats!.totalEstudiantes,
          icon: Icons.school,
          color: Colors.blue,
        ),
        KpiCardAnimated(
          title: 'Docentes',
          value: _stats!.totalDocentes,
          icon: Icons.person,
          color: Colors.green,
        ),
        KpiCardAnimated(
          title: 'Cursos',
          value: _stats!.totalCursos,
          icon: Icons.book,
          color: Colors.orange,
        ),
        KpiCardAnimated(
          title: 'Matrículas',
          value: _stats!.totalMatriculas,
          icon: Icons.assignment,
          color: Colors.purple,
        ),
        KpiCardAnimated(
          title: 'Ciclos',
          value: _stats!.totalCiclos,
          icon: Icons.calendar_today,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildGraficos(bool isMobile, bool isTablet, bool isDesktop) {
    if (isDesktop) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DonutChartCiclos(
                    estudiantesPorCiclo: _stats!.estudiantesPorCiclo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BarChartSecciones(
                    estudiantesPorSeccion: _stats!.estudiantesPorSeccion,
                    totalEstudiantes: _stats!.totalEstudiantes,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CursosPorCicloAccordion(
                    cursosPorCiclo: _stats!.cursosPorCiclo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BarChartDocentes(
                    docentesCursos: _stats!.docentesCursos,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LineChartEvolucion(
            evolucionMatriculas: _stats!.evolucionMatriculas,
          ),
        ],
      );
    } else if (isTablet) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DonutChartCiclos(
                    estudiantesPorCiclo: _stats!.estudiantesPorCiclo,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: BarChartSecciones(
                    estudiantesPorSeccion: _stats!.estudiantesPorSeccion,
                    totalEstudiantes: _stats!.totalEstudiantes,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CursosPorCicloAccordion(cursosPorCiclo: _stats!.cursosPorCiclo),
          const SizedBox(height: 14),
          BarChartDocentes(docentesCursos: _stats!.docentesCursos),
          const SizedBox(height: 14),
          LineChartEvolucion(
            evolucionMatriculas: _stats!.evolucionMatriculas,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          DonutChartCiclos(estudiantesPorCiclo: _stats!.estudiantesPorCiclo),
          const SizedBox(height: 12),
          BarChartSecciones(
            estudiantesPorSeccion: _stats!.estudiantesPorSeccion,
            totalEstudiantes: _stats!.totalEstudiantes,
          ),
          const SizedBox(height: 12),
          CursosPorCicloAccordion(cursosPorCiclo: _stats!.cursosPorCiclo),
          const SizedBox(height: 12),
          BarChartDocentes(docentesCursos: _stats!.docentesCursos),
          const SizedBox(height: 12),
          LineChartEvolucion(
            evolucionMatriculas: _stats!.evolucionMatriculas,
          ),
        ],
      );
    }
  }
}