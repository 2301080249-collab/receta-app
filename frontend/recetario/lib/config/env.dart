import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  // Backend
  static String get backendUrl => 'https://receta-backend.onrender.com';
  
  // Supabase - valores hardcodeados para TODAS las plataformas
  static String get supabaseUrl => 'https://mqwaijsnybindsxvgjss.supabase.co';
  
  static String get supabaseKey => 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xd2FpanNueWJpbmRzeHZnanNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNzQyMDksImV4cCI6MjA3NDc1MDIwOX0.sR_W-Nc1-qoisLUBJWR16PpZ8uRj693CgtBK1jVg1N8';
  
  static String get supabaseAnonKey => 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xd2FpanNueWJpbmRzeHZnanNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNzQyMDksImV4cCI6MjA3NDc1MDIwOX0.sR_W-Nc1-qoisLUBJWR16PpZ8uRj693CgtBK1jVg1N8';
  
  // Gemini AI
  static String get geminiApiKey => 'AIzaSyDzVX0e1hmW2U-An4A_BBzVIFSXoxylq2k';
  
  // Environment
  static String get environment => 'production';
  static int get connectionTimeout => 30;
  
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