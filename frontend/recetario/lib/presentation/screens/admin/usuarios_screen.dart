import 'package:flutter/material.dart';
import 'dart:math';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/loading_state_mixin.dart';
import '../../../core/mixins/snackbar_mixin.dart';
import '../../../core/mixins/auth_token_mixin.dart';

// Repositories
import '../../../data/repositories/admin_repository.dart';

// Widgets
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/role_avatar.dart';
import '../../widgets/usuario_card.dart';

// Screens
import 'crear_usuario_screen.dart';

/// Pantalla de gestión de usuarios con tabla moderna y profesional
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({Key? key}) : super(key: key);

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  final AdminRepository _adminRepository = AdminRepository();
  List<dynamic> _usuarios = [];
  List<dynamic> _usuariosFiltrados = [];
  
  // Controladores de búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _criterioBusqueda = 'nombre';
  
  // Filtro por rol
  String _filtroRol = 'todos';
  
  // Paginación
  int _currentPage = 0;
  final int _rowsPerPage = 5;

  // Hover state
  int? _hoveredRowIndex;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _searchController.addListener(_filtrarUsuarios);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    try {
      final usuarios = await executeWithLoading(() async {
        final token = getToken();
        return await _adminRepository.obtenerUsuarios(token);
      });

      if (usuarios != null && mounted) {
        setState(() {
          _usuarios = usuarios;
          _usuariosFiltrados = usuarios;
        });
      }
    } catch (e) {
      showError('Error al cargar usuarios: $e');
    }
  }

  void _filtrarUsuarios() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      // Primero filtramos por rol
      var usuariosPorRol = _usuarios;
      if (_filtroRol != 'todos') {
        usuariosPorRol = _usuarios.where((usuario) {
          return (usuario['rol'] ?? '').toLowerCase() == _filtroRol;
        }).toList();
      }
      
      // Luego filtramos por búsqueda
      if (query.isEmpty) {
        _usuariosFiltrados = usuariosPorRol;
      } else {
        _usuariosFiltrados = usuariosPorRol.where((usuario) {
          switch (_criterioBusqueda) {
            case 'nombre':
              final nombre = (usuario['nombre_completo'] ?? '').toLowerCase();
              return nombre.contains(query);
            
            case 'email':
              final email = (usuario['email'] ?? '').toLowerCase();
              return email.contains(query);
            
            case 'codigo':
              String? codigo = _obtenerCodigo(usuario);
              return (codigo ?? '').toLowerCase().contains(query);
            
            default:
              return false;
          }
        }).toList();
      }
      
      _currentPage = 0;
    });
  }

  String? _obtenerCodigo(dynamic usuario) {
    if (usuario['rol'] == 'estudiante' &&
        usuario['estudiantes'] != null &&
        usuario['estudiantes'].isNotEmpty) {
      return usuario['estudiantes'][0]['codigo_estudiante'];
    } else if (usuario['rol'] == 'docente' &&
        usuario['docentes'] != null &&
        usuario['docentes'].isNotEmpty) {
      return usuario['docentes'][0]['codigo_docente'];
    } else if (usuario['rol'] == 'administrador') {
      return usuario['codigo'];
    }
    return usuario['codigo'];
  }

  String _obtenerRolDisplay(dynamic usuario) {
    if (usuario['rol'] == 'estudiante' &&
        usuario['estudiantes'] != null &&
        usuario['estudiantes'].isNotEmpty) {
      final est = usuario['estudiantes'][0];
      final especialidad = est['especialidad'] ?? '';
      return especialidad.isNotEmpty ? especialidad : 'Estudiante';
    } else if (usuario['rol'] == 'docente' &&
        usuario['docentes'] != null &&
        usuario['docentes'].isNotEmpty) {
      final doc = usuario['docentes'][0];
      return doc['especialidad'] ?? 'Docente';
    }
    return 'Administrador';
  }

  Future<void> _irACrearUsuario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearUsuarioScreen()),
    );

    if (resultado == true) _cargarUsuarios();
  }

  void _irAEditarUsuario(dynamic usuario) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearUsuarioScreen(
          usuario: usuario,
          esEdicion: true,
        ),
      ),
    );
    
    if (resultado == true) _cargarUsuarios();
  }

  void _confirmarEliminar(dynamic usuario) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Confirmar Eliminación',
        message: '¿Estás seguro de eliminar este usuario?',
        warningMessage: '⚠️ Esta acción no se puede deshacer',
        confirmText: 'Eliminar',
        onConfirm: () => _eliminarUsuario(usuario),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario['nombre_completo'] ?? '',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                usuario['email'] ?? '',
                style: AppTheme.bodyMedium.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarUsuario(dynamic usuario) async {
    try {
      await executeWithLoading(() async {
        final token = getToken();
        await _adminRepository.eliminarUsuario(usuario['id'], token);
      });

      showSuccess('Usuario eliminado correctamente');
      _cargarUsuarios();
    } catch (e) {
      showError('Error al eliminar usuario: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuarios.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No hay usuarios creados',
        subtitle: 'Comienza creando tu primer usuario',
        buttonText: 'Crear Primer Usuario',
        onButtonPressed: _irACrearUsuario,
      );
    }

    // 📱 Detectar si es móvil o desktop
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        isMobile ? 16 : 32,
        isMobile ? 16 : 32,
        isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          if (!isMobile) _buildFiltersBar(),
          if (!isMobile) const SizedBox(height: 20),
          Expanded(
            child: _usuariosFiltrados.isEmpty
                ? _buildNoResultsFound()
                : isMobile
                    ? _buildMobileList() // 📱 Vista móvil
                    : _buildTable(),      // 💻 Vista desktop
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.people_rounded,
                size: isMobile ? 24 : 28,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Lista de usuarios (${_usuariosFiltrados.length})',
                  style: AppTheme.heading2.copyWith(
                    fontSize: isMobile ? 18 : 22,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
              onPressed: _cargarUsuarios,
              tooltip: 'Actualizar lista',
            ),
            if (!isMobile) const SizedBox(width: 8),
            if (isMobile)
              IconButton(
                onPressed: _irACrearUsuario,
                icon: Icon(Icons.person_add_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _irACrearUsuario,
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: const Text('Crear Usuario'),
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
        ),
      ],
    );
  }

  Widget _buildFiltersBar() {
    return Row(
      children: [
        Text(
          'Filtrar por rol:',
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        _buildFilterChip('Todos', 'todos'),
        _buildFilterChip('Administradores', 'administrador'),
        _buildFilterChip('Docentes', 'docente'),
        _buildFilterChip('Estudiantes', 'estudiante'),
        const Spacer(),
        Text(
          '${_usuariosFiltrados.length} resultados',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
  final isSelected = _filtroRol == value;
  
  // 🎨 Colores según el rol seleccionado
  Color backgroundColor;
  Color borderColor;
  Color textColor;
  
  if (isSelected) {
    switch (value) {
      case 'administrador':
        backgroundColor = Color(0xFFFEF3C7); // amarillo claro
        borderColor = Color(0xFFF59E0B); // amarillo
        textColor = Color(0xFFD97706); // amarillo oscuro
        break;
      case 'docente':
        backgroundColor = Color(0xFFD1FAE5); // verde claro
        borderColor = Color(0xFF10B981); // verde
        textColor = Color(0xFF059669); // verde oscuro
        break;
      case 'estudiante':
        backgroundColor = Color(0xFFDBEAFE); // azul claro
        borderColor = Color(0xFF3B82F6); // azul
        textColor = Color(0xFF2563EB); // azul oscuro
        break;
      default: // 'todos'
  backgroundColor = Color(0xFF475569).withOpacity(0.15); // ✅ Azul oscuro/gris
  borderColor = Color(0xFF475569);
  textColor = Color(0xFF475569);
    }
  } else {
    backgroundColor = Colors.white;
    borderColor = Colors.grey[300]!;
    textColor = AppTheme.textSecondary;
  }
  
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroRol = value;
          _filtrarUsuarios();
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
    return Column(
      children: [
        // Filtros móvil
        _buildMobileFilters(),
        const SizedBox(height: 16),
        
        // Lista de cards
        Expanded(
          child: ListView.builder(
            itemCount: _usuariosFiltrados.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final usuario = _usuariosFiltrados[index];
              return UsuarioCard(
                usuario: usuario,
                onView: () => showInDevelopment('Ver detalles'),
                onEdit: () => _irAEditarUsuario(usuario),
                onDelete: () => _confirmarEliminar(usuario),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Búsqueda
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar usuarios...',
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                    onPressed: () {
                      _searchController.clear();
                      _filtrarUsuarios();
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
        const SizedBox(height: 12),
        
        // Filtros de rol
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMobileFilterChip('Todos', 'todos'),
              _buildMobileFilterChip('Admin', 'administrador'),
              _buildMobileFilterChip('Docentes', 'docente'),
              _buildMobileFilterChip('Estudiantes', 'estudiante'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilterChip(String label, String value) {
    final isSelected = _filtroRol == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroRol = value;
            _filtrarUsuarios();
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: AppTheme.accentColor.withOpacity(0.15),
        checkmarkColor: AppTheme.accentColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppTheme.accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            value: _criterioBusqueda,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            items: const [
              DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'codigo', child: Text('Código')),
            ],
            onChanged: (value) => setState(() => _criterioBusqueda = value!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        _filtrarUsuarios();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ),
      ],
    );
  }

  Widget _buildTable() {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, _usuariosFiltrados.length);
    final paginatedUsers = _usuariosFiltrados.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda dentro del card
          Padding(
            padding: const EdgeInsets.all(24), // ✅ Más espacio interno
            child: _buildSearchBar(),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                // ✨ SIN BORDES EXTERNOS GRUESOS
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1),
                  verticalInside: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(0.5),  // #
                  1: FlexColumnWidth(2),    // Nombre
                  2: FlexColumnWidth(3),    // Email
                  3: FlexColumnWidth(1.5),  // Código
                  4: FlexColumnWidth(1.5),  // Cargo
                  5: FlexColumnWidth(1),    // Avatar
                  6: FlexColumnWidth(2.5),  // Acciones (más ancho para botones con texto)
                },
                children: [
                  // Header con estilo moderno
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 2),
                      ),
                    ),
                    children: [
                      _buildHeaderCell('#'),
                      _buildHeaderCell('Nombre'),
                      _buildHeaderCell('Email'),
                      _buildHeaderCell('Código'),
                      _buildHeaderCell('Cargo'),
                      _buildHeaderCell('Avatar'),
                      _buildHeaderCell('Acciones'),
                    ],
                  ),
                  // Rows con hover effect
                 // Rows con hover effect
...paginatedUsers.asMap().entries.map((entry) {
  final globalIndex = startIndex + entry.key + 1;
  final usuario = entry.value;
  final rowIndex = entry.key;
  final rol = usuario['rol'] ?? ''; // ✨ AGREGA ESTA LÍNEA
  
  return TableRow(
    decoration: BoxDecoration(
      color: _hoveredRowIndex == rowIndex
          ? Colors.grey[50]
          : Colors.white,
    ),
    children: [
      _buildDataCell(globalIndex.toString(), rowIndex),
      _buildDataCell(usuario['nombre_completo'] ?? 'Sin nombre', rowIndex, bold: true),
      _buildDataCell(usuario['email'] ?? 'Sin email', rowIndex),
      _buildCodigoCell(_obtenerCodigo(usuario) ?? '-', rol, rowIndex), // ✨ CAMBIO
      _buildCargoCell(_obtenerRolDisplay(usuario), rol, rowIndex), // ✨ CAMBIO
      _buildAvatarCell(usuario['rol'] ?? '', usuario['nombre_completo'], rowIndex),
      _buildActionsCell(usuario, rowIndex),
    ],
  );
}).toList(),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildPagination(),
        ],
      ),
    );
  }
  

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppTheme.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, int rowIndex, {bool bold = false}) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = rowIndex),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
  // 🎨 Celda de código con badge de color según rol
