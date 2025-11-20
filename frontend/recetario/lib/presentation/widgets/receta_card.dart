import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/portafolio.dart';

/// Card para mostrar una receta en el grid del portafolio
class RecetaCard extends StatelessWidget {
  final Portafolio receta;
  final VoidCallback onTap;
  final bool mostrarAutor;

  const RecetaCard({
    Key? key,
    required this.receta,
    required this.onTap,
    this.mostrarAutor = false,
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
                tag: 'receta-${receta.id}',
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
                      receta.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Autor (si se pide mostrar)
                    if (mostrarAutor && receta.nombreEstudiante != null)
                      Text(
                        'Por ${receta.nombreEstudiante}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Stats
                    Row(
                      children: [
                        // Likes
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${receta.likes}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),

                        // Vistas
                        Icon(
                          Icons.visibility,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${receta.vistas}',
                          style: const TextStyle(fontSize: 12),
                        ),

                        const Spacer(),

                        // Badge de tipo
                        if (receta.tipoReceta == 'api')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'API',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    if (receta.fotos.isEmpty) {
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
      imageUrl: receta.fotos.first,
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