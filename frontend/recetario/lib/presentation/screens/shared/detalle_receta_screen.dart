import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/portafolio_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/comment_section.dart';
import '../../../data/models/portafolio_item.dart';

/// Pantalla de detalle de una receta con diseño profesional web y responsivo móvil
class DetalleRecetaScreen extends StatefulWidget {
  final String recetaId;

  const DetalleRecetaScreen({
    Key? key,
    required this.recetaId,
  }) : super(key: key);

  @override
  State<DetalleRecetaScreen> createState() => _DetalleRecetaScreenState();
}

class _DetalleRecetaScreenState extends State<DetalleRecetaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _initYoutubePlayer(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return;

    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) return;

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortafolioProvider>(
      builder: (context, provider, _) {
        final item = provider.obtenerItem(widget.recetaId);

        if (item == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Receta no encontrada'),
            ),
            body: const Center(
              child: Text('Esta receta no está en tu portafolio'),
            ),
          );
        }

        // Inicializar reproductor de YouTube si hay video
        if (_youtubeController == null) {
          _initYoutubePlayer(item.receta.videoUrl);
        }

        // ✅ Detectar si es móvil
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Detalle de Receta',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: isMobile
                ? _buildMobileLayout(item, provider)
                : _buildWebLayout(item, provider),
          ),
        );
      },
    );
  }

  // ✅ DISEÑO MÓVIL - Imagen ancho completo sin padding (CORREGIDO)
  Widget _buildMobileLayout(PortafolioItem item, PortafolioProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular altura segura basada en el ancho
        final imageHeight = (constraints.maxWidth * 0.75).clamp(200.0, 400.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen a ancho completo con dimensiones seguras
            Hero(
              tag: 'receta-${item.receta.id}',
              child: Container(
                height: imageHeight,
                width: constraints.maxWidth,
                constraints: BoxConstraints(
                  maxHeight: 400,
                  maxWidth: constraints.maxWidth,
                ),
                color: Colors.grey[200],
                child: item.receta.imagenUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.receta.imagenUrl!,
                        fit: BoxFit.cover,
                        width: constraints.maxWidth,
                        height: imageHeight,
                        maxHeightDiskCache: 800,
                        maxWidthDiskCache: 800,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            // Contenido con padding
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la receta
                  Text(
                    item.receta.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.receta.categoria != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.receta.categoria!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.receta.area != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.public,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.receta.area!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Estadísticas
                  _buildEstadisticasMobile(item, provider),

                  const SizedBox(height: 20),

                  // Ingredientes
                  _buildIngredientesCard(item),

                  const SizedBox(height: 16),

                  // Preparación
                  _buildPreparacionCard(item),

                  const SizedBox(height: 16),

                  // Video
                  _buildVideoCard(item),

                  const SizedBox(height: 16),

                  // Comentarios
                  _buildComentariosSection(item, provider),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ ESTADÍSTICAS MÓVIL COMPACTAS
  Widget _buildEstadisticasMobile(
      PortafolioItem item, PortafolioProvider provider) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Like
            Expanded(
              child: InkWell(
                onTap: () => provider.toggleLike(widget.recetaId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: item.likedByUser
                        ? Colors.red.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.likedByUser
                          ? Colors.red.shade200
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        item.likedByUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: item.likedByUser ? Colors.red : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.likes}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              item.likedByUser ? Colors.red : Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Me gusta',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Comentarios
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.comentarios.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Comentarios',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
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

  // ✅ DISEÑO WEB - Original con ancho máximo centrado
  Widget _buildWebLayout(PortafolioItem item, PortafolioProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card con imagen y información básica
              _buildHeaderCard(item),

              const SizedBox(height: 24),

              // Estadísticas y acciones
              _buildEstadisticas(item, provider),

              const SizedBox(height: 32),

              // Contenido en dos columnas
              _buildContenidoDosColumnas(item),

              const SizedBox(height: 32),

              // Sección de comentarios
              _buildComentariosSection(item, provider),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ CARD PROFESIONAL CON IMAGEN Y INFO (WEB - CORREGIDO)
  Widget _buildHeaderCard(PortafolioItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con altura fija y dimensiones seguras
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 400,
                  width: constraints.maxWidth,
                  constraints: BoxConstraints(
                    maxHeight: 400,
                    maxWidth: constraints.maxWidth,
                  ),
                  color: Colors.grey[200],
                  child: Hero(
                    tag: 'receta-${item.receta.id}',
                    child: item.receta.imagenUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.receta.imagenUrl!,
                            fit: BoxFit.cover,
                            width: constraints.maxWidth,
                            height: 400,
                            maxHeightDiskCache: 1200,
                            maxWidthDiskCache: 1200,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // Información
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(
                  item.receta.nombre,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Badges de categoría y área
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (item.receta.categoria != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.receta.categoria!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.receta.area != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.public,
                              size: 18,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.receta.area!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ESTADÍSTICAS PROFESIONALES (WEB)
  Widget _buildEstadisticas(PortafolioItem item, PortafolioProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Botón de like
            Expanded(
              child: InkWell(
                onTap: () => provider.toggleLike(widget.recetaId),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: item.likedByUser
                        ? Colors.red.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.likedByUser
                          ? Colors.red.shade200
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        item.likedByUser ? Icons.favorite : Icons.favorite_border,
                        color: item.likedByUser ? Colors.red : Colors.grey[600],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.likes}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: item.likedByUser ? Colors.red : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Me gusta',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Comentarios (no clickeable)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      color: Colors.grey[600],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.comentarios.length}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comentarios',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
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

  // ✅ CONTENIDO EN DOS COLUMNAS (RESPONSIVE)
  Widget _buildContenidoDosColumnas(PortafolioItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho es mayor a 900, usar dos columnas
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda: Ingredientes
              Expanded(
                flex: 1,
                child: _buildIngredientesCard(item),
              ),
              const SizedBox(width: 24),
              // Columna derecha: Preparación y Video
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildPreparacionCard(item),
                    const SizedBox(height: 24),
                    _buildVideoCard(item),
                  ],
                ),
              ),
            ],
          );
        } else {
          // En pantallas pequeñas, apilar verticalmente
          return Column(
            children: [
              _buildIngredientesCard(item),
              const SizedBox(height: 24),
              _buildPreparacionCard(item),
              const SizedBox(height: 24),
              _buildVideoCard(item),
            ],
          );
        }
      },
    );
  }

  // ✅ CARD DE INGREDIENTES
  Widget _buildIngredientesCard(PortafolioItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_basket_outlined,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ingredientes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (item.receta.ingredientes.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No hay ingredientes disponibles',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ...item.receta.ingredientes.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${entry.key}${entry.value.isNotEmpty ? " - ${entry.value}" : ""}',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // ✅ CARD DE PREPARACIÓN
  Widget _buildPreparacionCard(PortafolioItem item) {
    final instrucciones = item.receta.instrucciones != null
        ? item.receta.instrucciones!
            .split('\n')
            .where((linea) => linea.trim().isNotEmpty)
            .toList()
        : [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Preparación',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (instrucciones.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No hay instrucciones disponibles',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ...instrucciones.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // ✅ CARD DE VIDEO
  Widget _buildVideoCard(PortafolioItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Video Tutorial',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_youtubeController == null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay video disponible',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (item.receta.videoUrl != null &&
                        item.receta.videoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _abrirEnlace(item.receta.videoUrl!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Abrir en YouTube'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.red,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.red,
                        handleColor: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirEnlace(item.receta.videoUrl!),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Ver en YouTube'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ✅ SECCIÓN DE COMENTARIOS
  Widget _buildComentariosSection(
      PortafolioItem item, PortafolioProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            // Obtener nombre según el rol del usuario
            String nombreUsuario = 'Usuario';

            if (userProvider.estudiante != null) {
              nombreUsuario =
                  'Estudiante ${userProvider.estudiante!.codigoEstudiante}';
            } else if (userProvider.docente != null) {
              nombreUsuario =
                  'Docente ${userProvider.docente!.codigoDocente}';
            } else if (userProvider.administrador != null) {
              nombreUsuario =
                  'Admin ${userProvider.administrador!.codigoAdmin}';
            }

            return CommentSection(
              comentarios: item.comentarios,
              nombreUsuario: nombreUsuario,
              onAgregarComentario: (texto) async {
                await provider.agregarComentario(
                  widget.recetaId,
                  texto,
                  nombreUsuario,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}