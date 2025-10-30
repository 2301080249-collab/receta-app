import 'package:flutter/material.dart';

/// Mixin para manejar estados de carga de forma unificada
/// Uso: class _MyScreenState extends State<MyScreen> with LoadingStateMixin
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;
  
  /// Ejecuta una operación asíncrona con manejo de loading automático
  Future<R?> executeWithLoading<R>(
    Future<R> Function() operation, {
    VoidCallback? onSuccess,
    Function(dynamic error)? onError,
  }) async {
    if (!mounted) return null;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await operation();
      if (mounted) {
        setState(() => _isLoading = false);
        onSuccess?.call();
      }
      return result;
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        onError?.call(e);
      }
      rethrow;
    }
  }
  
  /// Setter manual para casos especiales
  void setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }
}