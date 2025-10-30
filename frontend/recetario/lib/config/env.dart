import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get backendUrl {
    final baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8080';

    // Si estás en Android (emulador físico o virtual)
    if (!kIsWeb && Platform.isAndroid) {
      return baseUrl.replaceAll('localhost', '10.0.2.2');
    }

    // Si estás en Web, iOS o Windows
    return baseUrl;
  }

  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseKey => dotenv.env['SUPABASE_KEY'] ?? '';

  // Ambientes
  static bool get isProduction => dotenv.env['ENVIRONMENT'] == 'production';
  static bool get isDevelopment => !isProduction;

  // Timeouts
  static Duration get connectionTimeout =>
      Duration(seconds: int.parse(dotenv.env['CONNECTION_TIMEOUT'] ?? '30'));
}
