import 'package:flutter/material.dart';

// ==================== IMPORTS DE SCREENS ====================
// Auth
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/change_password_screen.dart';

// Admin
import '../presentation/screens/admin/admin_layout.dart';
import '../presentation/screens/admin/matriculas_screen.dart';
import '../presentation/screens/admin/crear_usuario_screen.dart'; // ✅ AGREGADO

// Layouts - ✅ NUEVO: Imports de los layouts principales
import '../presentation/layouts/estudiante_main_layout.dart';
import '../presentation/layouts/docente_main_layout.dart';

// Portafolio - ✅ NUEVO
import '../presentation/screens/shared/portafolio_screen.dart';
import '../presentation/screens/shared/detalle_receta_screen.dart';
import '../presentation/screens/shared/agregar_receta_screen.dart';

/// Configuración centralizada de rutas de la aplicación
class AppRoutes {
  // ==================== RUTAS DE AUTENTICACIÓN ====================
  static const String login = '/login';
  static const String changePassword = '/change-password';

  // ==================== RUTAS DE ADMIN ====================
  static const String adminDashboard = '/admin/dashboard';
  static const String matriculas = '/admin/matriculas';
  static const String crearUsuario = '/admin/crear-usuario'; // ✅ AGREGADO

  // ==================== RUTAS DE ESTUDIANTE ====================
  static const String estudianteHome = '/estudiante/home';

  // ==================== RUTAS DE DOCENTE ====================
  static const String docenteHome = '/docente/home';

  // ==================== RUTAS DE PORTAFOLIO ====================
  static const String portafolio = '/portafolio';
  static const String agregarReceta = '/portafolio/agregar';
  // Nota: detalleReceta usa navegación programática con parámetros

  // ==================== MAPA DE RUTAS ====================
  static Map<String, WidgetBuilder> get routes {
    return {
      // Auth
      login: (context) => const LoginScreen(),

      // Admin - Una sola ruta para todo el módulo
      adminDashboard: (context) => const AdminLayout(),
      matriculas: (context) => const MatriculasScreen(),
      crearUsuario: (context) => const CrearUsuarioScreen(), // ✅ AGREGADO
      
      // ✅ MODIFICADO: Estudiante - Ahora usa el layout principal que mantiene estado
      estudianteHome: (context) => const EstudianteMainLayout(
        initialIndex: 1, // Inicia en la tab de Cursos (index 1)
      ),

      // ✅ MODIFICADO: Docente - Ahora usa el layout principal que mantiene estado
      docenteHome: (context) => const DocenteMainLayout(
        initialIndex: 1, // Inicia en la tab de Cursos (index 1)
      ),

      // Portafolio - ✅ NUEVO
      portafolio: (context) => const PortafolioScreen(),
      agregarReceta: (context) => const AgregarRecetaScreen(),
    };
  }

  // ==================== NAVEGACIÓN CON ARGUMENTOS ====================

  /// Configurar rutas que requieren argumentos
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case changePassword:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(
              userId: args['userId'],
              token: args['token'],
            ),
          );
        }
        return null;

      default:
        return null;
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Navegar según el rol del usuario
  static String getRouteByRole(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
      case 'admin':
        return adminDashboard;
      case 'docente':
        return docenteHome;
      case 'estudiante':
        return estudianteHome;
      default:
        return login;
    }
  }

  /// Navegar a cambio de contraseña
  static Future<void> navigateToChangePassword(
    BuildContext context, {
    required String userId,
    required String token,
  }) {
    return Navigator.pushNamed(
      context,
      changePassword,
      arguments: {'userId': userId, 'token': token},
    );
  }

  /// Navegar al dashboard según rol (después de login exitoso)
  static Future<void> navigateToDashboard(BuildContext context, String rol) {
    final route = getRouteByRole(rol);
    return Navigator.pushReplacementNamed(context, route);
  }

  /// Regresar al login (limpia el stack de navegación)
  static Future<void> logout(BuildContext context) {
    return Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }

  // ==================== NAVEGACIÓN ADMIN ====================

  /// Navegar a gestión de matrículas
  static Future<void> navigateToMatriculas(BuildContext context) {
    return Navigator.pushNamed(context, matriculas);
  }

  /// ✅ AGREGADO: Navegar a crear usuario
  static Future<void> navigateToCrearUsuario(BuildContext context) {
    return Navigator.pushNamed(context, crearUsuario);
  }

  // ==================== NAVEGACIÓN PORTAFOLIO ====================

  /// Navegar al portafolio
  static Future<void> navigateToPortafolio(BuildContext context) {
    return Navigator.pushNamed(context, portafolio);
  }

  /// Navegar a agregar receta
  static Future<void> navigateToAgregarReceta(BuildContext context) {
    return Navigator.pushNamed(context, agregarReceta);
  }

  /// Navegar a detalle de receta (con parámetro)
  static Future<void> navigateToDetalleReceta(
    BuildContext context,
    String recetaId,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleRecetaScreen(recetaId: recetaId),
      ),
    );
  }
}