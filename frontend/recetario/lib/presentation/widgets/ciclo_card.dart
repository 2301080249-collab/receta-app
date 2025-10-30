import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/ciclo.dart';

/// Card reutilizable para mostrar un ciclo
class CicloCard extends StatelessWidget {
  final Ciclo ciclo;
  final VoidCallback onActivar;
  final VoidCallback onEliminar;
  final VoidCallback onEditar;

  const CicloCard({
    Key? key,
    required this.ciclo,
    required this.onActivar,
    required this.onEliminar,
    required this.onEditar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Estado visual
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: ciclo.activo ? AppTheme.successColor : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),

            // Información del ciclo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(ciclo.nombre, style: AppTheme.heading3),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ciclo.activo
                              ? AppTheme.successColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ciclo.estadoTexto,
                          style: AppTheme.bodySmall.copyWith(
                            color: ciclo.activo
                                ? AppTheme.successColor
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        ciclo.rangoFechas,
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ciclo.duracionSemanas} semanas',
                    style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Botones de acción
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'activar':
                    onActivar();
                    break;
                  case 'editar':
                    onEditar();
                    break;
                  case 'eliminar':
                    onEliminar();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'activar',
                  child: Row(
                    children: [
                      Icon(
                        ciclo.activo ? Icons.toggle_on : Icons.toggle_off,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(ciclo.activo ? 'Desactivar' : 'Activar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
