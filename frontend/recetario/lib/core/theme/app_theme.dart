import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 PALETA "CHEF ELEGANTE" - Gastronomía Profesional
  
  // Colores principales - Gris carbón elegante
  static const Color primaryColor = Color(0xFF2C3E50); // Gris carbón oscuro
  static const Color secondaryColor = Color(0xFF34495E); // Gris carbón medio
  static const Color accentColor = Color(0xFFE67E22); // Naranja cálido gastronómico
  static const Color accentGold = Color(0xFFF39C12); // Dorado excelencia

  // Colores por rol - Actualizados con la nueva paleta
  static const Color estudianteColor = Color(0xFF3498DB); // Azul moderno
  static const Color docenteColor = Color(0xFF27AE60); // Verde profesional
  static const Color adminColor = Color(0xFFE67E22); // Naranja gastronómico
  static const Color formColor = Color(0xFF475569); // 🎨 Color para formularios

  // Colores de estado
  static const Color successColor = Color(0xFF27AE60); // Verde éxito
  static const Color warningColor = Color(0xFFF39C12); // Dorado advertencia
  static const Color errorColor = Color(0xFFE74C3C); // Rojo elegante
  static const Color infoColor = Color(0xFF3498DB); // Azul información

  // Colores de fondo
  static const Color backgroundColor = Color(0xFFF8F9FA); // Gris muy claro
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color hoverColor = Color(0xFF34495E); // Para hover en sidebar

  // Colores de texto
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFFECF0F1);

  // Theme principal
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),

      // AppBar - Elegante y profesional
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textLight),
      ),

      // Cards - Más elegantes
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button - Con acento gastronómico
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 2,
          shadowColor: accentColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: accentColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration - Más refinado
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: formColor, width: 2), // 🎨 CAMBIO AQUÍ
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100]!,
        deleteIconColor: textSecondary,
        labelStyle: TextStyle(color: textPrimary),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 1,
      ),
    );
  }

  // 📝 Estilos de texto mejorados
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
    letterSpacing: 0.3,
  );

  // 🎯 Estilos especiales para badges
  static TextStyle badgeStyle(Color color) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.5,
    );
  }

  // 🌟 Sombras elegantes
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];

  // 🎨 Gradientes para elementos especiales
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => LinearGradient(
        colors: [accentColor, accentGold],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // 🎨 Gradiente para formularios - Color del sidebar/header
  static LinearGradient get formGradient => LinearGradient(
        colors: [
          formColor.withOpacity(0.08),
          formColor.withOpacity(0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ); // ✨ NUEVO GRADIENTE

  // 🏆 Colores para niveles de logro (útil para recetas)
  static const Color levelBronze = Color(0xFFCD7F32);
  static const Color levelSilver = Color(0xFFC0C0C0);
  static const Color levelGold = Color(0xFFFFD700);
  static const Color levelPlatinum = Color(0xFFE5E4E2);

  // ⭐ Método helper para obtener color por rol
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'estudiante':
        return estudianteColor;
      case 'docente':
        return docenteColor;
      case 'administrador':
        return adminColor;
      default:
        return primaryColor;
    }
  }

  // 📊 Método helper para obtener color por estado
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
      case 'aprobado':
      case 'entregado':
        return successColor;
      case 'pendiente':
      case 'en_progreso':
        return warningColor;
      case 'rechazado':
      case 'reprobado':
      case 'atrasado':
        return errorColor;
      default:
        return infoColor;
    }
  }
  // 🆕 COLORES ADICIONALES PARA PANTALLAS DE DOCENTE
static const Color tabBarBackground = Color(0xFF475569); // Fondo de tabs
static const Color tabIndicator = Color(0xFF3B82F6); // Indicador de tab activo
static const Color tabUnselected = Color(0xFFCBD5E1); // Tabs inactivos

// 🎨 Gradientes para Cards de Cursos
static const List<Color> gradientPurple = [
  Color(0xFF667eea),
  Color(0xFF764ba2),
];

static const List<Color> gradientPink = [
  Color(0xFFf093fb),
  Color(0xFFf5576c),
];

// ✅ MÁS SUAVE Y PROFESIONAL
static const List<Color> gradientBlue = [
  Color(0xFF667eea), // Azul-púrpura suave
  Color(0xFF4facfe), // Azul medio
];

// Helper para obtener gradiente variado
static LinearGradient getCourseGradient(int index) {
  final gradients = [gradientPurple, gradientPink, gradientBlue];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: gradients[index % gradients.length],
  );
}
}