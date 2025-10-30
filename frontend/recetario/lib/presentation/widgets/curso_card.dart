import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/curso.dart';

/// Card reutilizable para mostrar un curso
class CursoCard extends StatelessWidget {
  final Curso curso;
  final VoidCallback? onActivar;
  final VoidCallback? onEliminar;
  final VoidCallback? onTap;

  const CursoCard({
    Key? key,
    required this.curso,
    this.onActivar,
    this.onEliminar,
    this.onTap,
  }) : super(key: key);

  // ✅ Paleta de colores más variada y vibrante (como aula virtual)
  Color _getColorByIndex(int index) {
    final colores = [
      const Color(0xFFFFA726), // Naranja
      const Color(0xFF26A69A), // Verde agua/turquesa
      const Color(0xFFEC407A), // Rosa/fucsia
      const Color(0xFF66BB6A), // Verde
      const Color(0xFF7986CB), // Azul/morado claro
      const Color(0xFFFFCA28), // Amarillo dorado
      const Color(0xFFAB47BC), // Púrpura
      const Color(0xFF42A5F5), // Azul cielo
      const Color(0xFFEF5350), // Rojo coral
      const Color(0xFF78909C), // Gris azulado
    ];
    
    return colores[index % colores.length];
  }

  // ✅ Patrones variados según el índice
  Widget _getPattern(Color color, int index) {
    final patternType = index % 4;
    
    switch (patternType) {
      case 0:
        return _SquarePattern(color: color);
      case 1:
        return _TrianglePattern(color: color);
      case 2:
        return _PlaidPattern(color: color);
      case 3:
        return _CirclePattern(color: color);
      default:
        return _CirclePattern(color: color);
    }
  }

  // ✅ Texto del nivel en romano
  String _getNivelRomano() {
    const romanos = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    final nivel = curso.nivel ?? 1;
    
    return nivel > 0 && nivel <= 10 
        ? romanos[nivel - 1] 
        : nivel.toString();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Card moderno para estudiante/docente
    if (onTap != null) {
      // Usar el ID del curso como índice para colores consistentes
      final colorIndex = curso.id?.hashCode ?? 0;
      final color = _getColorByIndex(colorIndex.abs());
      
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Patrón decorativo de fondo más visible
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _getPattern(color, colorIndex.abs()),
                ),
              ),
              
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge del nivel
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_getNivelRomano()} CICLO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Nombre del curso
                    Text(
                      curso.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Ciclo académico
                    if (curso.cicloNombre != null)
                      Text(
                        curso.cicloNombre!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Sección
                    if (curso.seccion != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Sección ${curso.seccion}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Card completo para admin (sin cambios)
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono del curso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: curso.activo
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: curso.activo ? AppTheme.primaryColor : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Información del curso
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(curso.nombre, style: AppTheme.heading3),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: curso.activo
                              ? AppTheme.successColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          curso.estadoTexto,
                          style: AppTheme.caption.copyWith(
                            color: curso.activo
                                ? AppTheme.successColor
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (curso.descripcion != null &&
                      curso.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      curso.descripcion!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    curso.infoCompleta,
                    style: AppTheme.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Botones de acción
            if (onActivar != null && onEliminar != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'activar':
                      onActivar!();
                      break;
                    case 'eliminar':
                      onEliminar!();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'activar',
                    child: Row(
                      children: [
                        Icon(
                          curso.activo ? Icons.toggle_on : Icons.toggle_off,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(curso.activo ? 'Desactivar' : 'Activar'),
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

// ================== PATRONES DECORATIVOS ==================

// Patrón de cuadrados (tipo tablero)
class _SquarePattern extends StatelessWidget {
  final Color color;
  const _SquarePattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SquarePatternPainter(color: color.withOpacity(0.08)),
    );
  }
}

class _SquarePatternPainter extends CustomPainter {
  final Color color;
  _SquarePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 35.0;
    const squareSize = 25.0;

    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      for (var y = -spacing; y < size.height + spacing; y += spacing) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Patrón de triángulos
class _TrianglePattern extends StatelessWidget {
  final Color color;
  const _TrianglePattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrianglePatternPainter(color: color.withOpacity(0.08)),
    );
  }
}

class _TrianglePatternPainter extends CustomPainter {
  final Color color;
  _TrianglePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 40.0;

    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      for (var y = -spacing; y < size.height + spacing; y += spacing) {
        final path = Path();
        path.moveTo(x, y + 20);
        path.lineTo(x + 20, y + 20);
        path.lineTo(x + 10, y);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Patrón de cuadros (tipo tartán/plaid)
class _PlaidPattern extends StatelessWidget {
  final Color color;
  const _PlaidPattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlaidPatternPainter(color: color.withOpacity(0.08)),
    );
  }
}

class _PlaidPatternPainter extends CustomPainter {
  final Color color;
  _PlaidPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 30.0;

    // Líneas verticales
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 8, size.height),
        paint,
      );
    }

    // Líneas horizontales
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Patrón de círculos
class _CirclePattern extends StatelessWidget {
  final Color color;
  const _CirclePattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CirclePatternPainter(color: color.withOpacity(0.08)),
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  final Color color;
  _CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 40.0;

    for (var x = 0.0; x < size.width + spacing; x += spacing) {
      for (var y = 0.0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 15, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}