import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/loading_state_mixin.dart';
import '../../../core/mixins/snackbar_mixin.dart';
import '../../../core/mixins/auth_token_mixin.dart';

// Repositories
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/ciclo_repository.dart';

// Services
import '../../../data/services/ciclo_service.dart';

// Models
import '../../../data/models/ciclo.dart';

// Providers
import '../../../providers/auth_provider.dart';

// Widgets reutilizables
import '../../widgets/stat_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/action_button.dart';
import '../../widgets/activity_item.dart';
import '../../widgets/dashboard_layout.dart';

// Diálogos
import '../../widgets/dialogo_crear_editar_ciclo.dart';
import '../../widgets/dialogo_crear_curso.dart';
import '../../widgets/dialogo_crear_matricula.dart';

/// Dashboard principal del administrador
/// Responsabilidad: Mostrar estadísticas generales y acciones rápidas
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  final AdminRepository _adminRepository = AdminRepository();

  Map<String, dynamic> _stats = {
    'total_estudiantes': 0,
    'total_docentes': 0,
    'total_recetas': 0,
    'total_categorias': 0,
  };

  List<Ciclo> _ciclos = [];

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
    _cargarCiclos();
  }

  Future<void> _cargarCiclos() async {
    try {
      final token = getTokenSafe();
      if (token == null) {
        setState(() => _ciclos = []);
        return;
      }
      
      final ciclos = await CicloService.listarCiclos(token);
      if (mounted) {
        setState(() => _ciclos = ciclos);
      }
    } catch (e) {
      // Si hay error, asegurar que la lista esté vacía
      if (mounted) {
        setState(() => _ciclos = []);
      }
      print('Error al cargar ciclos: $e'); // Debug
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final stats = await executeWithLoading(() async {
        final token = getTokenSafe();
        if (token == null) return _stats;
        return await _adminRepository.obtenerEstadisticas(token);
      });

      if (stats != null && mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      showError('Error al cargar estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DashboardLayout(
      header: _buildHeader(context),
      stats: _buildStatsSection(context),
      actions: _buildQuickActions(context),
      recentActivity: _buildRecentActivity(),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dashboard', style: AppTheme.heading1),
        const SizedBox(height: 8),
        Text(
          'Resumen general del sistema',
          style: AppTheme.bodyLarge.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ==================== ESTADÍSTICAS ====================

  Widget _buildStatsSection(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isDesktop ? 1.4 : 1.1, // ✅ MÓVIL: 1.1 (más alto para evitar overflow)
      children: [
        StatCard(
          title: 'Estudiantes',
          value: '${_stats['total_estudiantes'] ?? 0}',
          icon: Icons.school,
          color: AppTheme.estudianteColor,
          subtitle: '+0 nuevos',
          onTap: () => Navigator.pushNamed(context, '/admin/usuarios'),
        ),
        StatCard(
          title: 'Docentes',
          value: '${_stats['total_docentes'] ?? 0}',
          icon: Icons.person,
          color: AppTheme.docenteColor,
          subtitle: '+0 nuevos',
          onTap: () => Navigator.pushNamed(context, '/admin/usuarios'),
        ),
        StatCard(
          title: 'Recetas',
          value: '${_stats['total_recetas'] ?? 0}',
          icon: Icons.restaurant_menu,
          color: AppTheme.accentColor,
          subtitle: '+0 esta semana',
          onTap: () => showInDevelopment('Recetas'),
        ),
        StatCard(
          title: 'Categorías',
          value: '${_stats['total_categorias'] ?? 0}',
          icon: Icons.category,
          color: Colors.purple,
          subtitle: 'Total activas',
          onTap: () => showInDevelopment('Categorías'),
        ),
      ],
    );
  }

  // ==================== ACCIONES RÁPIDAS ====================

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: AppTheme.warningColor, size: 24),
            const SizedBox(width: 8),
            Text('Acciones Rápidas', style: AppTheme.heading3),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionButton(
              label: 'Crear Usuario',
              icon: Icons.person_add,
              color: const Color(0xFF2563EB), // ✅ Azul brillante
              onTap: () => Navigator.pushNamed(context, '/admin/crear-usuario'),
            ),
            ActionButton(
              label: 'Crear Ciclo',
              icon: Icons.calendar_today,
              color: const Color(0xFF475569), // ✅ Gris oscuro (tema)
              onTap: () => _mostrarDialogoCrearCiclo(context),
            ),
            ActionButton(
              label: 'Crear Curso',
              icon: Icons.book,
              color: const Color(0xFFF97316), // ✅ Naranja
              onTap: () => _mostrarDialogoCrearCurso(context),
            ),
            ActionButton(
              label: 'Crear Matrícula',
              icon: Icons.assignment_ind,
              color: const Color(0xFF059669), // ✅ Verde esmeralda
              onTap: () => _mostrarDialogoCrearMatricula(context),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== FUNCIONES PARA ABRIR DIÁLOGOS ====================

  Future<void> _mostrarDialogoCrearCiclo(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => DialogoCrearEditarCiclo(
        onGuardar: () {
          _cargarEstadisticas();
          _cargarCiclos();
        },
      ),
    );
  }

  Future<void> _mostrarDialogoCrearCurso(BuildContext context) async {
    // ✅ FIX: Verificar si _ciclos está vacío o es null de forma segura
    if (_ciclos == null || _ciclos.isEmpty) {
      showError('Primero crea un ciclo académico');
      return;
    }

    try {
      await showDialog(
        context: context,
        builder: (context) => DialogoCrearCurso(
          ciclos: _ciclos,
          onGuardar: () {
            _cargarEstadisticas();
          },
        ),
      );
    } catch (e) {
      showError('Error al abrir diálogo: $e');
    }
  }

  Future<void> _mostrarDialogoCrearMatricula(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const DialogoCrearMatricula(),
    );

    if (result == true) {
      _cargarEstadisticas();
      showSuccess('Matrícula creada exitosamente');
    }
  }

  // ==================== ACTIVIDAD RECIENTE ====================

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: AppTheme.infoColor, size: 24),
            const SizedBox(width: 8),
            Text('Actividad Reciente', style: AppTheme.heading3),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ActivityItem(
                  title: 'Sistema iniciado',
                  subtitle: 'El administrador inició sesión',
                  icon: Icons.login,
                  color: AppTheme.successColor,
                  time: 'Hace unos momentos',
                ),
                const Divider(height: 24),
                EmptyState(
                  icon: Icons.event_note,
                  title: 'No hay más actividad',
                  subtitle: 'Las actividades recientes aparecerán aquí',
                  iconColor: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}