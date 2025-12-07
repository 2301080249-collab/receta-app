import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Backend
  static String get backendUrl => 
      dotenv.env['BACKEND_URL'] ?? 'https://nerveless-saporific-fermin.ngrok-free.dev';
  
  // Supabase
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? '';
  
  static String get supabaseKey => 
      dotenv.env['SUPABASE_KEY'] ?? '';
  
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Gemini AI
  static String get geminiApiKey => 
      dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Environment
  static String get environment => 
      dotenv.env['ENVIRONMENT'] ?? 'production';
  
  static int get connectionTimeout => 
      int.tryParse(dotenv.env['CONNECTION_TIMEOUT'] ?? '30') ?? 30;
  
  // Validación
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  
  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL no está configurado');
    }
    if (supabaseKey.isEmpty) {
      throw Exception('SUPABASE_KEY no está configurado');
    }
    if (!hasGeminiKey) {
      print('⚠️ ADVERTENCIA: GEMINI_API_KEY no configurado');
    }
  }
}