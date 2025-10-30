import 'package:flutter/material.dart';

/// Widget: Avatar con inicial o ícono según el rol del usuario
class RoleAvatar extends StatelessWidget {
  final String rol;
  final String? nombreCompleto;
  final double radius;

  const RoleAvatar({
    Key? key,
    required this.rol,
    this.nombreCompleto,
    this.radius = 28,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(rol);
    
    // Si hay nombre completo, mostramos la inicial
    if (nombreCompleto != null && nombreCompleto!.isNotEmpty) {
      final inicial = nombreCompleto![0].toUpperCase();
      
      return CircleAvatar(
        radius: radius,
        backgroundColor: config['backgroundColor'],
        child: Text(
          inicial,
          style: TextStyle(
            color: config['textColor'],
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // Si no hay nombre, mostramos el ícono
    return CircleAvatar(
      radius: radius,
      backgroundColor: config['backgroundColor'],
      child: Icon(
        config['icon'],
        color: config['iconColor'],
        size: radius * 0.9,
      ),
    );
  }

  Map<String, dynamic> _getRoleConfig(String rol) {
    switch (rol.toLowerCase()) {
      case 'estudiante':
        return {
          'icon': Icons.school,
          'backgroundColor': Colors.blue[100],
          'iconColor': Colors.blue[700],
          'textColor': Colors.blue[700],
        };
      case 'docente':
        return {
          'icon': Icons.person,
          'backgroundColor': Colors.green[100],
          'iconColor': Colors.green[700],
          'textColor': Colors.green[700],
        };
      case 'administrador':
        return {
          'icon': Icons.admin_panel_settings,
          'backgroundColor': Colors.orange[100],
          'iconColor': Colors.orange[700],
          'textColor': Colors.orange[700],
        };
      default:
        return {
          'icon': Icons.person_outline,
          'backgroundColor': Colors.grey[100],
          'iconColor': Colors.grey[700],
          'textColor': Colors.grey[700],
        };
    }
  }
}