import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Config
import 'config/routes.dart';

// Core
import 'core/theme/app_theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/portafolio_provider.dart';  // ✅ NUEVO

// ✅ IMPORTANTE: GlobalKey para acceder al context desde providers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Asegurar inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // TODO: Inicializar Supabase si lo usas
  // await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ AuthProvider (independiente)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        // ✅ UserProvider (depende de AuthProvider)
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, authProvider, userProvider) {
            // Si el usuario cierra sesión, limpiar UserProvider
            if (!authProvider.isAuthenticated) {
              userProvider?.clear();
            }
            return userProvider ?? UserProvider();
          },
        ),

        // ✅ PortafolioProvider (independiente) - NUEVO
        ChangeNotifierProvider(
          create: (_) => PortafolioProvider(),
        ),
      ],
      child: const AppInitializer(),
    );
  }
}

// Widget para inicializar la app y restaurar sesión
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Obtener el AuthProvider
    final authProvider = context.read<AuthProvider>();

    // Intentar restaurar la sesión
    await authProvider.restoreSession();

    // Marcar como inicializado
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar splash mientras se inicializa
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o icono de tu app
                Icon(
                  Icons.restaurant_menu,
                  size: 100,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando...',
                  style: AppTheme.heading3.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Una vez inicializado, mostrar la app normal
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Determinar ruta inicial según estado de autenticación
        String initialRoute;
        
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          // Usuario autenticado: ir a su home según rol
          final role = authProvider.currentUser!.rol;
          
          switch (role) {
            case 'administrador':
              initialRoute = AppRoutes.adminDashboard;
              break;
            case 'docente':
              initialRoute = AppRoutes.docenteHome;
              break;
            case 'estudiante':
              initialRoute = AppRoutes.estudianteHome;
              break;
            default:
              initialRoute = AppRoutes.login;
          }
        } else {
          // No autenticado: ir al login
          initialRoute = AppRoutes.login;
        }

        return MaterialApp(
          // Configuración básica
          title: 'Sistema de Recetas',
          debugShowCheckedModeBanner: false,

          // ✅ CRÍTICO: NavigatorKey para acceder al context desde providers
          navigatorKey: navigatorKey,

          // Tema
          theme: AppTheme.lightTheme,
          // darkTheme: AppTheme.darkTheme, // ✅ Cuando lo agregues
          // themeMode: ThemeMode.system,

          // ✅ Localizaciones para español
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'), // Español
            Locale('en', 'US'), // Inglés (fallback)
          ],
          locale: const Locale('es', 'ES'), // Idioma por defecto

          // Rutas
          initialRoute: initialRoute,
          routes: AppRoutes.routes,

          // Manejo de rutas con argumentos
          onGenerateRoute: AppRoutes.onGenerateRoute,

          // Ruta no encontrada (404)
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                appBar: AppBar(
                  title: const Text('Error'),
                  backgroundColor: AppTheme.errorColor,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text('Página no encontrada', style: AppTheme.heading2),
                      const SizedBox(height: 8),
                      Text(
                        'Ruta: ${settings.name}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        ),
                        icon: const Icon(Icons.home),
                        label: const Text('Volver al inicio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}