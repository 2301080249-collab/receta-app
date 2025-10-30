import 'package:flutter/material.dart';

/// Widget: Badge de rol con color según el tipo de usuario
class RoleBadge extends StatelessWidget {
  final String rol;
  final bool uppercase;

  const RoleBadge({Key? key, required this.rol, this.uppercase = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(rol);
    final text = uppercase ? rol.toUpperCase() : rol;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: config.textColor,
        ),
      ),
    );
  }

  /// En lugar de Map, devolvemos una clase tipada (más segura)
  _RoleConfig _getRoleConfig(String rol) {
    switch (rol.toLowerCase()) {
      case 'estudiante':
        return _RoleConfig(
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade300,
          textColor: Colors.blue.shade700,
        );
      case 'docente':
        return _RoleConfig(
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade700,
        );
      case 'administrador':
        return _RoleConfig(
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade300,
          textColor: Colors.orange.shade700,
        );
      default:
        return _RoleConfig(
          backgroundColor: Colors.grey.shade50,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
        );
    }
  }
}

/// Clase auxiliar para tipar los colores
class _RoleConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _RoleConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
