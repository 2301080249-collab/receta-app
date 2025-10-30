import 'package:flutter/material.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/loading_state_mixin.dart';
import '../../../core/mixins/snackbar_mixin.dart';
import '../../../core/mixins/auth_token_mixin.dart';

// Repositories
import '../../../data/repositories/curso_repository.dart';
import '../../../data/repositories/ciclo_repository.dart';

// Models
import '../../../data/models/curso.dart';
import '../../../data/models/ciclo.dart';

// Widgets
import '../../widgets/empty_state.dart';
import '../../widgets/curso_card_modern.dart';
import '../../widgets/dialogo_crear_curso.dart';

/// Pantalla de gestión de cursos - DISEÑO UNIFICADO CON USUARIOS Y CICLOS
class CursosScreen extends StatefulWidget {
  const CursosScreen({Key? key}) : super(key: key);

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  final CursoRepository _cursoRepository = CursoRepository();
  final CicloRepository _cicloRepository = CicloRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Curso> _cursos = [];
  List<Curso> _cursosFiltrados = [];
  List<Ciclo> _ciclos = [];
  
  String? _cicloFiltro;
  String _filtroEstado = 'todos'; // todos, activos, inactivos

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrarCursos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final results = await executeWithLoading(() async {
        final token = getToken();
        
        return await Future.wait([
          _cicloRepository.listarCiclos(token),
          _cursoRepository.listarCursos(token),
        ]);
      });

