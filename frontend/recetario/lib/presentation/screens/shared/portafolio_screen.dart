import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../providers/portafolio_provider.dart';
import '../../widgets/search_bar_widget.dart';
import '../../../data/models/portafolio.dart';
import 'detalle_receta_screen.dart';
import 'agregar_receta_screen.dart';
import 'comunidad_screen.dart';
import 'explorar_screen.dart';

/// Pantalla principal del portafolio de recetas con 3 tabs
class PortafolioScreen extends StatefulWidget {
  const PortafolioScreen({Key? key}) : super(key: key);

  @override
  State<PortafolioScreen> createState() => _PortafolioScreenState();
}

class _PortafolioScreenState extends State<PortafolioScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;
  bool _isInitialized = false;
  
  String _filtroVisibilidad = 'todas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _filtroVisibilidad = 'todas';
          _searchQuery = '';
        });
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _cargarDatos();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    final provider = context.read<PortafolioProvider>();

    await Future.wait([
      provider.cargarMisRecetas().catchError((e) {
        debugPrint('⚠️ Error cargando mis recetas: $e');
      }),
      provider.cargarCategorias().catchError((e) {
        debugPrint('⚠️ Error cargando categorías: $e');
      }),
    ]);
  }

  Future<void> _confirmarEliminar(Portafolio receta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Receta'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${receta.titulo}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await _eliminarReceta(receta);
    }
  }

  Future<void> _eliminarReceta(Portafolio receta) async {
    final provider = context.read<PortafolioProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await provider.eliminarReceta(receta.id);

    if (mounted) Navigator.pop(context);

    if (success) {
      _mostrarMensaje('Receta eliminada exitosamente', Colors.green);
    } else {
      _mostrarMensaje(
        provider.error ?? 'Error al eliminar la receta',
        Colors.red,
      );
    }
  }

  void _irAEditar(Portafolio receta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarRecetaScreen(
          recetaParaEditar: receta,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _cargarDatos();
      }
    });
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF37474F),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF9800),
              indicatorWeight: 3,
              labelColor: const Color(0xFFFF9800),
              unselectedLabelColor: const Color(0xB3FFFFFF),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              onTap: (index) => setState(() {}),
              isScrollable: false,
              tabs: [
                Tab(
                  height: 50,
                  child: Consumer<PortafolioProvider>(
                    builder: (context, provider, _) {
                      final total = _tabController.index == 0 
                          ? _obtenerRecetasFiltradas(provider).length 
                          : 0;
                      
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder, size: 18),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              'Mis Recetas',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (_tabController.index == 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$total',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                
                Tab(
                  height: 50,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 18),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Comunidad',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Tab(
                  height: 50,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public, size: 18),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Explorar',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_tabController.index == 0)
            Consumer<PortafolioProvider>(
              builder: (context, provider, _) {
                String? nombreCategoriaSeleccionada;
                if (provider.categoriaSeleccionada != null) {
                  final catSeleccionada = provider.categorias
                      .where((c) => c.id == provider.categoriaSeleccionada)
                      .firstOrNull;
                  nombreCategoriaSeleccionada = catSeleccionada?.nombre;
                }

                return Column(
                  children: [
                    SearchBarWidget(
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
                    ),
                    _buildFiltroVisibilidad(isWeb),
                  ],
                );
              },
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMisRecetas(isWeb),
                const ComunidadScreen(),
                const ExplorarScreen(),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _irAAgregarReceta,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Receta'),
              backgroundColor: const Color(0xFF37474F),
            )
          : null,
    );
  }

  Widget _buildFiltroVisibilidad(bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 60 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Visibilidad:',
            style: TextStyle(
              fontSize: isWeb ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChipFiltro(
                    label: 'Todas',
                    icon: Icons.apps,
                    value: 'todas',
                    isWeb: isWeb,
                  ),
                  const SizedBox(width: 8),
                  _buildChipFiltro(
                    label: 'Públicas',
                    icon: Icons.public,
                    value: 'publica',
                    isWeb: isWeb,
                  ),
                  const SizedBox(width: 8),
                  _buildChipFiltro(
                    label: 'Privadas',
                    icon: Icons.lock,
                    value: 'privada',
                    isWeb: isWeb,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFiltro({
    required String label,
    required IconData icon,
    required String value,
    required bool isWeb,
  }) {
    final isSelected = _filtroVisibilidad == value;
    
    Color getColor() {
      switch (value) {
        case 'todas':
          return const Color(0xFF4CAF50);
        case 'publica':
          return const Color(0xFF2196F3);
        case 'privada':
          return const Color(0xFF9E9E9E);
        default:
          return const Color(0xFFFF9800);
      }
    }
    
    final chipColor = getColor();
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isWeb ? 14 : 16,
            color: isSelected ? Colors.white : chipColor,
          ),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroVisibilidad = value;
        });
      },
      selectedColor: chipColor,
      backgroundColor: chipColor.withOpacity(0.1),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: isWeb ? 12 : 13,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 10 : 8,
        vertical: isWeb ? 6 : 4,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  List<Portafolio> _obtenerRecetasFiltradas(PortafolioProvider provider) {
    List<Portafolio> recetas = provider.misRecetasFiltradas;

    if (_filtroVisibilidad != 'todas') {
      recetas = recetas.where((r) => r.visibilidad == _filtroVisibilidad).toList();
    }

    return recetas;
  }

  Widget _buildMisRecetas(bool isWeb) {
    return Consumer<PortafolioProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.misRecetas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.misRecetas.isEmpty) {
          return _buildError(provider.error!);
        }

        final recetasFiltradas = _filtrarRecetas(
          _obtenerRecetasFiltradas(provider),
          _searchQuery,
        );

        if (recetasFiltradas.isEmpty) {
          return _buildEmptyState(
            icon: Icons.restaurant_menu,
            title: _filtroVisibilidad == 'todas'
                ? 'No hay recetas en tu portafolio'
                : _filtroVisibilidad == 'publica'
                    ? 'No tienes recetas públicas'
                    : 'No tienes recetas privadas',
            subtitle: 'Crea tu primera receta',
          );
        }

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: _buildGrid(recetasFiltradas, isWeb),
        );
      },
    );
  }

  Widget _buildGrid(
    List<Portafolio> recetas,
    bool isWeb, {
    bool esPublico = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // ✅ MÓVIL: Grid 2 columnas
    if (isMobile) {
      return GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 12.h,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
        ),
        itemCount: recetas.length,
        itemBuilder: (context, index) {
          final receta = recetas[index];
          return _buildRecetaCardMobile(receta, esPublico);
        },
      );
    }
    
    // ✅ WEB: Grid con contenedor
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                childAspectRatio: 1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: recetas.length,
              itemBuilder: (context, index) {
                final receta = recetas[index];
                return _buildRecetaCard(receta, esPublico);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Card compacto para móvil (2 columnas)
  Widget _buildRecetaCardMobile(Portafolio receta, bool mostrarAutor) {
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
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  receta.fotos.isNotEmpty
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
                  
                  if (!mostrarAutor && receta.visibilidad == 'privada')
                    Positioned(
                      top: 4.h,
                      right: 4.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.lock,
                          size: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

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

                    if (mostrarAutor && receta.nombreEstudiante != null)
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

                    // Botones editar/eliminar
                    if (!mostrarAutor) ...[
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _irAEditar(receta),
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          InkWell(
                            onTap: () => _confirmarEliminar(receta),
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.delete,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
  Widget _buildRecetaCard(Portafolio receta, bool mostrarAutor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () => _irADetalle(receta.id),
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFFFF9800).withOpacity(0.08),
          splashColor: const Color(0xFFFF9800).withOpacity(0.15),
          highlightColor: const Color(0xFFFF9800).withOpacity(0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
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
                                  size: 35,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.restaurant,
                                size: 35,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    
                    if (!mostrarAutor && receta.visibilidad == 'privada')
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock,
                                size: 11,
                                color: Colors.white,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Privada',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (!mostrarAutor)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                color: Colors.white,
                                onPressed: () => _irAEditar(receta),
                                tooltip: 'Editar',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                color: Colors.white,
                                onPressed: () => _confirmarEliminar(receta),
                                tooltip: 'Eliminar',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        receta.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),

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

                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.red[300],
                          ),
                          const SizedBox(width: 4),
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
                          const SizedBox(width: 4),
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

  void _irAAgregarReceta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarRecetaScreen(),
      ),
    ).then((_) {
      if (mounted) {
        _cargarDatos();
      }
    });
  }
}