import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../providers/portafolio_provider.dart';
import '../../../data/models/receta_api.dart';
import 'detalle_receta_api_screen.dart';

/// Pantalla de Explorar - Búsqueda en API TheMealDB
class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({Key? key}) : super(key: key);

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final _searchController = TextEditingController();
  String? _categoriaSeleccionada;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortafolioProvider>().cargarCategoriasAPI();
    });
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {});
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      
      if (query.isEmpty) {
        context.read<PortafolioProvider>().limpiarBusqueda();
      } else if (query.length >= 2) {
        context.read<PortafolioProvider>().buscarRecetas(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        // Barra de búsqueda y categorías
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 60 : (isMobile ? 12.w : 16),
            vertical: kIsWeb ? 14 : (isMobile ? 8.h : 12),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isMobile
              // ✅ MÓVIL: Stack vertical para evitar overflow
              ? Column(
                  children: [
                    // Campo de búsqueda (arriba)
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar recetas inte...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFFFF9800),
                          size: 18.sp,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey, size: 16.sp),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<PortafolioProvider>().limpiarBusqueda();
                                  setState(() {});
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF9800),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                      ),
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    
                    SizedBox(height: 8.h),

                    // Dropdown de categorías (abajo)
                    Consumer<PortafolioProvider>(
                      builder: (context, provider, _) {
                        if (provider.categoriasAPI.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final categoriasConTodas = ['Todas', ...provider.categoriasAPI];

                        return Container(
                          height: 40.h,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _categoriaSeleccionada ?? 'Todas',
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[700],
                                size: 18.sp,
                              ),
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(10.r),
                              items: categoriasConTodas.map((categoria) {
                                return DropdownMenuItem<String>(
                                  value: categoria,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(categoria),
                                        size: 14.sp,
                                        color: Colors.orange[700],
                                      ),
                                      SizedBox(width: 6.w),
                                      Flexible(
                                        child: Text(
                                          categoria,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _categoriaSeleccionada = value == 'Todas' ? null : value;
                                });
                                
                                if (value != null && value != 'Todas') {
                                  context.read<PortafolioProvider>().buscarPorCategoria(value);
                                } else {
                                  context.read<PortafolioProvider>().limpiarBusqueda();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              // ✅ WEB/TABLET: Row horizontal (diseño original)
              : Row(
                  children: [
                    // Campo de búsqueda (70%)
                    Expanded(
                      flex: 7,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar recetas internacionales...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFFF9800),
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<PortafolioProvider>().limpiarBusqueda();
                                    setState(() {});
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF9800),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    
                    const SizedBox(width: 16),

                    // Dropdown de categorías (30%)
                    Expanded(
                      flex: 3,
                      child: Consumer<PortafolioProvider>(
                        builder: (context, provider, _) {
                          if (provider.categoriasAPI.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final categoriasConTodas = ['Todas', ...provider.categoriasAPI];

                          return Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _categoriaSeleccionada ?? 'Todas',
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                items: categoriasConTodas.map((categoria) {
                                  return DropdownMenuItem<String>(
                                    value: categoria,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(categoria),
                                          size: 16,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(categoria),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _categoriaSeleccionada = value == 'Todas' ? null : value;
                                  });
                                  
                                  if (value != null && value != 'Todas') {
                                    context.read<PortafolioProvider>().buscarPorCategoria(value);
                                  } else {
                                    context.read<PortafolioProvider>().limpiarBusqueda();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),

        // Resultados
        Expanded(
          child: Consumer<PortafolioProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF9800),
                  ),
                );
              }

              if (provider.resultadosBusqueda.isEmpty) {
                return _buildEmptyState(isWeb);
              }

              return _buildResultados(provider.resultadosBusqueda, isWeb);
            },
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'todas':
        return Icons.restaurant_menu;
      case 'res':
      case 'beef':
        return Icons.food_bank;
      case 'desayuno':
      case 'breakfast':
        return Icons.free_breakfast;
      case 'pollo':
      case 'chicken':
        return Icons.set_meal;
      case 'postre':
      case 'dessert':
        return Icons.cake;
      case 'cordero':
      case 'lamb':
        return Icons.dining;
      case 'varios':
      case 'miscellaneous':
        return Icons.restaurant;
      case 'pasta':
        return Icons.ramen_dining;
      case 'cerdo':
      case 'pork':
        return Icons.food_bank;
      case 'mariscos':
      case 'seafood':
        return Icons.set_meal;
      case 'acompañamientos':
      case 'side':
        return Icons.rice_bowl;
      case 'entradas':
      case 'starter':
        return Icons.soup_kitchen;
      case 'vegano':
      case 'vegan':
        return Icons.eco;
      case 'vegetariano':
      case 'vegetarian':
        return Icons.spa;
      case 'cabra':
      case 'goat':
        return Icons.pets;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildEmptyState(bool isWeb) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.public,
                  size: isWeb ? 80 : 64,
                  color: const Color(0xFFFF9800),
                ),
              ),
              
              SizedBox(height: isWeb ? 32 : 24),
              
              Text(
                '🌍 Explora Recetas del Mundo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF37474F),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Descubre recetas internacionales de cocinas de todo el mundo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: isWeb ? 32 : 24),
              
              Container(
                padding: EdgeInsets.all(isWeb ? 24 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cómo empezar:',
                          style: TextStyle(
                            fontSize: isWeb ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF37474F),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isWeb ? 16 : 12),
                    
                    _buildSugerencia('🔍', 'Busca por nombre de platillo', isWeb),
                    _buildSugerencia('🏷️', 'Selecciona una categoría', isWeb),
                    _buildSugerencia('🎥', 'Mira videos de preparación', isWeb),
                    _buildSugerencia('📌', 'Usa recetas como inspiración', isWeb),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSugerencia(String emoji, String texto, bool isWeb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: isWeb ? 18 : 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: isWeb ? 14 : 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados(List<RecetaApi> recetas, bool isWeb) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 1400 : double.infinity,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 60 : 20,
            vertical: isWeb ? 32 : 16,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              childAspectRatio: 0.90,
              crossAxisSpacing: isWeb ? 24 : 12,
              mainAxisSpacing: isWeb ? 24 : 12,
            ),
            itemCount: recetas.length,
            itemBuilder: (context, index) {
              final receta = recetas[index];
              return _buildRecetaAPICard(receta, isWeb);
            },
          ),
        ),
      ),
    );
  }

 Widget _buildRecetaAPICard(RecetaApi receta, bool isWeb) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  
  return GestureDetector(
    onTap: () => _mostrarDetalleAPI(receta),
    child: Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                receta.imagenUrl != null
                    ? Image.network(
                        receta.imagenUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.restaurant,
                              size: kIsWeb ? 40 : 28.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(
                            Icons.restaurant,
                            size: kIsWeb ? 40 : 28.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                
                Positioned(
                  top: kIsWeb ? 8 : 6.h,
                  right: kIsWeb ? 8 : 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 8 : 6.w,
                      vertical: kIsWeb ? 4 : 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(kIsWeb ? 6 : 5.r),
                    ),
                    child: Text(
                      'API',
                      style: TextStyle(
                        fontSize: kIsWeb ? 10 : 9.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ PARTE DE ABAJO ARREGLADA
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 12 : 8.w,
                vertical: kIsWeb ? 10 : 6.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      receta.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: kIsWeb ? 13 : 11.sp,
                        height: 1.2,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: kIsWeb ? 6 : 4.h),
                  
                  if (receta.categoria != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 6 : 5.w,
                        vertical: kIsWeb ? 3 : 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(kIsWeb ? 4 : 4.r),
                      ),
                      child: Text(
                        receta.categoria!,
                        style: TextStyle(
                          fontSize: kIsWeb ? 10 : 9.sp,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
  void _mostrarDetalleAPI(RecetaApi receta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleRecetaApiScreen(receta: receta),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 5;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 2;
  }
}