      if (results != null && mounted) {
        setState(() {
          _ciclos = results[0] as List<Ciclo>;
          _cursos = results[1] as List<Curso>;
          _filtrarCursos();
        });
      }
    } catch (e) {
      showError('Error al cargar datos: ${e.toString()}');
    }
  }

  void _filtrarCursos() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      // Filtrar por ciclo
      var cursosPorCiclo = _cursos;
      if (_cicloFiltro != null) {
        cursosPorCiclo = _cursos.where((c) => c.cicloId == _cicloFiltro).toList();
      }
      
      // Filtrar por estado
      var cursosPorEstado = cursosPorCiclo;
      if (_filtroEstado == 'activos') {
        cursosPorEstado = cursosPorCiclo.where((c) => c.activo).toList();
      } else if (_filtroEstado == 'inactivos') {
        cursosPorEstado = cursosPorCiclo.where((c) => !c.activo).toList();
      }
      
      // Filtrar por búsqueda
      if (query.isEmpty) {
        _cursosFiltrados = cursosPorEstado;
      } else {
        _cursosFiltrados = cursosPorEstado.where((curso) {
          return curso.nombre.toLowerCase().contains(query) ||
                 (curso.descripcion?.toLowerCase().contains(query) ?? false) ||
                 (curso.docenteNombre?.toLowerCase().contains(query) ?? false) ||
                 (curso.seccion?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _eliminarCurso(Curso curso) async {
    final confirmar = await _mostrarConfirmacion(curso);
    if (confirmar != true) return;

    try {
      await executeWithLoading(() async {
        final token = getToken();
        await _cursoRepository.eliminarCurso(token, curso.id);
      });

      showSuccess('Curso eliminado exitosamente');
      _cargarDatos();
    } catch (e) {
      showError('Error al eliminar: ${e.toString()}');
    }
  }

  Future<void> _activarDesactivarCurso(Curso curso) async {
    try {
      await executeWithLoading(() async {
        final token = getToken();
        
        if (curso.activo) {
          await _cursoRepository.desactivarCurso(token, curso.id);
        } else {
          await _cursoRepository.activarCurso(token, curso.id);
        }
      });

      showSuccess(curso.activo ? 'Curso desactivado' : 'Curso activado');
      _cargarDatos();
    } catch (e) {
      showError('Error: ${e.toString()}');
    }
  }

  Future<bool?> _mostrarConfirmacion(Curso curso) {
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
          '¿Está seguro de eliminar el curso "${curso.nombre}"?\n\nEsta acción no se puede deshacer.',
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

  void _mostrarDialogoCrearCurso() {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearCurso(
        ciclos: _ciclos,
        onGuardar: _cargarDatos,
      ),
    );
  }

  // ✅ NUEVO: Método para editar curso
  void _editarCurso(Curso curso) {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearCurso(
        ciclos: _ciclos,
        onGuardar: _cargarDatos,
        curso: curso, // ✅ Pasar el curso a editar
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cursos.isEmpty) {
      return EmptyState(
        icon: Icons.school_rounded,
        title: 'No hay cursos registrados',
        subtitle: 'Comienza creando tu primer curso',
        buttonText: 'Crear Primer Curso',
        onButtonPressed: _mostrarDialogoCrearCurso,
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
                child: _cursosFiltrados.isEmpty
                    ? _buildNoResults()
                    : isMobile
                        ? _buildMobileList()
                        : _buildDesktopGrid(),
              ),
            ],
          ),
        ),
        // ✅ BOTÓN FLOTANTE PARA MÓVIL
        if (isMobile)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _mostrarDialogoCrearCurso,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
              tooltip: 'Crear Curso',
            ),
          ),
      ],
    );
  }

  // ✅ HEADER SIN BOTÓN EN MÓVIL (ya que está flotante abajo)
  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // ✅ CAMBIO: Ícono con color del sidebar
              Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor, // ✅ Color del sidebar (azul)
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_rounded,
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
                      'Lista de cursos (${_cursosFiltrados.length})',
                      style: AppTheme.heading2.copyWith(
                        fontSize: isMobile ? 18 : 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 🖥️ Botones solo en desktop
        if (!isMobile) ...[
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              padding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _mostrarDialogoCrearCurso,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Crear Curso'),
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

  // ✅ BARRA DE FILTROS
  Widget _buildFiltersBar(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Búsqueda
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
                      _filtrarCursos();
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
        
        // Filtros
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
                    _buildCicloDropdown(),
                    const SizedBox(width: 8),
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
                '${_cursosFiltrados.length} resultado${_cursosFiltrados.length != 1 ? "s" : ""}',
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

  Widget _buildCicloDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _cicloFiltro != null
            ? AppTheme.accentColor.withOpacity(0.15)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _cicloFiltro != null
              ? AppTheme.accentColor
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _cicloFiltro,
          hint: Text(
            'Todos los ciclos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: _cicloFiltro != null
                ? AppTheme.accentColor
                : AppTheme.textSecondary,
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentColor,
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('Todos los ciclos'),
            ),
            ..._ciclos.map(
              (ciclo) => DropdownMenuItem(
                value: ciclo.id,
                child: Text(ciclo.nombre),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _cicloFiltro = value;
              _filtrarCursos();
            });
          },
        ),
      ),
    );
  }

  // ✅ CAMBIO PRINCIPAL: Filtros con colores dinámicos
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroEstado == value;
    
    // ✅ Definir colores según el estado
    Color chipColor;
    Color borderColor;
    Color textColor;
    
    if (isSelected) {
      switch (value) {
        case 'todos':
  chipColor = Color(0xFF475569).withOpacity(0.15); // ✅ Gris igual que ciclos
  borderColor = Color(0xFF475569);
  textColor = Color(0xFF475569);
          break;
        case 'activos':
          chipColor = Color(0xFF10B981).withOpacity(0.15); // Verde
          borderColor = Color(0xFF10B981);
          textColor = Color(0xFF10B981);
          break;
        case 'inactivos':
          chipColor = Color(0xFFEF4444).withOpacity(0.15); // Rojo
          borderColor = Color(0xFFEF4444);
          textColor = Color(0xFFEF4444);
          break;
        default:
          chipColor = Colors.grey[100]!;
          borderColor = Colors.transparent;
          textColor = AppTheme.textSecondary;
      }
    } else {
      chipColor = Colors.grey[100]!;
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
            _filtrarCursos();
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: chipColor,
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
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _cursosFiltrados.length,
        itemBuilder: (context, index) {
          final curso = _cursosFiltrados[index];
          return CursoCardMobile(
            curso: curso,
            onActivar: () => _activarDesactivarCurso(curso),
            onEditar: () => _editarCurso(curso), // ✅ CAMBIO
            onEliminar: () => _eliminarCurso(curso),
          );
        },
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 : 3,
          childAspectRatio: 1.15,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _cursosFiltrados.length,
        itemBuilder: (context, index) {
          final curso = _cursosFiltrados[index];
          return CursoCardDesktop(
            curso: curso,
            onActivar: () => _activarDesactivarCurso(curso),
            onEditar: () => _editarCurso(curso), // ✅ CAMBIO
            onEliminar: () => _eliminarCurso(curso),
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
              setState(() {
                _cicloFiltro = null;
                _filtroEstado = 'todos';
              });
              _filtrarCursos();
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