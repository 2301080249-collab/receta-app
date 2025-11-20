import 'package:flutter/material.dart';

/// Barra de búsqueda moderna con dropdown de categorías
/// TODO EN UNA LÍNEA - Diseño profesional
class SearchBarWidget extends StatelessWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String? categoriaSeleccionada;
  final List<String> categorias;
  final Function(String?) onCategoriaChanged;

  const SearchBarWidget({
    Key? key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.categoriaSeleccionada,
    required this.categorias,
    required this.onCategoriaChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 16, // ✅ Cambio: 40 → 60 para alinear con filtros
        vertical: isDesktop ? 14 : 12,   // ✅ Cambio: 20 → 14 (menos altura)
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
      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  /// Layout para desktop - todo en una línea
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Campo de búsqueda (70% del espacio)
        Expanded(
          flex: 7,
          child: _buildSearchField(),
        ),

        const SizedBox(width: 20),

        // Dropdown de categorías (30% del espacio)
        Expanded(
          flex: 3,
          child: _buildCategoryDropdown(),
        ),
      ],
    );
  }

  /// Layout para móvil - apilado en 2 líneas
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildCategoryDropdown(),
      ],
    );
  }

  /// Campo de búsqueda
  Widget _buildSearchField() {
    return Container(
      height: 42, // ✅ Cambio: 50 → 42 (más pequeño)
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10), // ✅ Cambio: 12 → 10
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar recetas...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14, // ✅ Cambio: 15 → 14
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20, // ✅ Cambio: 22 → 20
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[600],
                    size: 18, // ✅ Cambio: 20 → 18
                  ),
                  onPressed: () => onSearchChanged(''),
                  padding: EdgeInsets.zero, // ✅ Nuevo: reduce padding
                  constraints: const BoxConstraints(), // ✅ Nuevo: más compacto
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, // ✅ Cambio: 16 → 14
            vertical: 10,   // ✅ Cambio: 14 → 10
          ),
        ),
        style: const TextStyle(
          fontSize: 14, // ✅ Cambio: 15 → 14
          color: Colors.black87,
        ),
      ),
    );
  }

  /// Dropdown de categorías
  Widget _buildCategoryDropdown() {
    // Agregar "Todas" al inicio si no existe
    final categoriasConTodas = ['Todas', ...categorias];
    final categoriaActual = categoriaSeleccionada ?? 'Todas';

    return Container(
      height: 42, // ✅ Cambio: 50 → 42 (igual que search field)
      padding: const EdgeInsets.symmetric(horizontal: 14), // ✅ Cambio: 16 → 14
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // ✅ Cambio: 12 → 10
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: categoriaActual,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[700],
            size: 20, // ✅ Nuevo: tamaño del icono
          ),
          style: const TextStyle(
            fontSize: 14, // ✅ Cambio: 15 → 14
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10), // ✅ Cambio: 12 → 10
          items: categoriasConTodas.map((categoria) {
            return DropdownMenuItem<String>(
              value: categoria,
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(categoria),
                    size: 16, // ✅ Cambio: 18 → 16
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8), // ✅ Cambio: 10 → 8
                  Text(categoria),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            onCategoriaChanged(value == 'Todas' ? null : value);
          },
        ),
      ),
    );
  }

  /// Obtener ícono según categoría
  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'todas':
        return Icons.restaurant_menu;
      case 'desayuno':
      case 'breakfast':
        return Icons.free_breakfast;
      case 'almuerzo':
      case 'lunch':
        return Icons.lunch_dining;
      case 'cena':
      case 'dinner':
        return Icons.dinner_dining;
      case 'postre':
      case 'dessert':
        return Icons.cake;
      case 'bebida':
      case 'drink':
        return Icons.local_drink;
      case 'vegetariano':
      case 'vegetarian':
        return Icons.eco;
      case 'vegano':
      case 'vegan':
        return Icons.spa;
      case 'pasta':
        return Icons.ramen_dining;
      case 'pollo':
      case 'chicken':
        return Icons.set_meal;
      case 'carne':
      case 'beef':
        return Icons.food_bank;
      case 'pescado':
      case 'seafood':
        return Icons.set_meal;
      default:
        return Icons.restaurant;
    }
  }
}