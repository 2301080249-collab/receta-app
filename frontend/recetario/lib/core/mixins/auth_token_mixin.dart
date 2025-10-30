import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Mixin para obtener el token de autenticación de forma segura
/// Uso: class _MyScreenState extends State<MyScreen> with AuthTokenMixin
mixin AuthTokenMixin<T extends StatefulWidget> on State<T> {
  
  /// Obtiene el token del AuthProvider
  /// Lanza Exception si no hay token disponible
  String getToken() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación');
    }
    
    return token;
  }
  
  /// Obtiene el token de forma segura (nullable)
  /// Retorna null si no hay token en lugar de lanzar excepción
  String? getTokenSafe() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.token;
    } catch (e) {
      return null;
    }
  }
  
  /// Ejecuta una operación que requiere token
  /// Maneja automáticamente el caso de token faltante
  Future<R?> executeWithToken<R>(
    Future<R> Function(String token) operation, {
    String? errorMessage,
  }) async {
    try {
      final token = getToken();
      return await operation(token);
    } catch (e) {
      final message = errorMessage ?? 'Error de autenticación: ${e.toString()}';
      throw Exception(message);
    }
  }
}