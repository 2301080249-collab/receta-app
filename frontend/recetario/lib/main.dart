import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Config
import 'config/routes.dart';

// Core
import 'core/theme/app_theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/portafolio_provider.dart';

// Services
import 'data/services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handler para notificaciones en segundo plano (DEBE estar ANTES de main)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    print('📬 Notificación en segundo plano: ${message.messageId}');
    print('📋 Título: ${message.notification?.title}');
    print('📋 Cuerpo: ${message.notification?.body}');
    print('📦 Data: ${message.data}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // ✅ Firebase SOLO en móvil (Android/iOS)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase inicializado para móvil');
      
      // 🔥 Registrar background handler ANTES de todo lo demás
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print('✅ Background handler registrado');
      
      // 🔥 Inicializar FCM inmediatamente (para pedir permisos y obtener token)
      await FCMService().initialize();
      print('✅ FCM inicializado (token se enviará después del login)');
    } catch (e) {
      print('❌ Error inicializando Firebase/FCM: $e');
    }
  } else {
    print('🌐 Web detectado - Firebase deshabilitado');
  }

  // Inicializar Supabase (funciona en todas las plataformas)
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
    );
    print('✅ Supabase inicializado correctamente');
  } catch (e) {
    print('❌ ERROR inicializando Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, authProvider, userProvider) {
            if (!authProvider.isAuthenticated) {
              userProvider?.clear();
            }
            return userProvider ?? UserProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => PortafolioProvider()),
      ],
      child: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  RemoteMessage? _pendingMessage; // 👈 Para guardar mensaje de notificación

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
  try {
    final authProvider = context.read<AuthProvider>();
    
    // 1. Restaurar sesión primero
    await authProvider.restoreSession().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ Timeout restaurando sesión, continuando sin sesión...');
      },
    );

    // 2. Si hay sesión, manejar mensaje inicial de notificación (solo móvil)
    if (!kIsWeb && authProvider.isAuthenticated) {
      // Llamar al nuevo método que maneja la navegación con delay
      FCMService().handleInitialMessage();
    }
  } catch (e) {
    print('❌ Error restaurando sesión: $e');
  } finally {
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }
}

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.restaurant_menu, size: 100, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text('Cargando...', style: AppTheme.heading3.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        String initialRoute;

        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          final role = authProvider.currentUser!.rol;

          // 🔥 Manejar navegación pendiente desde notificación
          if (_pendingMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final recetaId = _pendingMessage!.data['receta_id']?.toString();
              if (recetaId != null && mounted) {
                print('🧭 Navegando a receta pendiente: $recetaId');
                AppRoutes.navigateToDetalleReceta(context, recetaId);
                _pendingMessage = null; // Limpiar después de navegar
              }
            });
          }

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
          initialRoute = AppRoutes.login;
        }

        // ✅ SIEMPRE usar ScreenUtilInit (funciona en web y móvil)
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              title: 'Sistema de Recetas',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: AppTheme.lightTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('es', 'ES'),
                Locale('en', 'US'),
              ],
              locale: const Locale('es', 'ES'),
              initialRoute: initialRoute,
              routes: AppRoutes.routes,
              onGenerateRoute: AppRoutes.onGenerateRoute,
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
                          Icon(Icons.error_outline, size: 80, color: AppTheme.errorColor),
                          const SizedBox(height: 16),
                          Text('Página no encontrada', style: AppTheme.heading2),
                          const SizedBox(height: 8),
                          Text(
                            'Ruta: ${settings.name}',
                            style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                            icon: const Icon(Icons.home),
                            label: const Text('Volver al inicio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      },
    );
  }
}