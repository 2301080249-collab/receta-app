import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../main.dart';
import '../../config/routes.dart';
import '../../core/utils/token_manager.dart';

/// Servicio para manejar Firebase Cloud Messaging (Push Notifications)
/// Web: usa polling del backend
/// Móvil: usa FCM push real
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging? _messaging = kIsWeb ? null : FirebaseMessaging.instance;
  
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  bool _isInitialized = false;

  /// Inicializar FCM (solo móvil, no web) - SIN enviar token
  Future<void> initialize() async {
    if (kIsWeb) {
      print('🌐 Web detectado - FCM deshabilitado (usar polling API)');
      return;
    }

    // 🔒 Evitar inicializar múltiples veces
    if (_isInitialized) {
      print('ℹ️ FCM ya está inicializado');
      return;
    }

    try {
      print('🚀 Inicializando FCM...');

      // 1. Solicitar permisos
      await _requestPermissions();

      // 2. Configurar notificaciones locales
      await _setupLocalNotifications();

      // 3. Obtener token FCM (PERO NO ENVIARLO AÚN)
      await _getTokenSinEnviar();

      // 4. Configurar listeners
      _setupMessageHandlers();

      _isInitialized = true;
      print('✅ FCM inicializado correctamente (token NO enviado aún)');
    } catch (e) {
      print('❌ Error inicializando FCM: $e');
    }
  }

  /// Solicitar permisos de notificaciones (SOLO MÓVIL)
  Future<void> _requestPermissions() async {
    if (kIsWeb || _messaging == null) return;

    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 Permisos de notificaciones: ${settings.authorizationStatus}');
  }

  /// Configurar notificaciones locales (Android/iOS)
  Future<void> _setupLocalNotifications() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Canal de Android para recetas compartidas
    const channel = AndroidNotificationChannel(
      'recetas_compartidas',
      'Recetas Compartidas',
      description: 'Notificaciones cuando alguien comparte una receta contigo',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Obtener token FCM SIN enviarlo al backend
  Future<void> _getTokenSinEnviar() async {
    if (kIsWeb || _messaging == null) return;

    try {
      _fcmToken = await _messaging!.getToken();
      print('🔑 FCM Token obtenido: $_fcmToken');
      print('⏳ Token guardado localmente, esperando autenticación para enviarlo...');

      // Escuchar cambios de token
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 Token actualizado: $newToken');
        _enviarTokenAlBackend(newToken);
      });
    } catch (e) {
      print('❌ Error al obtener token FCM: $e');
    }
  }

  /// Enviar token FCM al backend
  Future<void> _enviarTokenAlBackend(String token) async {
    try {
      final authToken = await TokenManager.getToken();
      
      if (authToken == null) {
        print('⚠️ No hay token de autenticación, no se puede enviar FCM token');
        return;
      }

      final baseUrl = dotenv.env['BACKEND_URL'];
      if (baseUrl == null) {
        print('❌ BACKEND_URL no configurado en .env');
        return;
      }

      print('📤 Enviando FCM token al backend...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/usuarios/device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcm_token': token,
          'plataforma': Platform.isAndroid ? 'android' : 'ios',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Token FCM registrado en el backend correctamente');
      } else {
        print('⚠️ Error al registrar token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error enviando token al backend: $e');
    }
  }

  /// Método público para registrar token después del login/restaurar sesión
  Future<void> registrarTokenDespuesDeLogin() async {
    if (kIsWeb) {
      print('🌐 Web: FCM no disponible');
      return;
    }

    // Si no está inicializado, inicializar primero
    if (!_isInitialized) {
      print('🔧 FCM no inicializado, inicializando ahora...');
      await initialize();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Enviar token si existe
    if (_fcmToken != null) {
      print('📤 Enviando token FCM después de autenticación...');
      await _enviarTokenAlBackend(_fcmToken!);
    } else {
      print('⚠️ No hay token FCM disponible, intentando obtenerlo...');
      try {
        _fcmToken = await _messaging?.getToken();
        if (_fcmToken != null) {
          print('🔑 Token FCM obtenido: $_fcmToken');
          await _enviarTokenAlBackend(_fcmToken!);
        } else {
          print('❌ No se pudo obtener el token FCM');
        }
      } catch (e) {
        print('❌ Error obteniendo token FCM: $e');
      }
    }
  }

  /// Configurar listeners de mensajes (SOLO MÓVIL)
  void _setupMessageHandlers() {
    if (kIsWeb || _messaging == null) return;

    // 📱 App en PRIMER PLANO
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Mensaje recibido en PRIMER PLANO');
      print('📋 Título: ${message.notification?.title}');
      print('📋 Mensaje: ${message.notification?.body}');
      print('📦 Data: ${message.data}');
      _showLocalNotification(message);
    });

    // 🔔 App en SEGUNDO PLANO
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App abierta desde notificación (SEGUNDO PLANO)');
      print('📦 Data: ${message.data}');
      _handleNotificationNavigation(message);
    });

    // 🚀 App CERRADA - NO manejar aquí, se maneja con delay en método público
    print('✅ Listeners configurados (onMessage y onMessageOpenedApp)');
  }

  /// Método público para manejar mensaje inicial (app cerrada)
  /// Debe llamarse DESPUÉS de que la UI esté completamente cargada
  /// Método público para manejar mensaje inicial (app cerrada)
