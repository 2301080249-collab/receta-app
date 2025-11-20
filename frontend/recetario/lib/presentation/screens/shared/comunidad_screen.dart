import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../providers/portafolio_provider.dart';
import '../../../data/models/portafolio.dart';
import '../../widgets/search_bar_widget.dart';
import 'detalle_receta_screen.dart';

/// Pantalla de Comunidad - Feed social de recetas públicas
class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({Key? key}) : super(key: key);

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _cargarDatos();
      }
    });
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    final provider = context.read<PortafolioProvider>();

    await Future.wait([
      provider.cargarRecetasPublicas().catchError((e) {
        debugPrint('⚠️ Error cargando recetas públicas: $e');
      }),
      provider.cargarCategorias().catchError((e) {
        debugPrint('⚠️ Error cargando categorías: $e');
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Column(
      children: [
        // Barra de búsqueda y filtros
        Consumer<PortafolioProvider>(
          builder: (context, provider, _) {
            String? nombreCategoriaSeleccionada;
            if (provider.categoriaSeleccionada != null) {
              final catSeleccionada = provider.categorias
                  .where((c) => c.id == provider.categoriaSeleccionada)
                  .firstOrNull;
              nombreCategoriaSeleccionada = catSeleccionada?.nombre;
            }

            return SearchBarWidget(
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
              categoriaSeleccionada: nombreCategoriaSeleccionada,
              categorias: provider.categorias.map((c) => c.nombre).toList(),
              onCategoriaChanged: (nombreCategoria) {
                if (nombreCategoria == null) {
                  provider.setCategoria(null);
                } else {
                  final cat = provider.categorias
                      .where((c) => c.nombre == nombreCategoria)
                      .firstOrNull;
                  if (cat != null) {
                    provider.setCategoria(cat.id);
                  }
                }
              },
            );
          },
        ),

        // Contenido del feed
        Expanded(
          child: _buildFeedPublico(isWeb),
        ),
      ],
    );
  }

  Widget _buildFeedPublico(bool isWeb) {
    return Consumer<PortafolioProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.recetasPublicas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.recetasPublicas.isEmpty) {
          return _buildError(provider.error!);
        }

        final recetasFiltradas = _filtrarRecetas(
          provider.recetasPublicasFiltradas,
          _searchQuery,
        );

        if (recetasFiltradas.isEmpty) {
          return _buildEmptyState(
            icon: Icons.public_off,
            title: 'No hay recetas públicas aún',
            subtitle: 'Sé el primero en compartir una receta',
          );
        }

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: _buildGrid(recetasFiltradas, isWeb),
        );
      },
    );
  }

  Widget _buildGrid(List<Portafolio> recetas, bool isWeb) {
    final maxWidth = isWeb ? 1400.0 : double.infinity;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 40 : (isMobile ? 12.w : 16),
            vertical: isWeb ? 32 : (isMobile ? 12.h : 16),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWeb ? _getCrossAxisCount(context) : 2,
            childAspectRatio: isWeb ? 0.88 : 0.75,
            crossAxisSpacing: isWeb ? 24 : (isMobile ? 10.w : 16),
            mainAxisSpacing: isWeb ? 24 : (isMobile ? 10.h : 16),
          ),
          itemCount: recetas.length,
          itemBuilder: (context, index) {
            final receta = recetas[index];
            return isWeb 
                ? _buildRecetaCard(receta)
                : _buildRecetaCardMobile(receta);
          },
        ),
      ),
    );
  }

  // ✅ Card compacto para móvil (2 columnas)
  Widget _buildRecetaCardMobile(Portafolio receta) {
    return GestureDetector(
      onTap: () => _irADetalle(receta.id),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            Expanded(
              flex: 5,
              child: receta.fotos.isNotEmpty
                  ? Image.network(
                      receta.fotos.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.restaurant,
                          size: 32.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.restaurant,
                        size: 32.sp,
                        color: Colors.grey[600],
                      ),
                    ),
            ),

            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 6.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Flexible(
                      child: Text(
                        receta.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                          height: 1.2,
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Autor
                    if (receta.nombreEstudiante != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 11.sp,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              receta.nombreEstudiante!,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: 4.h),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 12.sp,
                          color: Colors.red[300],
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${receta.likes}',
                          style: TextStyle(fontSize: 10.sp),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.visibility,
                          size: 12.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${receta.vistas}',
                          style: TextStyle(fontSize: 10.sp),
                        ),
                        const Spacer(),
                        if (receta.tipoReceta == 'api')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            child: Text(
                              'API',
                              style: TextStyle(
                                fontSize: 8.sp,
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

  // ✅ Card para web (sin cambios)
  Widget _buildRecetaCard(Portafolio receta) {
    return GestureDetector(
      onTap: () => _irADetalle(receta.id),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: receta.fotos.isNotEmpty
                    ? Image.network(
                        receta.fotos.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      receta.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Autor
                    if (receta.nombreEstudiante != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              receta.nombreEstudiante!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.red[300],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${receta.likes}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${receta.vistas}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const Spacer(),
                        if (receta.tipoReceta == 'api')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'API',
                              style: TextStyle(
                                fontSize: 9,
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

  List<Portafolio> _filtrarRecetas(List<Portafolio> recetas, String query) {
    if (query.isEmpty) return recetas;

    return recetas.where((receta) {
      final titulo = receta.titulo.toLowerCase();
      final ingredientes = receta.ingredientes.toLowerCase();
      return titulo.contains(query) || ingredientes.contains(query);
    }).toList();
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 5;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 2;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarDatos,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _irADetalle(String recetaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleRecetaScreen(recetaId: recetaId),
      ),
    );
  }
}