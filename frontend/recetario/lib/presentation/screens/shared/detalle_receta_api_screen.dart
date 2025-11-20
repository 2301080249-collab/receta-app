import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/receta_api.dart';
import '../../../data/services/translation_themealdb_service.dart';
import '../../widgets/analisis_nutricional_card.dart'; // 🆕 NUEVO IMPORT

/// Pantalla de detalle completo de una receta de TheMealDB (SOLO CONSULTA)
class DetalleRecetaApiScreen extends StatefulWidget {
  final RecetaApi receta;

  const DetalleRecetaApiScreen({
    Key? key,
    required this.receta,
  }) : super(key: key);

  @override
  State<DetalleRecetaApiScreen> createState() => _DetalleRecetaApiScreenState();
}

class _DetalleRecetaApiScreenState extends State<DetalleRecetaApiScreen> {
  final _service = TranslatedTheMealDBService();
  RecetaApi? _recetaCompleta;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDetalleCompleto();
  }

  Future<void> _cargarDetalleCompleto() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detalle = await _service.obtenerDetallePorId(widget.receta.id);
      
      if (detalle != null) {
        setState(() {
          _recetaCompleta = detalle;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No se pudo cargar el detalle de la receta';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirVideo() async {
    final videoUrl = _recetaCompleta?.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      _mostrarMensaje('Esta receta no tiene video disponible');
      return;
    }

    final uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarMensaje('No se pudo abrir el video');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.receta.nombre,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Referencia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContenido(isWeb),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarDetalleCompleto,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(bool isWeb) {
    if (isWeb) {
      return _buildContenidoWeb();
    } else {
      return _buildContenidoMovil();
    }
  }

  // ==================== DISEÑO WEB OPTIMIZADO ====================
  Widget _buildContenidoWeb() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección superior: Imagen + Info básica
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen (40% del ancho)
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImagenPrincipalWeb(),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Info básica + video (60% del ancho)
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTituloYBadges(),
                        const SizedBox(height: 28),
                        if (_recetaCompleta?.videoUrl != null &&
                            _recetaCompleta!.videoUrl!.isNotEmpty)
                          _buildBotonVideoWeb(),
                        const SizedBox(height: 24),
                        _buildInfoAdicional(),
                        const SizedBox(height: 16),
                        _buildMensajeInformativo(),
                      ],
                    ),
                  ),
                ],
              ),
              
              // 🆕 ANÁLISIS NUTRICIONAL CON IA (WEB)
              const SizedBox(height: 32),
              if (_recetaCompleta != null)
                AnalisisNutricionalCard(
                  recetaId: _recetaCompleta!.id,
                  nombreReceta: _recetaCompleta!.nombre,
                  categoria: _recetaCompleta!.categoria ?? 'Varios',
                  ingredientes: _recetaCompleta!.ingredientes.keys.toList(),
                ),
              
              const SizedBox(height: 40),

              // Sección inferior: Ingredientes + Preparación lado a lado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredientes (40%)
                  Expanded(
                    flex: 4,
                    child: _buildSeccionIngredientes(true),
                  ),
                  const SizedBox(width: 24),
                  // Preparación (60%)
                  Expanded(
                    flex: 6,
                    child: _buildSeccionPreparacion(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== DISEÑO MÓVIL OPTIMIZADO ====================
  Widget _buildContenidoMovil() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen principal (sin padding)
          _buildImagenPrincipal(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y badges
                _buildTituloYBadges(),
                const SizedBox(height: 20),

                // Botón de video (si existe)
                if (_recetaCompleta?.videoUrl != null &&
                    _recetaCompleta!.videoUrl!.isNotEmpty) ...[
                  _buildBotonVideo(),
                  const SizedBox(height: 20),
                ],

                // Info adicional y mensaje en móvil
                _buildInfoAdicional(),
                const SizedBox(height: 12),
                _buildMensajeInformativo(),
                
                // 🆕 ANÁLISIS NUTRICIONAL CON IA (MÓVIL)
                const SizedBox(height: 20),
                if (_recetaCompleta != null)
                  AnalisisNutricionalCard(
                    recetaId: _recetaCompleta!.id,
                    nombreReceta: _recetaCompleta!.nombre,
                    categoria: _recetaCompleta!.categoria ?? 'Varios',
                    ingredientes: _recetaCompleta!.ingredientes.keys.toList(),
                  ),
                
                const SizedBox(height: 24),

                // Ingredientes
                _buildSeccionIngredientes(false),
                const SizedBox(height: 20),

                // Pasos de preparación
                _buildSeccionPreparacion(false),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenPrincipal() {
    return _recetaCompleta?.imagenUrl != null
        ? Image.network(
            _recetaCompleta!.imagenUrl!,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          )
        : Container(
            width: double.infinity,
            height: 250,
            color: Colors.grey[300],
            child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
          );
  }

  Widget _buildImagenPrincipalWeb() {
    return _recetaCompleta?.imagenUrl != null
        ? Image.network(
            _recetaCompleta!.imagenUrl!,
            width: double.infinity,
            height: 350,
            fit: BoxFit.cover,
          )
        : Container(
            width: double.infinity,
            height: 350,
            color: Colors.grey[300],
            child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
          );
  }

  Widget _buildTituloYBadges() {
    final isWeb = MediaQuery.of(context).size.width > 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _recetaCompleta?.nombre ?? widget.receta.nombre,
          style: TextStyle(
            fontSize: isWeb ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_recetaCompleta?.categoria != null)
              _buildBadge(
                icon: Icons.category,
                label: _recetaCompleta!.categoria!,
                color: Colors.orange,
              ),
            if (_recetaCompleta?.area != null)
              _buildBadge(
                icon: Icons.public,
                label: _recetaCompleta!.area!,
                color: Colors.blue,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonVideo() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _abrirVideo,
        icon: const Icon(Icons.play_circle_outline, size: 28),
        label: const Text(
          'Ver Video Tutorial',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonVideoWeb() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ElevatedButton.icon(
          onPressed: _abrirVideo,
          icon: const Icon(Icons.play_circle_outline, size: 24),
          label: const Text(
            'Ver Video Tutorial',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionIngredientes(bool isWeb) {
    final ingredientes = _recetaCompleta?.ingredientes ?? {};

    if (ingredientes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_basket, color: Colors.orange[900], size: isWeb ? 20 : 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ingredientes',
                  style: TextStyle(
                    fontSize: isWeb ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...ingredientes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: isWeb ? 15 : 14,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: entry.value.isNotEmpty
                                  ? '${entry.value} '
                                  : '',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: entry.key),
                          ],
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

  Widget _buildSeccionPreparacion(bool isWeb) {
    final instrucciones = _recetaCompleta?.instrucciones;

    if (instrucciones == null || instrucciones.isEmpty) {
      return const SizedBox.shrink();
    }

    final pasos = instrucciones
        .split('\n')
        .where((paso) => paso.trim().isNotEmpty)
        .toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.format_list_numbered, color: Colors.blue[900], size: isWeb ? 20 : 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Preparación',
                  style: TextStyle(
                    fontSize: isWeb ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF37474F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...pasos.asMap().entries.map((entry) {
              final index = entry.key;
              final paso = entry.value.trim();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isWeb ? 26 : 24,
                      height: isWeb ? 26 : 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isWeb ? 13 : 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        paso,
                        style: TextStyle(
                          fontSize: isWeb ? 15 : 14,
                          color: Colors.black87,
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

  Widget _buildInfoAdicional() {
    return Card(
      elevation: 1,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.source, color: Colors.blue[900]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fuente: TheMealDB',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Esta receta es proporcionada por TheMealDB, una base de datos abierta de recetas de cocina.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMensajeInformativo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.orange[900], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta receta es solo de referencia. Úsala como inspiración para crear tus propias recetas originales.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}