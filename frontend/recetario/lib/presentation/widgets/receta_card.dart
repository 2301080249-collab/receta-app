import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/portafolio_item.dart';

/// Card para mostrar una receta en el grid del portafolio
class RecetaCard extends StatelessWidget {
  final PortafolioItem item;
  final VoidCallback onTap;

  const RecetaCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Hero(
                tag: 'receta-${item.receta.id}',
                child: _buildImagen(),
              ),
            ),

            // Información
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Título
                    Text(
                      item.receta.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Categoría
                    if (item.receta.categoria != null)
                      Text(
                        item.receta.categoria!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),

                    const Spacer(),

                    // Likes y comentarios
                    Row(
                      children: [
                        Icon(
                          item.likedByUser ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: item.likedByUser ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.likes}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.comment_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.comentarios.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagen() {
    if (item.receta.imagenUrl == null || item.receta.imagenUrl!.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.receta.imagenUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}