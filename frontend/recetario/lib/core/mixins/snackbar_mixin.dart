import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mixin para mostrar mensajes (SnackBars) de forma unificada
/// Uso: class _MyScreenState extends State<MyScreen> with SnackBarMixin
mixin SnackBarMixin<T extends StatefulWidget> on State<T> {
  
  /// Muestra mensaje de éxito (verde)
  void showSuccess(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppTheme.successColor,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
  
  /// Muestra mensaje de error (rojo)
  void showError(String message, {Duration? duration}) {
    // Limpia el prefijo "Exception: " si existe
    final cleanMessage = message.replaceAll('Exception: ', '');
    
    _showSnackBar(
      message: cleanMessage,
      icon: Icons.error_outline,
      backgroundColor: AppTheme.errorColor,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
  
  /// Muestra mensaje informativo (azul)
  void showInfo(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      icon: Icons.info_outline,
      backgroundColor: AppTheme.infoColor,
      duration: duration ?? const Duration(seconds: 2),
    );
  }
  
  /// Muestra mensaje de "En desarrollo"
  void showInDevelopment(String feature) {
    showInfo('$feature - Próximamente');
  }
  
  /// Método privado que construye el SnackBar
  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}