import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/portafolio_item.dart';

/// Card moderna para mostrar recetas en el grid del portafolio
/// Diseño estilo Pinterest/Instagram con hover effects
class RecetaCardModern extends StatefulWidget {
  final PortafolioItem item;
  final VoidCallback onTap;

  const RecetaCardModern({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  State<RecetaCardModern> createState() => _RecetaCardModernState();
}

class _RecetaCardModernState extends State<RecetaCardModern> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        child: Material(
          elevation: _isHovered ? 12 : 4,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          shadowColor: Colors.black.withOpacity(0.15),
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen con aspect ratio fijo
                  _buildImageSection(),
                  
                  // Contenido de la card
                  _buildContentSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sección de imagen con overlay en hover
  Widget _buildImageSection() {
    return AspectRatio(
      aspectRatio: 1.0, // Imagen cuadrada
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen principal con Hero animation
          Hero(
            tag: 'receta-${widget.item.receta.id}',
            child: _buildImagen(),
          ),

          // Overlay en hover
          if (_isHovered)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: Color(0xFF37474F),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ver receta',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF37474F),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Badge de categoría
          if (widget.item.receta.categoria != null)
            Positioned(
              top: 12,
              left: 12,
              child: _buildCategoryBadge(),
            ),
        ],
      ),
    );
  }

  /// Sección de contenido (título, stats, etc.)
  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            widget.item.receta.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: Color(0xFF263238),
            ),
          ),

          const SizedBox(height: 8),

          // Área geográfica si existe
          if (widget.item.receta.area != null)
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.item.receta.area!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Divider sutil
          Container(
            height: 1,
            color: Colors.grey[200],
          ),

          const SizedBox(height: 12),

          // Stats: Likes y Comentarios
          Row(
            children: [
              // Likes
              Icon(
                widget.item.likedByUser
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 18,
                color: widget.item.likedByUser ? Colors.red : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.item.likes}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(width: 20),

              // Comentarios
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.item.comentarios.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),

              const Spacer(),

              // Indicador de tiempo
              _buildTimeIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge de categoría con diseño moderno
  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 14,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            widget.item.receta.categoria!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  /// Indicador de tiempo relativo
  Widget _buildTimeIndicator() {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(widget.item.fechaAgregado);

    String timeText;
    if (diferencia.inDays > 30) {
      timeText = '${(diferencia.inDays / 30).floor()}m';
    } else if (diferencia.inDays > 0) {
      timeText = '${diferencia.inDays}d';
    } else if (diferencia.inHours > 0) {
      timeText = '${diferencia.inHours}h';
    } else {
      timeText = 'Nuevo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// Widget de imagen con manejo de errores
  Widget _buildImagen() {
    if (widget.item.receta.imagenUrl == null ||
        widget.item.receta.imagenUrl!.isEmpty) {
      return _buildPlaceholderImage();
    }

    return CachedNetworkImage(
      imageUrl: widget.item.receta.imagenUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange[700],
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholderImage(),
    );
  }

  /// Placeholder cuando no hay imagen
  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[100]!,
            Colors.orange[50]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: Colors.orange[300],
            ),
            const SizedBox(height: 8),
            Text(
              'Sin imagen',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}