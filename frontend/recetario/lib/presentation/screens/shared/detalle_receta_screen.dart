import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/portafolio_provider.dart';
import '../../../data/models/portafolio.dart';
import '../../widgets/compartir_receta_dialog.dart';

/// Pantalla de detalle de una receta profesional web y móvil
class DetalleRecetaScreen extends StatefulWidget {
  final String recetaId;

  const DetalleRecetaScreen({
    Key? key,
    required this.recetaId,
  }) : super(key: key);

  @override
  State<DetalleRecetaScreen> createState() => _DetalleRecetaScreenState();
}

class _DetalleRecetaScreenState extends State<DetalleRecetaScreen> {
  Portafolio? _receta;
  List<ComentarioPortafolio> _comentarios = [];
  bool _yaDioLike = false;
  bool _isLoading = true;
  final _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    final provider = context.read<PortafolioProvider>();

    try {
      // Cargar receta
      final receta = await provider.obtenerRecetaPorId(widget.recetaId);
      
      // Cargar comentarios
      final comentarios = await provider.obtenerComentarios(widget.recetaId);
      
      // Verificar si dio like
      final yaDioLike = await provider.yaDioLike(widget.recetaId);

      if (mounted) {
        setState(() {
          _receta = receta;
          _comentarios = comentarios;
          _yaDioLike = yaDioLike;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    final provider = context.read<PortafolioProvider>();
    final success = await provider.toggleLike(widget.recetaId);

    if (success) {
      setState(() {
        _yaDioLike = !_yaDioLike;
        if (_receta != null) {
          _receta = _receta!.copyWith(
            likes: _yaDioLike ? _receta!.likes + 1 : _receta!.likes - 1,
          );
        }
      });
    }
  }

  Future<void> _agregarComentario() async {
    if (_comentarioController.text.trim().isEmpty) return;

    final provider = context.read<PortafolioProvider>();
    final success = await provider.crearComentario(
      widget.recetaId,
      _comentarioController.text.trim(),
    );

    if (success) {
      _comentarioController.clear();
      await _cargarDatos(); // Recargar comentarios
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentario agregado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ✅ NUEVO: Mostrar diálogo de compartir
  void _mostrarDialogCompartir() {
    if (_receta == null) return;

    showDialog(
      context: context,
      builder: (context) => CompartirRecetaDialog(
        recetaId: _receta!.id,
        tituloReceta: _receta!.titulo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF37474F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de Receta',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        // ✅ NUEVO: Botón de compartir
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Compartir receta',
            onPressed: _mostrarDialogCompartir,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receta == null
              ? _buildError()
              : SingleChildScrollView(
                  child: isMobile
                      ? _buildMobileLayout()
                      : _buildWebLayout(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Receta no encontrada'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  // ==================== DISEÑO MÓVIL OPTIMIZADO ====================

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen principal
        _buildImagenPrincipal(),

        // Contenido
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitulo(fontSize: 22),
              const SizedBox(height: 12),
              _buildBadges(compact: true),
              const SizedBox(height: 16),
              if (_receta!.nombreEstudiante != null) ...[
                _buildAutor(),
                const SizedBox(height: 16),
              ],
              _buildEstadisticasMobile(),
              if (_receta!.descripcion != null && _receta!.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildDescripcion(),
              ],
              const SizedBox(height: 20),
              _buildIngredientes(),
              const SizedBox(height: 20),
              _buildPreparacion(),
              if (_receta!.videoUrl != null) ...[
                const SizedBox(height: 20),
                _buildVideo(),
              ],
              const SizedBox(height: 20),
              _buildComentarios(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== DISEÑO WEB OPTIMIZADO ====================

  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección superior: Imagen + Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen (40%)
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImagenWeb(),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Info + Estadísticas (60%)
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitulo(fontSize: 28),
                        const SizedBox(height: 16),
                        _buildBadges(compact: false),
                        if (_receta!.nombreEstudiante != null) ...[
                          const SizedBox(height: 20),
                          _buildAutor(),
                        ],
                        const SizedBox(height: 24),
                        _buildEstadisticasWeb(),
                        if (_receta!.descripcion != null && _receta!.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildDescripcionCompacta(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Contenido en dos columnas: Ingredientes + Preparación
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredientes (40%)
                  Expanded(
                    flex: 4,
                    child: _buildIngredientes(),
                  ),
                  const SizedBox(width: 24),
                  // Preparación + Video (60%)
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        _buildPreparacion(),
                        if (_receta!.videoUrl != null) ...[
                          const SizedBox(height: 20),
                          _buildVideo(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildComentarios(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== COMPONENTES ====================

  Widget _buildImagenPrincipal() {
    return Hero(
      tag: 'receta-${_receta!.id}',
      child: Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[200],
        child: _receta!.fotos.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: _receta!.fotos.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.restaurant,
                size: 64,
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildImagenWeb() {
    return Hero(
      tag: 'receta-${_receta!.id}',
      child: Container(
        height: 350,
        width: double.infinity,
        color: Colors.grey[200],
        child: _receta!.fotos.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: _receta!.fotos.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.restaurant,
                size: 64,
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildTitulo({required double fontSize}) {
    return Text(
      _receta!.titulo,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: const Color(0xFF37474F),
      ),
    );
  }

  Widget _buildBadges({required bool compact}) {
    final padding = compact ? 8.0 : 12.0;
    final fontSize = compact ? 11.0 : 13.0;
    final iconSize = compact ? 14.0 : 16.0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 6),
          decoration: BoxDecoration(
            color: _receta!.tipoReceta == 'api'
                ? Colors.blue[50]
                : Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _receta!.tipoReceta == 'api'
                  ? Colors.blue[200]!
                  : Colors.purple[200]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _receta!.tipoReceta == 'api'
                    ? Icons.public
                    : Icons.person,
                size: iconSize,
                color: _receta!.tipoReceta == 'api'
                    ? Colors.blue[700]
                    : Colors.purple[700],
              ),
              const SizedBox(width: 4),
              Text(
                _receta!.tipoReceta == 'api' ? 'De API' : 'Original',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: _receta!.tipoReceta == 'api'
                      ? Colors.blue[700]
                      : Colors.purple[700],
                ),
              ),
            ],
          ),
        ),
        if (_receta!.esCertificada)
          Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: iconSize, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'Certificada',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAutor() {
  return Row(
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: _receta!.nombreEstudiante != null
            ? Colors.primaries[_receta!.nombreEstudiante!.hashCode % Colors.primaries.length]
            : Colors.grey[300],
        backgroundImage: _receta!.avatarEstudiante != null && _receta!.avatarEstudiante!.isNotEmpty
            ? NetworkImage(_receta!.avatarEstudiante!)
            : null,
        child: _receta!.avatarEstudiante == null || _receta!.avatarEstudiante!.isEmpty
            ? Text(
                _receta!.nombreEstudiante != null && _receta!.nombreEstudiante!.isNotEmpty
                    ? _receta!.nombreEstudiante![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _receta!.nombreEstudiante!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (_receta!.codigoEstudiante != null)
            Text(
              _receta!.codigoEstudiante!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    ],
  );
}

  Widget _buildEstadisticasMobile() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _toggleLike,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _yaDioLike ? Colors.red[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _yaDioLike ? Colors.red[200]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _yaDioLike ? Icons.favorite : Icons.favorite_border,
                    color: _yaDioLike ? Colors.red : Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_receta!.likes}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _yaDioLike ? Colors.red : Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Me gusta',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.comment_outlined, color: Colors.grey[600], size: 24),
                const SizedBox(height: 6),
                Text(
                  '${_comentarios.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Comentarios',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.visibility_outlined, color: Colors.grey[600], size: 24),
                const SizedBox(height: 6),
                Text(
                  '${_receta!.vistas}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Vistas',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasWeb() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _toggleLike,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _yaDioLike ? Colors.red[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _yaDioLike ? Colors.red[200]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _yaDioLike ? Icons.favorite : Icons.favorite_border,
                    color: _yaDioLike ? Colors.red : Colors.grey[600],
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_receta!.likes}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _yaDioLike ? Colors.red : Colors.grey[800],
                    ),
                  ),
                  Text('Me gusta', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.comment_outlined, color: Colors.grey[600], size: 28),
                const SizedBox(height: 8),
                Text(
                  '${_comentarios.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text('Comentarios', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.visibility_outlined, color: Colors.grey[600], size: 28),
                const SizedBox(height: 8),
                Text(
                  '${_receta!.vistas}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text('Vistas', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescripcion() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description_outlined, color: Colors.grey[700], size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Descripción',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _receta!.descripcion!,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcionCompacta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        _receta!.descripcion!,
        style: const TextStyle(fontSize: 14, height: 1.5),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildIngredientes() {
    final ingredientes = _receta!.ingredientes.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final isWeb = MediaQuery.of(context).size.width >= 600;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 18 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_basket_outlined, color: Colors.orange[700], size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ingredientes',
                  style: TextStyle(fontSize: isWeb ? 18 : 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...ingredientes.map((ingrediente) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(ingrediente.trim(), style: const TextStyle(fontSize: 14, height: 1.4)),
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

  Widget _buildPreparacion() {
    final pasos = _receta!.preparacion.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final isWeb = MediaQuery.of(context).size.width >= 600;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 18 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restaurant_menu, color: Colors.blue[700], size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Preparación',
                  style: TextStyle(fontSize: isWeb ? 18 : 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...pasos.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.orange,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(entry.value.trim(), style: const TextStyle(fontSize: 14, height: 1.5)),
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

  Widget _buildVideo() {
    final isWeb = MediaQuery.of(context).size.width >= 600;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 18 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.play_circle_outline, color: Colors.red[700], size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Video Tutorial',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirEnlace(_receta!.videoUrl!),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ver en YouTube'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComentarios() {
    final isWeb = MediaQuery.of(context).size.width >= 600;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.comment_outlined, color: Colors.purple[700], size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Comentarios (${_comentarios.length})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Formulario
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentarioController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: _agregarComentario,
                    icon: const Icon(Icons.send, color: Colors.white),
                    iconSize: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de comentarios
            if (_comentarios.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No hay comentarios aún. ¡Sé el primero!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              )
            else
              ..._comentarios.map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     CircleAvatar(
  radius: 16,
  backgroundColor: c.nombreUsuario != null
      ? Colors.primaries[c.nombreUsuario!.hashCode % Colors.primaries.length]
      : Colors.grey[300],
  backgroundImage: c.avatarUsuario != null && c.avatarUsuario!.isNotEmpty
      ? NetworkImage(c.avatarUsuario!)
      : null,
  child: c.avatarUsuario == null || c.avatarUsuario!.isEmpty
      ? Text(
          c.nombreUsuario != null && c.nombreUsuario!.isNotEmpty
              ? c.nombreUsuario![0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        )
      : null,
),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.nombreUsuario ?? 'Usuario',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(c.comentario, style: const TextStyle(fontSize: 13, height: 1.4)),
                          ],
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

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}