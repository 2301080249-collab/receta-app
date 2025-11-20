import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  // Backend - usar URL de Render en web, .env en móvil
  static String get backendUrl {
    if (kIsWeb) {
      return 'https://receta-backend.onrender.com';
    }
    return dotenv.env['BACKEND_URL'] ?? 'http://localhost:8080';
  }
  
  // Supabase - valores hardcodeados para web
  static String get supabaseUrl {
    if (kIsWeb) {
      return 'https://mqwaijsnybindsxvgjss.supabase.co';
    }
    return dotenv.env['SUPABASE_URL'] ?? '';
  }
  
  static String get supabaseKey {
    if (kIsWeb) {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xd2FpanNueWJpbmRzeHZnanNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNzQyMDksImV4cCI6MjA3NDc1MDIwOX0.sR_W-Nc1-qoisLUBJWR16PpZ8uRj693CgtBK1jVg1N8';
    }
    return dotenv.env['SUPABASE_KEY'] ?? '';
  }
  
  static String get supabaseAnonKey {
    if (kIsWeb) {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xd2FpanNueWJpbmRzeHZnanNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNzQyMDksImV4cCI6MjA3NDc1MDIwOX0.sR_W-Nc1-qoisLUBJWR16PpZ8uRj693CgtBK1jVg1N8';
    }
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }
  
  // Gemini AI
  static String get geminiApiKey {
    if (kIsWeb) {
      return 'AIzaSyDzVX0e1hmW2U-An4A_BBzVIFSXoxylq2k';
    }
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }
  
  // Environment
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
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
      print('⚠️ ADVERTENCIA: GEMINI_API_KEY no configurado. Análisis nutricional deshabilitado.');
    }
  }
}