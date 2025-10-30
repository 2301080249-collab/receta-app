import 'package:flutter/material.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/loading_state_mixin.dart';
import '../../../core/mixins/snackbar_mixin.dart';
import '../../../core/mixins/auth_token_mixin.dart';

// Models
import '../../../data/models/ciclo.dart';
import '../../../data/models/matricula.dart';

// Services
import '../../../data/services/ciclo_service.dart';
import '../../../data/services/matricula_service.dart';

// Widgets
import '../../widgets/dialogo_crear_matricula.dart';
import '../../widgets/dialogo_matricula_masiva.dart';
import '../../widgets/dialogo_editar_matricula.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

/// Pantalla de gestión de matrículas - DISEÑO UNIFICADO RESPONSIVE
class MatriculasScreen extends StatefulWidget {
  const MatriculasScreen({super.key});

  @override
  State<MatriculasScreen> createState() => _MatriculasScreenState();
}

class _MatriculasScreenState extends State<MatriculasScreen>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  List<Matricula> _matriculas = [];
  List<Matricula> _matriculasFiltradas = [];
  List<Ciclo> _ciclos = [];
  
  final TextEditingController _searchController = TextEditingController();
  String? _filtroCicloId;
  String _filtroEstado = 'todos'; // todos, activos, completados, retirados

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== CARGAR DATOS ====================

  Future<void> _cargarDatos() async {
    try {
      final results = await executeWithLoading(() async {
        final token = getToken();
        
        return await Future.wait([
          MatriculaService.listarTodasLasMatriculas(token: token),
          CicloService.listarCiclos(token),
        ]);
      });

      if (results != null && mounted) {
        setState(() {
          _matriculas = results[0] as List<Matricula>;
          _ciclos = results[1] as List<Ciclo>;
          _aplicarFiltros();
        });
      }
    } catch (e) {
      showError('Error al cargar datos: $e');
    }
  }

  // ==================== APLICAR FILTROS ====================

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _matriculasFiltradas = _matriculas.where((matricula) {
        // Filtro por búsqueda
        final cumpleBusqueda = query.isEmpty ||
            (matricula.nombreEstudiante?.toLowerCase().contains(query) ?? false) ||
            (matricula.codigoEstudiante?.toLowerCase().contains(query) ?? false) ||
            (matricula.nombreCurso?.toLowerCase().contains(query) ?? false);

        // Filtro por ciclo
        final cumpleFiltroCiclo =
            _filtroCicloId == null || matricula.cicloId == _filtroCicloId;

        // Filtro por estado
        final cumpleFiltroEstado = _filtroEstado == 'todos' ||
            (_filtroEstado == 'activos' && matricula.estado == 'activo') ||
            (_filtroEstado == 'completados' && matricula.estado == 'completado') ||
            (_filtroEstado == 'retirados' && matricula.estado == 'retirado');

        return cumpleBusqueda && cumpleFiltroCiclo && cumpleFiltroEstado;
      }).toList();
    });
  }

  // ==================== CREAR MATRÍCULA ====================

  Future<void> _mostrarDialogoCrearMatricula() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DialogoCrearMatricula(),
    );

    if (resultado == true) {
      _cargarDatos();
      showSuccess('Matrícula creada exitosamente');
    }
  }

  // ✅ MATRÍCULA MASIVA
  Future<void> _mostrarDialogoMatriculaMasiva() async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DialogoMatriculaMasiva(),
    );

    if (resultado == true) {
      _cargarDatos();
      showSuccess('Matrículas creadas exitosamente');
    }
  }

  // ==================== EDITAR MATRÍCULA ====================

  Future<void> _mostrarDialogoEditarMatricula(Matricula matricula) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogoEditarMatricula(matricula: matricula),
    );

    if (resultado == true) {
      _cargarDatos();
      showSuccess('Matrícula actualizada exitosamente');
    }
  }

  // ==================== ELIMINAR MATRÍCULA ====================

  Future<void> _eliminarMatricula(Matricula matricula) async {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: '¿Eliminar matrícula?',
        message:
            '¿Está seguro de eliminar la matrícula de ${matricula.nombreEstudiante ?? "este estudiante"}?',
        warningMessage: 'Esta acción no se puede deshacer',
        confirmText: 'Eliminar',
        cancelText: 'Cancelar',
        onConfirm: () async {
          try {
            await executeWithLoading(() async {
              final token = getToken();
              await MatriculaService.eliminarMatricula(
                token: token,
                matriculaId: matricula.id,
              );
            });

            showSuccess('Matrícula eliminada exitosamente');
            _cargarDatos();
          } catch (e) {
            showError('Error al eliminar: $e');
          }
        },
      ),
    );
  }

  // ==================== UI - BUILD PRINCIPAL ====================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matriculas.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_rounded,
        title: 'No hay matrículas registradas',
        subtitle: 'Comienza creando la primera matrícula',
        buttonText: 'Crear Primera Matrícula',
        onButtonPressed: _mostrarDialogoCrearMatricula,
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
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
            child: _matriculasFiltradas.isEmpty
                ? _buildNoResults()
                : isMobile
                    ? _buildListaMovil()      // 📱 Lista vertical para móvil
                    : _buildTablaWeb(),       // 💻 Tabla para web
          ),
        ],
      ),
    );
  }

  // ==================== HEADER ====================

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
                  color: Color(0xFF334155), // Azul oscuro del sidebar
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF334155).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.assignment_rounded,
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
                      'Lista de matrículas (${_matriculas.length})',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestiona las matrículas de estudiantes',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 16),
          _buildBotonesAccion(isMobile),
        ],
      ],
    );
  }

  Widget _buildBotonesAccion(bool isMobile) {
    return Row(
      children: [
        // Botón Matrícula Masiva
        ElevatedButton.icon(
          onPressed: _mostrarDialogoMatriculaMasiva,
          icon: Icon(Icons.group_add_rounded, size: isMobile ? 18 : 20),
          label: Text(
            isMobile ? 'Masiva' : 'Matrícula Masiva',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF334155), // ✅ Azul oscuro
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 12 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Botón Crear Matrícula
        ElevatedButton.icon(
          onPressed: _mostrarDialogoCrearMatricula,
          icon: Icon(Icons.add_rounded, size: isMobile ? 18 : 20),
          label: Text(
            isMobile ? 'Crear' : 'Crear Matrícula',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF334155), // ✅ Azul oscuro
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 12 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== BARRA DE FILTROS ====================

  Widget _buildFiltersBar(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          // Búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por estudiante, código o curso...',
              hintStyle: TextStyle(fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Filtros
          Row(
            children: [
              // Filtro por Ciclo
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _filtroCicloId,
                      hint: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 8),
                          Text('Ciclo',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Todos', style: TextStyle(fontSize: 13)),
                        ),
                        ..._ciclos.map((ciclo) => DropdownMenuItem(
                              value: ciclo.id,
                              child: Text(ciclo.nombre,
                                  style: TextStyle(fontSize: 13)),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filtroCicloId = value;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filtro por Estado
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroEstado,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'todos',
                          child: Row(
                            children: [
                              Icon(Icons.flag_rounded,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text('Todos', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'activos',
                          child: Text('Activos', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'completados',
                          child: Text('Completados',
                              style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'retirados',
                          child: Text('Retirados',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filtroEstado = value!;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Botones de acción en móvil
          _buildBotonesAccion(isMobile),
        ],
      );
    }

    // Filtros para WEB
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por estudiante, código o curso...',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 200,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _filtroCicloId,
              hint: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Todos los ciclos'),
                ],
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('Todos los ciclos'),
                ),
                ..._ciclos.map((ciclo) => DropdownMenuItem(
                      value: ciclo.id,
                      child: Text(ciclo.nombre),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroCicloId = value;
                  _aplicarFiltros();
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 180,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filtroEstado,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'todos',
                  child: Row(
                    children: [
                      Icon(Icons.flag_rounded,
                          size: 18, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text('Todos'),
                    ],
                  ),
                ),
                DropdownMenuItem(value: 'activos', child: Text('Activos')),
                DropdownMenuItem(
                    value: 'completados', child: Text('Completados')),
                DropdownMenuItem(value: 'retirados', child: Text('Retirados')),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroEstado = value!;
                  _aplicarFiltros();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==================== VISTA MÓVIL - LISTA VERTICAL ====================

  Widget _buildListaMovil() {
    return ListView.builder(
      itemCount: _matriculasFiltradas.length,
      itemBuilder: (context, index) {
        final matricula = _matriculasFiltradas[index];
        return _buildMatriculaCard(matricula);
      },
    );
  }

  Widget _buildMatriculaCard(Matricula matricula) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Avatar + Nombre del Estudiante
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                  child: Text(
                    (matricula.nombreEstudiante ?? 'E')[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matricula.nombreEstudiante ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ciclo: ${matricula.cicloActualRomano} | Sección: ${matricula.seccionEstudiante ?? "--"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 16),

            // Fila 2: Curso
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.book_rounded, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curso',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        matricula.nombreCurso ?? 'Sin curso',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nivel: ${matricula.nivelRomano} | Sección: ${matricula.seccionCurso ?? "--"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (matricula.nombreDocente != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          matricula.nombreDocente!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Fila 3: Ciclo Académico
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ciclo Académico',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      matricula.nombreCiclo ?? '--',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 16),

            // Fila 4: Estado + Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(matricula.estado)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getEstadoColor(matricula.estado)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        matricula.estadoLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getEstadoColor(matricula.estado),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (matricula.notaFinal != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Nota: ${matricula.notaFinal}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Botones de acción
                Row(
                  children: [
                    // Botón Editar
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () =>
                            _mostrarDialogoEditarMatricula(matricula),
                        icon: Icon(Icons.edit_rounded, size: 20),
                        color: Color(0xFF3B82F6),
                        tooltip: 'Editar',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón Eliminar
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _eliminarMatricula(matricula),
                        icon: Icon(Icons.delete_rounded, size: 20),
                        color: Color(0xFFDC2626),
                        tooltip: 'Eliminar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== VISTA WEB - TABLA ====================

  Widget _buildTablaWeb() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildTablaHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _matriculasFiltradas.length,
              itemBuilder: (context, index) {
                return _buildMatriculaRow(
                    _matriculasFiltradas[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Estudiante',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Curso',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Ciclo Académico',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Estado',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            width: 240,
            child: Text(
              'Acciones',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatriculaRow(Matricula matricula, int index) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          _buildEstudianteColumn(matricula),
          _buildCursoColumn(matricula),
          _buildCicloColumn(matricula),
          _buildEstadoColumn(matricula),
          _buildAccionesColumn(matricula),
        ],
      ),
    );
  }

  Widget _buildEstudianteColumn(Matricula matricula) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.accentColor.withOpacity(0.1),
            child: Text(
              (matricula.nombreEstudiante ?? 'E')[0].toUpperCase(),
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matricula.nombreEstudiante ?? 'Sin nombre',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ciclo: ${matricula.cicloActualRomano} | Sección: ${matricula.seccionEstudiante ?? "--"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCursoColumn(Matricula matricula) {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            matricula.nombreCurso ?? 'Sin curso',
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Nivel: ${matricula.nivelRomano} | Sección: ${matricula.seccionCurso ?? "--"}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (matricula.nombreDocente != null) ...[
            const SizedBox(height: 2),
            Text(
              matricula.nombreDocente!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCicloColumn(Matricula matricula) {
    return Expanded(
      flex: 2,
      child: Text(
        matricula.nombreCiclo ?? '--',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEstadoColumn(Matricula matricula) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getEstadoColor(matricula.estado).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getEstadoColor(matricula.estado).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              matricula.estadoLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _getEstadoColor(matricula.estado),
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (matricula.notaFinal != null) ...[
            const SizedBox(height: 6),
            Text(
              'Nota: ${matricula.notaFinal}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccionesColumn(Matricula matricula) {
    return SizedBox(
      width: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoEditarMatricula(matricula),
            icon: Icon(Icons.edit_rounded, size: 16),
            label: Text(
              'Editar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size(100, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _eliminarMatricula(matricula),
            icon: Icon(Icons.delete_rounded, size: 16),
            label: Text(
              'Eliminar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size(100, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NO RESULTS ====================

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activo':
        return AppTheme.successColor; // Verde
      case 'retirado':
        return AppTheme.warningColor; // Naranja/Amarillo
      case 'completado':
        return AppTheme.infoColor; // Azul
      default:
        return Colors.grey[600]!;
    }
  }
}