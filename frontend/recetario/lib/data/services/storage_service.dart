import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;
  static const String bucket = 'archivos';

  /// Eliminar un archivo específico del Storage
  static Future<void> eliminarArchivo(String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      print('✅ Archivo eliminado del Storage: $path');
    } catch (e) {
      print('❌ Error al eliminar archivo del Storage: $e');
      throw Exception('Error al eliminar archivo del Storage: $e');
    }
  }

  /// Eliminar múltiples archivos
  static Future<void> eliminarArchivos(List<String> paths) async {
    try {
      await _supabase.storage.from(bucket).remove(paths);
      print('✅ ${paths.length} archivos eliminados del Storage');
    } catch (e) {
      print('❌ Error al eliminar archivos del Storage: $e');
      throw Exception('Error al eliminar archivos del Storage: $e');
    }
  }

  /// Extraer el path del Storage desde una URL completa
  /// Ejemplo: https://xxx.supabase.co/storage/v1/object/public/archivos/entregas/abc-123/file.pdf
  /// Resultado: entregas/abc-123/file.pdf
  static String extraerPathDeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      
      // Buscar el índice donde empieza el path real después de "archivos"
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
      
      throw Exception('No se pudo extraer el path de la URL');
    } catch (e) {
      print('❌ Error al extraer path de URL: $e');
      throw Exception('Error al procesar URL: $e');
    }
  }
}