import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Dialog reutilizable para preguntar al usuario si desea cambiar contraseña
/// en su primer inicio de sesión
class FirstTimeDialog extends StatelessWidget {
  final VoidCallback onChangeNow;
  final VoidCallback onSkip;

  const FirstTimeDialog({
    Key? key,
    required this.onChangeNow,
    required this.onSkip,
  }) : super(key: key);

  /// Método estático para mostrar el dialog fácilmente
  static Future<bool?> show(
    BuildContext context, {
    required VoidCallback onChangeNow,
    required VoidCallback onSkip,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // No cerrar tocando fuera
      builder: (context) =>
          FirstTimeDialog(onChangeNow: onChangeNow, onSkip: onSkip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              '¡Bienvenido al Sistema!',
              style: AppTheme.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Mensaje
            Text(
              'Es tu primera vez iniciando sesión. Por seguridad, te recomendamos cambiar tu contraseña.',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Mensaje adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Puedes cambiarla más tarde desde tu perfil',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.warningColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botones
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botón primario: Cambiar ahora
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onChangeNow();
                  },
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Cambiar Contraseña Ahora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // Botón secundario: Omitir
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSkip();
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Omitir por Ahora'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
