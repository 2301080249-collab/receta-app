import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'role_avatar.dart';

/// Card de usuario para vista móvil - Diseño profesional y moderno
class UsuarioCard extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UsuarioCard({
    Key? key,
    required this.usuario,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = usuario['nombre_completo'] ?? 'Sin nombre';
    final email = usuario['email'] ?? 'Sin email';
    final rol = usuario['rol'] ?? '';
    final codigo = _obtenerCodigo();
    final especialidad = _obtenerEspecialidad();
    final activo = usuario['activo'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                RoleAvatar(
                  rol: rol,
                  nombreCompleto: nombreCompleto,
                  radius: 28,
                ),
                const SizedBox(width: 16),
                
                // Información del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre y badge de estado
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nombreCompleto,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(activo),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Email
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Código y especialidad
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getRoleColor(rol).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              codigo,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getRoleColor(rol),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (especialidad.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                especialidad,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Menú de acciones
                _buildActionsMenu(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: activo
            ? AppTheme.successColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: activo
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: activo ? AppTheme.successColor : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

 Widget _buildActionsMenu(BuildContext context) {
  return PopupMenuButton<String>(
    icon: Icon(
      Icons.more_vert_rounded,
      color: AppTheme.textSecondary,
      size: 22,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    offset: const Offset(0, 8),
    onSelected: (value) {
      switch (value) {
        // ❌ ELIMINA ESTE CASO
        // case 'ver':
        //   onView();
        //   break;
        case 'editar':
          onEdit();
          break;
        case 'eliminar':
          onDelete();
          break;
      }
    },
    itemBuilder: (context) => [
      // ❌ ELIMINA TODO ESTE PopupMenuItem
      // PopupMenuItem(
      //   value: 'ver',
      //   child: Row(
      //     children: [
      //       Icon(
      //         Icons.remove_red_eye_rounded,
      //         size: 18,
      //         color: Color(0xFF64748B),
      //       ),
      //       const SizedBox(width: 12),
      //       Text(
      //         'Ver detalles',
      //         style: TextStyle(
      //           fontSize: 14,
      //           fontWeight: FontWeight.w500,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      PopupMenuItem(
        value: 'editar',
        child: Row(
          children: [
            Icon(
              Icons.edit_rounded,
              size: 18,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 12),
            Text(
              'Editar usuario',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'eliminar',
        child: Row(
          children: [
            Icon(
              Icons.delete_rounded,
              size: 18,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(width: 12),
            Text(
              'Eliminar usuario',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  String _obtenerCodigo() {
    if (usuario['rol'] == 'estudiante' &&
        usuario['estudiantes'] != null &&
        usuario['estudiantes'].isNotEmpty) {
      return usuario['estudiantes'][0]['codigo_estudiante'] ?? '-';
    } else if (usuario['rol'] == 'docente' &&
        usuario['docentes'] != null &&
        usuario['docentes'].isNotEmpty) {
      return usuario['docentes'][0]['codigo_docente'] ?? '-';
    } else if (usuario['rol'] == 'administrador') {
      return usuario['codigo'] ?? '-';
    }
    return usuario['codigo'] ?? '-';
  }

  String _obtenerEspecialidad() {
    final rol = usuario['rol'];
    
    if (rol == 'estudiante' &&
        usuario['estudiantes'] != null &&
        usuario['estudiantes'].isNotEmpty) {
      final especialidad = usuario['estudiantes'][0]['especialidad'] ?? '';
      return especialidad.isNotEmpty ? especialidad : 'Estudiante';
    } else if (rol == 'docente' &&
        usuario['docentes'] != null &&
        usuario['docentes'].isNotEmpty) {
      return usuario['docentes'][0]['especialidad'] ?? 'Docente';
    } else if (rol == 'administrador') {
      return 'Administrador';
    }
    
    return '';
  }
}