Widget _buildCodigoCell(String codigo, String rol, int rowIndex) {
  return MouseRegion(
    onEnter: (_) => setState(() => _hoveredRowIndex = rowIndex),
    onExit: (_) => setState(() => _hoveredRowIndex = null),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.getRoleColor(rol).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppTheme.getRoleColor(rol).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          codigo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.getRoleColor(rol),
            letterSpacing: 0.3,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

// 🎨 Celda de cargo con color según rol
Widget _buildCargoCell(String cargo, String rol, int rowIndex) {
  return MouseRegion(
    onEnter: (_) => setState(() => _hoveredRowIndex = rowIndex),
    onExit: (_) => setState(() => _hoveredRowIndex = null),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        cargo,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.getRoleColor(rol),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

  Widget _buildAvatarCell(String rol, String? nombreCompleto, int rowIndex) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = rowIndex),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: RoleAvatar(
          rol: rol,
          nombreCompleto: nombreCompleto,
          radius: 24,
        ),
      ),
    );
  }

  Widget _buildActionsCell(dynamic usuario, int rowIndex) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = rowIndex),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ BOTÓN EDITAR - AZUL CON TEXTO
            Tooltip(
              message: 'Editar usuario',
              child: Material(
                color: Color(0xFF2563EB), // Azul profesional
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _irAEditarUsuario(usuario),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Editar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ✅ BOTÓN ELIMINAR - ROJO CON TEXTO
            Tooltip(
              message: 'Eliminar usuario',
              child: Material(
                color: Color(0xFFEF4444), // Rojo profesional
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _confirmarEliminar(usuario),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_usuariosFiltrados.length / _rowsPerPage).ceil();
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando registros del ${_currentPage * _rowsPerPage + 1} al ${min((_currentPage + 1) * _rowsPerPage, _usuariosFiltrados.length)} de un total de ${_usuariosFiltrados.length} registros',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
                child: const Text('Primero'),
              ),
              TextButton(
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                child: const Text('Anterior'),
              ),
              ...List.generate(min(totalPages, 5), (index) {
                final pageNumber = _currentPage < 3 ? index : _currentPage + index - 2;
                if (pageNumber >= totalPages) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: _currentPage == pageNumber
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _currentPage = pageNumber),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '${pageNumber + 1}',
                          style: TextStyle(
                            color: _currentPage == pageNumber
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: _currentPage == pageNumber
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              TextButton(
                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                child: Text(
                  'Siguiente',
                  style: TextStyle(color: AppTheme.accentColor),
                ),
              ),
              TextButton(
                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage = totalPages - 1) : null,
                child: Text(
                  'Último',
                  style: TextStyle(color: AppTheme.accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
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
            'Intenta con otro término de búsqueda',
            style: AppTheme.bodyMedium.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _filtroRol = 'todos');
              _filtrarUsuarios();
            },
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: const Text('Limpiar filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}