/// Debe llamarse DESPUÉS de que la UI esté completamente cargada
Future<void> handleInitialMessage() async {
  if (kIsWeb || _messaging == null) return;

  try {
    final message = await _messaging!.getInitialMessage();
    if (message != null) {
      print('🚀 Mensaje inicial detectado (app estaba cerrada)');
      print('📦 Data: ${message.data}');
      
      // Esperar que el contexto esté disponible (polling cada 200ms, max 5 segundos)
      for (int i = 0; i < 25; i++) {
        if (navigatorKey.currentContext != null) {
          print('✅ Contexto disponible después de ${i * 200}ms, navegando...');
          await Future.delayed(const Duration(milliseconds: 300)); // Un poco más de tiempo
          _handleNotificationNavigation(message);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      print('⚠️ Timeout esperando contexto, no se puede navegar');
    } else {
      print('ℹ️ No hay mensaje inicial (app no se abrió desde notificación)');
    }
  } catch (e) {
    print('❌ Error manejando mensaje inicial: $e');
  }
}

  /// Mostrar notificación local cuando la app está en primer plano
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'recetas_compartidas',
            'Recetas Compartidas',
            channelDescription: 'Notificaciones cuando alguien comparte una receta contigo',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            sound: const RawResourceAndroidNotificationSound('notification'),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: message.data['receta_id']?.toString(),
      );
      print('✅ Notificación local mostrada');
    }
  }

  /// Manejar tap en notificación local
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      print('👆 Tap en notificación local, receta_id: ${response.payload}');
      _navigateToRecipe(response.payload!);
    }
  }

  /// Manejar navegación desde notificación push
  void _handleNotificationNavigation(RemoteMessage message) {
    String? recetaId = message.data['receta_id']?.toString();
    if (recetaId != null) {
      print('🧭 Navegando a receta: $recetaId');
      _navigateToRecipe(recetaId);
    }
  }

  /// Navegar al detalle de la receta
  void _navigateToRecipe(String recetaId) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      AppRoutes.navigateToDetalleReceta(context, recetaId);
      print('✅ Navegación ejecutada a receta: $recetaId');
    } else {
      print('⚠️ No se puede navegar: context es null');
    }
  }

  /// Suscribirse a un topic
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb || _messaging == null) return;
    
    await _messaging!.subscribeToTopic(topic);
    print('✅ Suscrito a topic: $topic');
  }

  /// Desuscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb || _messaging == null) return;
    
    await _messaging!.unsubscribeFromTopic(topic);
    print('❌ Desuscrito de topic: $topic');
  }
}