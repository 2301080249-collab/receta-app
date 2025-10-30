import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ciclo.dart';

/// Card de ciclo para vista móvil - DISEÑO UNIFICADO
class CicloCardMobile extends StatelessWidget {
  final Ciclo ciclo;
  final VoidCallback onActivar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const CicloCardMobile({
    Key? key,
    required this.ciclo,
    required this.onActivar,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ciclo.activo 
              ? AppTheme.successColor.withOpacity(0.2)
              : Colors.grey[300]!,
          width: 1,
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
            // Header: Nombre y badge
            Row(
              children: [
                // ✅ Ícono circular con gradiente (consistente)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ciclo.activo
                        ? LinearGradient(
                            colors: [
                              AppTheme.successColor,
                              AppTheme.successColor.withOpacity(0.7),
                            ],
                          )
                        : LinearGradient(
                            colors: [Colors.grey[400]!, Colors.grey[500]!],
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ciclo.nombre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Fechas
            _buildInfoRow(
              Icons.calendar_month_rounded,
              ciclo.rangoFechas,
              AppTheme.accentColor,
            ),
            const SizedBox(height: 10),
            
            // Duración
            _buildInfoRow(
              Icons.schedule_rounded,
              '${ciclo.duracionSemanas} semanas',
              AppTheme.infoColor,
            ),
            const SizedBox(height: 16),
            
            // ✅ ACCIONES CON BOTONES CIRCULARES (igual a usuarios)
            Row(
              children: [
                // Botón activar/desactivar prominente
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onActivar,
                    icon: Icon(
                      ciclo.activo 
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      ciclo.activo ? 'Desactivar' : 'Activar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ciclo.activo 
                          ? Colors.grey[100]
                          : AppTheme.successColor,
                      foregroundColor: ciclo.activo
                          ? Colors.grey[700]
                          : Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // ✅ Botón CIRCULAR para editar (igual a usuarios)
                _buildCircularButton(
                  icon: Icons.edit_rounded,
                  color: AppTheme.accentColor,
                  onPressed: onEditar,
                  tooltip: 'Editar',
                ),
                const SizedBox(width: 6),
                
                // ✅ Botón CIRCULAR para eliminar (igual a usuarios)
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

  // ✅ WIDGET PARA BOTONES CIRCULARES (mismo de usuarios)
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
        color: ciclo.activo
            ? AppTheme.successColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ciclo.activo
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        ciclo.estadoTexto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ciclo.activo ? AppTheme.successColor : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card de ciclo para vista desktop - DISEÑO UNIFICADO
class CicloCardDesktop extends StatefulWidget {
  final Ciclo ciclo;
  final VoidCallback onActivar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const CicloCardDesktop({
    Key? key,
    required this.ciclo,
    required this.onActivar,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  State<CicloCardDesktop> createState() => _CicloCardDesktopState();
}

class _CicloCardDesktopState extends State<CicloCardDesktop> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.ciclo.activo 
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  // ✅ Ícono con gradiente (consistente)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: widget.ciclo.activo
                          ? LinearGradient(
                              colors: [
                                AppTheme.successColor,
                                AppTheme.successColor.withOpacity(0.7),
                              ],
                            )
                          : LinearGradient(
                              colors: [Colors.grey[400]!, Colors.grey[500]!],
                            ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.ciclo.activo 
                              ? AppTheme.successColor
                              : Colors.grey[400]!).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.event_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ciclo.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Información
              _buildInfoRow(
                Icons.calendar_month_rounded,
                'Período',
                widget.ciclo.rangoFechas,
                AppTheme.accentColor,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.schedule_rounded,
                'Duración',
                '${widget.ciclo.duracionSemanas} semanas',
                AppTheme.infoColor,
              ),
              
              const Spacer(),
              const SizedBox(height: 16),
              
              // ✅ ACCIONES CON BOTONES CIRCULARES (igual a usuarios)
              Row(
  children: [
    Expanded(
      flex: 2,  // ✅ AGREGA ESTO
      child: ElevatedButton.icon(
        onPressed: widget.onActivar,
        icon: Icon(
          widget.ciclo.activo 
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_outline_rounded,
          size: 16,
        ),
        label: Text(
          widget.ciclo.activo ? 'Desactivar' : 'Activar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
  backgroundColor: widget.ciclo.activo 
      ? Colors.grey[100]
      : AppTheme.successColor,
  foregroundColor: widget.ciclo.activo
      ? Colors.grey[700]
      : Colors.white,
  elevation: 0,
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),  // ✅ AGREGA horizontal
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // ✅ Botón CIRCULAR para editar (igual a usuarios)
                  _buildCircularButton(
                    icon: Icons.edit_rounded,
                    color: AppTheme.accentColor,
                    onPressed: widget.onEditar,
                    tooltip: 'Editar',
                  ),
                  const SizedBox(width: 6),
                  
                  // ✅ Botón CIRCULAR para eliminar (igual a usuarios)
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

  // ✅ WIDGET PARA BOTONES CIRCULARES (mismo de usuarios)
  Widget _buildCircularButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.ciclo.activo
            ? AppTheme.successColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.ciclo.activo
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.ciclo.estadoTexto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: widget.ciclo.activo ? AppTheme.successColor : Colors.grey[600],
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
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}