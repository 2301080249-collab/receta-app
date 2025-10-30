import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/portafolio_provider.dart';
import '../../../data/models/receta_api.dart';

/// Pantalla profesional para buscar y agregar recetas desde TheMealDB
class AgregarRecetaScreen extends StatefulWidget {
  const AgregarRecetaScreen({Key? key}) : super(key: key);

  @override
  State<AgregarRecetaScreen> createState() => _AgregarRecetaScreenState();
}

class _AgregarRecetaScreenState extends State<AgregarRecetaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  RecetaApi? _recetaSeleccionada;
  bool _mostrarVistaPrevia = false;
  bool _mostrarCategorias = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final provider = context.read<PortafolioProvider>();
    await provider.cargarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarVistaPrevia && _recetaSeleccionada != null) {
      return _buildVistaPrevia();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Agregar Receta',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header con búsqueda moderna
          _buildSearchHeader(),

          // Resultados en GRID (web) o LISTA HORIZONTAL (móvil)
          Expanded(
            child: Consumer<PortafolioProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.resultadosBusqueda.isEmpty) {
                  return _buildEstadoInicial();
                }

                return _buildResultados(provider.resultadosBusqueda);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Buscar en TheMealDB',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Campo de búsqueda moderno
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<PortafolioProvider>().limpiarBusqueda();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        context.read<PortafolioProvider>().buscarRecetas(query);
                      };
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Botón de categorías
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _mostrarCategorias = !_mostrarCategorias;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _mostrarCategorias
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mostrarCategorias
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 18,
                            color: _mostrarCategorias
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _mostrarCategorias
                                ? 'Ocultar categorías'
                                : 'Buscar por categoría',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _mostrarCategorias
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _mostrarCategorias
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                            color: _mostrarCategorias
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Categorías desplegables
          if (_mostrarCategorias) _buildCategorias(),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
    return Consumer<PortafolioProvider>(
      builder: (context, provider, _) {
        if (provider.categorias.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.categorias.map((categoria) {
              return Material(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    provider.buscarPorCategoria(categoria);
                    setState(() {
                      _mostrarCategorias = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _traducirCategoria(categoria),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEstadoInicial() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Busca recetas deliciosas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe el nombre de una receta\no selecciona una categoría',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ GRID (web/tablet) o LISTA HORIZONTAL (móvil)
  Widget _buildResultados(List<RecetaApi> recetas) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // ✅ MÓVIL: Lista horizontal deslizable
              if (constraints.maxWidth < 500) {
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: recetas.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final receta = recetas[index];
                    return _buildRecetaCardHorizontal(receta);
                  },
                );
              }

              // ✅ WEB/TABLET: Grid responsive
              int crossAxisCount = 4;
              double spacing = 16;
              
              if (constraints.maxWidth < 900) {
                crossAxisCount = 3;
                spacing = 14;
              }
              if (constraints.maxWidth < 700) {
                crossAxisCount = 2;
                spacing = 12;
              }

              return GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: recetas.length,
                itemBuilder: (context, index) {
                  final receta = recetas[index];
                  return _buildRecetaCard(receta);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ✅ CARD HORIZONTAL para MÓVIL (como la imagen 2)
  Widget _buildRecetaCardHorizontal(RecetaApi receta) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _seleccionarReceta(receta),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen cuadrada
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: receta.imagenUrl != null
                      ? CachedNetworkImage(
                          imageUrl: receta.imagenUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Información a la derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nombre
                    Text(
                      receta.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Categoría con badge
                    if (receta.categoria != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _traducirCategoria(receta.categoria!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ CARD VERTICAL para WEB/TABLET (original)
  Widget _buildRecetaCard(RecetaApi receta) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _seleccionarReceta(receta),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 65,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    receta.imagenUrl != null
                        ? CachedNetworkImage(
                            imageUrl: receta.imagenUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          ),
                    
                    // Badge de categoría
                    if (receta.categoria != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            _traducirCategoria(receta.categoria!),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Información
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre
                    Text(
                      receta.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Área geográfica
                    if (receta.area != null)
                      Row(
                        children: [
                          Icon(
                            Icons.public,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              receta.area!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  Future<void> _seleccionarReceta(RecetaApi receta) async {
    // Obtener detalles completos si no los tiene
    if (receta.ingredientes.isEmpty) {
      final provider = context.read<PortafolioProvider>();
      final recetaCompleta = await provider.obtenerDetalleReceta(receta.id);
      
      if (recetaCompleta != null) {
        receta = recetaCompleta;
      }
    }

    setState(() {
      _recetaSeleccionada = receta;
      _mostrarVistaPrevia = true;
    });
  }

  Widget _buildVistaPrevia() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              _mostrarVistaPrevia = false;
              _recetaSeleccionada = null;
              _comentarioController.clear();
            });
          },
        ),
        title: const Text(
          'Vista Previa',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen con altura fija
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: SizedBox(
                        height: 350,
                        width: double.infinity,
                        child: _recetaSeleccionada!.imagenUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _recetaSeleccionada!.imagenUrl!,
                                fit: BoxFit.cover,
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
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),

                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre de la receta
                          Text(
                            _recetaSeleccionada!.nombre,
                            style: const TextStyle(
                              fontSize: 28,
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
                              if (_recetaSeleccionada!.categoria != null)
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
                                        size: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _traducirCategoria(
                                            _recetaSeleccionada!.categoria!),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_recetaSeleccionada!.area != null)
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
                                        size: 16,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _recetaSeleccionada!.area!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Sección de comentario
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 20,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Agrega un comentario (opcional)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _comentarioController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Cuéntanos tu experiencia con esta receta...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  maxLines: 3,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Botones de acción
                          Row(
                            children: [
                              // Botón cancelar
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarVistaPrevia = false;
                                      _recetaSeleccionada = null;
                                      _comentarioController.clear();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Botón publicar
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _agregarAlPortafolio,
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_circle_outline, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Publicar en Portafolio',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _agregarAlPortafolio() async {
    if (_recetaSeleccionada == null) return;

    final provider = context.read<PortafolioProvider>();
    final comentario = _comentarioController.text.trim();

    final success = await provider.agregarReceta(
      _recetaSeleccionada!,
      comentarioUsuario: comentario.isNotEmpty ? comentario : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Receta agregada al portafolio'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(provider.error ?? 'Error al agregar receta'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _traducirCategoria(String categoria) {
    const traducciones = {
      'Beef': 'Res',
      'Chicken': 'Pollo',
      'Dessert': 'Postres',
      'Lamb': 'Cordero',
      'Miscellaneous': 'Varios',
      'Pasta': 'Pasta',
      'Pork': 'Cerdo',
      'Seafood': 'Mariscos',
      'Side': 'Acompañamientos',
      'Starter': 'Entradas',
      'Vegan': 'Vegano',
      'Vegetarian': 'Vegetariano',
      'Breakfast': 'Desayuno',
      'Goat': 'Cabra',
    };

    return traducciones[categoria] ?? categoria;
  }
}