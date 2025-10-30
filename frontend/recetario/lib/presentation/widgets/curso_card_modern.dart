import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/curso.dart';

/// Card de curso para vista móvil - DISEÑO UNIFICADO CON FONDO BLANCO
class CursoCardMobile extends StatelessWidget {
  final Curso curso;
  final VoidCallback onActivar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const CursoCardMobile({
    Key? key,
    required this.curso,
    required this.onActivar,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  String _getNivelRomano() {
    const romanos = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    final nivel = curso.nivel ?? 1;
    return nivel > 0 && nivel <= 10 ? romanos[nivel - 1] : nivel.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Fondo blanco
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: curso.activo 
              ? AppTheme.successColor.withOpacity(0.2) // ✅ Borde sutil
              : Colors.grey[300]!,
          width: 1, // ✅ Más delgado
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            // Header: Icono y Badge de estado
            Row(
              children: [
                // ✅ Ícono con gradiente NARANJA (consistente)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient, // ✅ Naranja, no rojo
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_getNivelRomano()} CICLO',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            
            // Descripción
            if (curso.descripcion != null && curso.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  curso.descripcion!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            // Información detallada
            _buildInfoRow(
              Icons.calendar_month_rounded,
              curso.cicloNombre ?? 'Sin ciclo',
              AppTheme.infoColor,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.group_rounded,
                    'Sec. ${curso.seccion ?? "-"}',
                    Color(0xFF9C27B0),
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.star_rounded,
                    '${curso.creditos} créd.',
                    AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ✅ ACCIONES CON BOTONES CIRCULARES (igual a ciclos)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onActivar,
                    icon: Icon(
                      curso.activo 
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 16,
                    ),
                    label: Text(
                      curso.activo ? 'Desactivar' : 'Activar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: curso.activo 
                          ? Colors.grey[100]
                          : AppTheme.successColor,
                      foregroundColor: curso.activo
                          ? Colors.grey[700]
                          : Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // ✅ Botón CIRCULAR para editar
                _buildCircularButton(
                  icon: Icons.edit_rounded,
                  color: AppTheme.accentColor,
                  onPressed: onEditar,
                  tooltip: 'Editar',
                ),
                const SizedBox(width: 6),
                
                // ✅ Botón CIRCULAR para eliminar
                _buildCircularButton(
                  icon: Icons.delete_rounded,
                  color: Color(0xFFEF4444),
                  onPressed: onEliminar,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET PARA BOTONES CIRCULARES (mismo de usuarios/ciclos)
  Widget _buildCircularButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: curso.activo
            ? AppTheme.successColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: curso.activo
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        curso.estadoTexto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: curso.activo ? AppTheme.successColor : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Card de curso para vista desktop - DISEÑO UNIFICADO CON FONDO BLANCO
class CursoCardDesktop extends StatefulWidget {
  final Curso curso;
  final VoidCallback onActivar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const CursoCardDesktop({
    Key? key,
    required this.curso,
    required this.onActivar,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  State<CursoCardDesktop> createState() => _CursoCardDesktopState();
}

class _CursoCardDesktopState extends State<CursoCardDesktop> {
  bool _isHovered = false;

  String _getNivelRomano() {
    const romanos = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    final nivel = widget.curso.nivel ?? 1;
    return nivel > 0 && nivel <= 10 ? romanos[nivel - 1] : nivel.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white, // ✅ Fondo blanco
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.curso.activo 
                ? AppTheme.successColor.withOpacity(_isHovered ? 0.4 : 0.2)
                : Colors.grey[300]!,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con ícono y badge
              Row(
                children: [
                  // ✅ Ícono con gradiente NARANJA (consistente)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient, // ✅ Naranja, no rojo
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getNivelRomano()} CICLO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // Nombre del curso
              Text(
                widget.curso.nombre,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Descripción
              if (widget.curso.descripcion != null && widget.curso.descripcion!.isNotEmpty)
                Text(
                  widget.curso.descripcion!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const Spacer(),
              const SizedBox(height: 14),
              
              // Información compacta
              _buildInfoRow(
                Icons.calendar_month_rounded,
                'Período',
                widget.curso.cicloNombre ?? 'Sin ciclo',
                AppTheme.infoColor,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.group_rounded,
                      'Sección',
                      widget.curso.seccion ?? '-',
                      Color(0xFF9C27B0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.star_rounded,
                      'Créditos',
                      '${widget.curso.creditos}',
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // ✅ ACCIONES CON BOTONES CIRCULARES
              Row(
                children: [
                  Expanded(
                    flex: 2, // ✅ Más espacio para el botón
                    child: ElevatedButton.icon(
                      onPressed: widget.onActivar,
                      icon: Icon(
                        widget.curso.activo 
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 15,
                      ),
                      label: Text(
                        widget.curso.activo ? 'Desactivar' : 'Activar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.curso.activo 
                            ? Colors.grey[100]
                            : AppTheme.successColor,
                        foregroundColor: widget.curso.activo
                            ? Colors.grey[700]
                            : Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  
                  // ✅ Botón CIRCULAR para editar
                  _buildCircularButton(
                    icon: Icons.edit_rounded,
                    color: AppTheme.accentColor,
                    onPressed: widget.onEditar,
                    tooltip: 'Editar',
                  ),
                  const SizedBox(width: 4),
                  
                  // ✅ Botón CIRCULAR para eliminar
                  _buildCircularButton(
                    icon: Icons.delete_rounded,
                    color: Color(0xFFEF4444),
                    onPressed: widget.onEliminar,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET PARA BOTONES CIRCULARES (mismo de usuarios/ciclos)
  Widget _buildCircularButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 17),
        color: color,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.curso.activo
            ? AppTheme.successColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.curso.activo
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.curso.estadoTexto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: widget.curso.activo ? AppTheme.successColor : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}