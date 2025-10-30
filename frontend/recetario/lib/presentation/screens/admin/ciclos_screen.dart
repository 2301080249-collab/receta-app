import 'package:flutter/material.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/loading_state_mixin.dart';
import '../../../core/mixins/snackbar_mixin.dart';
import '../../../core/mixins/auth_token_mixin.dart';

// Repositories
import '../../../data/repositories/ciclo_repository.dart';

// Models
import '../../../data/models/ciclo.dart';

// Widgets
import '../../widgets/empty_state.dart';
import '../../widgets/ciclo_card_modern.dart';
import '../../widgets/dialogo_crear_editar_ciclo.dart';

/// Pantalla de gestión de ciclos académicos - DISEÑO UNIFICADO CON USUARIOS
class CiclosScreen extends StatefulWidget {
  const CiclosScreen({Key? key}) : super(key: key);

  @override
  State<CiclosScreen> createState() => _CiclosScreenState();
}

class _CiclosScreenState extends State<CiclosScreen>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  final CicloRepository _cicloRepository = CicloRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<Ciclo> _ciclos = [];
  List<Ciclo> _ciclosFiltrados = [];
  String _filtroEstado = 'todos'; // todos, activos, inactivos

  @override
  void initState() {
    super.initState();
    _cargarCiclos();
    _searchController.addListener(_filtrarCiclos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarCiclos() async {
    try {
      final ciclos = await executeWithLoading(() async {
        final token = getToken();
        return await _cicloRepository.listarCiclos(token);
      });

      if (ciclos != null && mounted) {
        setState(() {
          _ciclos = ciclos;
          _filtrarCiclos();
        });
      }
    } catch (e) {
      showError('Error al cargar ciclos: ${e.toString()}');
    }
  }

  void _filtrarCiclos() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      // Primero filtrar por estado
      var ciclosPorEstado = _ciclos;
      if (_filtroEstado == 'activos') {
        ciclosPorEstado = _ciclos.where((c) => c.activo).toList();
      } else if (_filtroEstado == 'inactivos') {
        ciclosPorEstado = _ciclos.where((c) => !c.activo).toList();
      }
      
      // Luego filtrar por búsqueda
      if (query.isEmpty) {
        _ciclosFiltrados = ciclosPorEstado;
      } else {
        _ciclosFiltrados = ciclosPorEstado.where((ciclo) {
          return ciclo.nombre.toLowerCase().contains(query) ||
                 ciclo.rangoFechas.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _activarDesactivarCiclo(Ciclo ciclo) async {
    try {
      await executeWithLoading(() async {
        final token = getToken();
        
        if (ciclo.activo) {
          await _cicloRepository.desactivarCiclo(token, ciclo.id);
        } else {
          await _cicloRepository.activarCiclo(token, ciclo.id);
        }
      });

      showSuccess(
        ciclo.activo
            ? 'Ciclo desactivado correctamente'
            : 'Ciclo activado correctamente',
      );
      _cargarCiclos();
    } catch (e) {
      showError('Error: ${e.toString()}');
    }
  }

  void _editarCiclo(Ciclo ciclo) {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearEditarCiclo(
        ciclo: ciclo,
        onGuardar: _cargarCiclos,
      ),
    );
  }

  Future<void> _eliminarCiclo(Ciclo ciclo) async {
    final confirmar = await _mostrarConfirmacion(ciclo);
    if (confirmar != true) return;

    try {
      await executeWithLoading(() async {
        final token = getToken();
        await _cicloRepository.eliminarCiclo(token, ciclo.id);
      });

      showSuccess('Ciclo eliminado exitosamente');
      _cargarCiclos();
    } catch (e) {
      showError('Error al eliminar: ${e.toString()}');
    }
  }

  Future<bool?> _mostrarConfirmacion(Ciclo ciclo) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 12),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Está seguro de eliminar el ciclo "${ciclo.nombre}"?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearCiclo() {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearEditarCiclo(
        onGuardar: _cargarCiclos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ciclos.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No hay ciclos registrados',
        subtitle: 'Comienza creando tu primer ciclo académico',
        buttonText: 'Crear Primer Ciclo',
        onButtonPressed: _mostrarDialogoCrearCiclo,
      );
    }

    // 📱 Detectar si es móvil o desktop
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 32,
            isMobile ? 16 : 32,
            isMobile ? 16 : 32,
            isMobile ? 80 : 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              SizedBox(height: isMobile ? 16 : 24),
              _buildFiltersBar(isMobile),
              SizedBox(height: isMobile ? 16 : 20),
              Expanded(
                child: _ciclosFiltrados.isEmpty
                    ? _buildNoResults()
                    : isMobile
                        ? _buildMobileList()
                        : _buildDesktopGrid(),
              ),
            ],
          ),
        ),
        // ✅ BOTÓN FLOTANTE PARA MÓVIL (Color del sidebar)
        if (isMobile)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _mostrarDialogoCrearCiclo,
              backgroundColor: const Color(0xFF475569), // ✅ Color del sidebar
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Crear Ciclo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 6,
              heroTag: 'crear_ciclo_fab',
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Color(0xFF475569),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF475569).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.event_rounded,
                  color: Colors.white,
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lista de ciclos (${_ciclos.length})',
                      style: isMobile
                          ? AppTheme.heading3
                          : AppTheme.heading2.copyWith(fontSize: 24),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Gestiona los ciclos académicos del sistema',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            onPressed: _cargarCiclos,
            tooltip: 'Actualizar',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              padding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _mostrarDialogoCrearCiclo,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Crear Ciclo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFiltersBar(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar...',
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                    onPressed: () {
                      _searchController.clear();
                      _filtrarCiclos();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.accentColor, width: 2),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        
        Row(
          children: [
            if (!isMobile)
              Text(
                'Filtrar por rol:',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            if (!isMobile) const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', 'todos'),
                    _buildFilterChip('Activos', 'activos'),
                    _buildFilterChip('Inactivos', 'inactivos'),
                  ],
                ),
              ),
            ),
            if (!isMobile) ...[
              const Spacer(),
              Text(
                '${_ciclosFiltrados.length} resultado${_ciclosFiltrados.length != 1 ? "s" : ""}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroEstado == value;
    
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isSelected) {
      switch (value) {
        case 'todos':
          backgroundColor = Color(0xFF475569).withOpacity(0.15);
          borderColor = Color(0xFF475569);
          textColor = Color(0xFF475569);
          break;
        case 'activos':
          backgroundColor = AppTheme.successColor.withOpacity(0.15);
          borderColor = AppTheme.successColor;
          textColor = AppTheme.successColor;
          break;
        case 'inactivos':
          backgroundColor = AppTheme.errorColor.withOpacity(0.15);
          borderColor = AppTheme.errorColor;
          textColor = AppTheme.errorColor;
          break;
        default:
          backgroundColor = Colors.grey[100]!;
          borderColor = Colors.grey[300]!;
          textColor = AppTheme.textSecondary;
      }
    } else {
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.transparent;
      textColor = AppTheme.textSecondary;
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroEstado = value;
            _filtrarCiclos();
          });
        },
        backgroundColor: backgroundColor,
        selectedColor: backgroundColor,
        checkmarkColor: textColor,
        labelStyle: TextStyle(
          color: textColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return RefreshIndicator(
      onRefresh: _cargarCiclos,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _ciclosFiltrados.length,
        itemBuilder: (context, index) {
          final ciclo = _ciclosFiltrados[index];
          return CicloCardMobile(
            ciclo: ciclo,
            onActivar: () => _activarDesactivarCiclo(ciclo),
            onEditar: () => _editarCiclo(ciclo),
            onEliminar: () => _eliminarCiclo(ciclo),
          );
        },
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return RefreshIndicator(
      onRefresh: _cargarCiclos,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
          childAspectRatio: 1.2, 
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _ciclosFiltrados.length,
        itemBuilder: (context, index) {
          final ciclo = _ciclosFiltrados[index];
          return CicloCardDesktop(
            ciclo: ciclo,
            onActivar: () => _activarDesactivarCiclo(ciclo),
            onEditar: () => _editarCiclo(ciclo),
            onEliminar: () => _eliminarCiclo(ciclo),
          );
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: AppTheme.heading3.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos de búsqueda',
            style: AppTheme.bodyMedium.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _filtroEstado = 'todos');
              _filtrarCiclos();
            },
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: const Text('Limpiar filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}