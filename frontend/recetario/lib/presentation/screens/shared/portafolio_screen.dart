import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/portafolio_provider.dart';
import '../../widgets/receta_card.dart';
import '../../widgets/search_bar_widget.dart';
// ❌ REMOVIDO: import '../../widgets/custom_app_header.dart'; 
import '../../../data/models/portafolio_item.dart';
import 'detalle_receta_screen.dart';
import 'agregar_receta_screen.dart';

/// Pantalla principal del portafolio de recetas
class PortafolioScreen extends StatefulWidget {
  const PortafolioScreen({Key? key}) : super(key: key);

  @override
  State<PortafolioScreen> createState() => _PortafolioScreenState();
}

class _PortafolioScreenState extends State<PortafolioScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final provider = context.read<PortafolioProvider>();
    await provider.cargarPortafolio();
    await provider.cargarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ❌ REMOVIDO: Este era el header duplicado
          // const CustomAppHeader(selectedMenu: 'portafolio'),

          // ✅ Barra de título con estadísticas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Portafolio de Recetas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Estadísticas
                Consumer<PortafolioProvider>(
                  builder: (context, provider, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${provider.portafolio.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Barra de búsqueda y filtros
          Consumer<PortafolioProvider>(
            builder: (context, provider, _) {
              return SearchBarWidget(
                searchQuery: _searchQuery,
                onSearchChanged: (query) {
                  setState(() {
                    _searchQuery = query.toLowerCase();
                  });
                },
                categoriaSeleccionada: provider.categoriaSeleccionada,
                categorias: provider.categorias,
                onCategoriaChanged: (categoria) {
                  provider.setCategoria(categoria);
                },
              );
            },
          ),

          // Grid de recetas
          Expanded(
            child: Consumer<PortafolioProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarDatos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final recetasFiltradas = _filtrarRecetas(
                  provider.portafolioFiltrado,
                  _searchQuery,
                );

                if (recetasFiltradas.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: recetasFiltradas.length,
                    itemBuilder: (context, index) {
                      final item = recetasFiltradas[index];
                      return RecetaCard(
                        item: item,
                        onTap: () => _irADetalle(item.receta.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Botón flotante para agregar recetas
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irAAgregarReceta,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Receta'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Filtrar recetas por búsqueda
  List<PortafolioItem> _filtrarRecetas(List<PortafolioItem> recetas, String query) {
    if (query.isEmpty) return recetas;

    return recetas.where((item) {
      final nombre = item.receta.nombre.toLowerCase();
      final categoria = item.receta.categoria?.toLowerCase() ?? '';
      final area = item.receta.area?.toLowerCase() ?? '';

      return nombre.contains(query) ||
          categoria.contains(query) ||
          area.contains(query);
    }).toList();
  }

  /// Calcular número de columnas según ancho de pantalla
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }

  /// Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay recetas en tu portafolio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tus primeras recetas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _irAAgregarReceta,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Receta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navegar a detalle de receta
  void _irADetalle(String recetaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleRecetaScreen(recetaId: recetaId),
      ),
    );
  }

  /// Navegar a agregar receta
  void _irAAgregarReceta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarRecetaScreen(),
      ),
    );
  }
}