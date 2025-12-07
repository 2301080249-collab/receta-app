import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../presentation/widgets/protected_route.dart';

// ==================== IMPORTS DE SCREENS ====================
// Auth
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/change_password_screen.dart';

// Admin
import '../presentation/screens/admin/admin_layout.dart';
import '../presentation/screens/admin/matriculas_screen.dart';
import '../presentation/screens/admin/crear_usuario_screen.dart';
import '../presentation/screens/admin/dashboard_analytics_screen.dart'; // ← NUEVO

// Layouts
import '../presentation/layouts/estudiante_main_layout.dart';
import '../presentation/layouts/docente_main_layout.dart';

// Portafolio
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
  static const String dashboardAnalytics = '/admin/dashboard-analytics'; // ← NUEVO
  static const String matriculas = '/admin/matriculas';
  static const String crearUsuario = '/admin/crear-usuario';

  // ==================== RUTAS DE ESTUDIANTE ====================
  static const String estudianteHome = '/estudiante/home';

  // ==================== RUTAS DE DOCENTE ====================
  static const String docenteHome = '/docente/home';

  // ==================== RUTAS DE PORTAFOLIO ====================
  static const String portafolio = '/portafolio';
  static const String agregarReceta = '/portafolio/agregar';

  // ==================== MAPA DE RUTAS ====================
  static Map<String, WidgetBuilder> get routes {
    return {
      // ==================== AUTH (SIN PROTECCIÓN) ====================
      login: (context) => const LoginScreen(),

      // ==================== ADMIN (PROTEGIDO - SOLO ADMINISTRADORES) ====================
      adminDashboard: (context) => ProtectedRoute(
        allowedRoles: const ['administrador'],
        child: const AdminLayout(),
      ),
      
      // ← NUEVO: RUTA DEL DASHBOARD ANALYTICS
      dashboardAnalytics: (context) => ProtectedRoute(
        allowedRoles: const ['administrador'],
        child: const DashboardAnalyticsScreen(),
      ),
      
      matriculas: (context) => ProtectedRoute(
        allowedRoles: const ['administrador'],
        child: const MatriculasScreen(),
      ),
      
      crearUsuario: (context) => ProtectedRoute(
        allowedRoles: const ['administrador'],
        child: const CrearUsuarioScreen(),
      ),

      // ==================== ESTUDIANTE (PROTEGIDO - SOLO ESTUDIANTES) ====================
      estudianteHome: (context) {
        int initialIndex = 1;
        
        if (kIsWeb) {
          try {
            final uri = Uri.base;
            final tabParam = uri.queryParameters['tab'];
            initialIndex = int.tryParse(tabParam ?? '1') ?? 1;
          } catch (e) {
            initialIndex = 1;
          }
        }

        return ProtectedRoute(
          allowedRoles: const ['estudiante'],
          child: EstudianteMainLayout(
            initialIndex: initialIndex,
          ),
        );
      },

      // ==================== DOCENTE (PROTEGIDO - SOLO DOCENTES) ====================
      docenteHome: (context) {
        int initialIndex = 1;
        
        if (kIsWeb) {
          try {
            final uri = Uri.base;
            final tabParam = uri.queryParameters['tab'];
            initialIndex = int.tryParse(tabParam ?? '1') ?? 1;
          } catch (e) {
            initialIndex = 1;
          }
        }

        return ProtectedRoute(
          allowedRoles: const ['docente'],
          child: DocenteMainLayout(
            initialIndex: initialIndex,
          ),
        );
      },

      // ==================== PORTAFOLIO (PROTEGIDO - TODOS LOS ROLES) ====================
      portafolio: (context) => ProtectedRoute(
        child: const PortafolioScreen(),
      ),
      
      agregarReceta: (context) => ProtectedRoute(
        child: const AgregarRecetaScreen(),
      ),
    };
  }

  // ==================== NAVEGACIÓN CON ARGUMENTOS ====================

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

  static Future<void> navigateToDashboard(BuildContext context, String rol) {
    final route = getRouteByRole(rol);
    return Navigator.pushReplacementNamed(context, route);
  }

  static Future<void> logout(BuildContext context) {
    return Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }

  // ==================== NAVEGACIÓN ADMIN ====================

  static Future<void> navigateToMatriculas(BuildContext context) {
    return Navigator.pushNamed(context, matriculas);
  }

  static Future<void> navigateToCrearUsuario(BuildContext context) {
    return Navigator.pushNamed(context, crearUsuario);
  }

  // ← NUEVO: MÉTODO PARA NAVEGAR AL DASHBOARD ANALYTICS
  static Future<void> navigateToDashboardAnalytics(BuildContext context) {
    return Navigator.pushNamed(context, dashboardAnalytics);
  }

  // ==================== NAVEGACIÓN PORTAFOLIO ====================

  static Future<void> navigateToPortafolio(BuildContext context) {
    return Navigator.pushNamed(context, portafolio);
  }

  static Future<void> navigateToAgregarReceta(BuildContext context) {
    return Navigator.pushNamed(context, agregarReceta);
  }

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