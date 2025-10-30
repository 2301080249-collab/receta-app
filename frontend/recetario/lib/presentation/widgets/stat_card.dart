import 'package:flutter/material.dart';

/// Widget: Tarjeta de estadística reutilizable (Responsivo)
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVO: Detectar si es móvil
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16), // ✅ Menos padding en móvil
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10), // ✅ Icono más compacto en móvil
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon, 
                  size: isMobile ? 24 : 28, // ✅ Icono más pequeño en móvil
                  color: color,
                ),
              ),
              SizedBox(height: isMobile ? 8 : 10), // ✅ Menos espacio en móvil
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26, // ✅ Valor más pequeño en móvil
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13, // ✅ Título más pequeño en móvil
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                SizedBox(height: isMobile ? 2 : 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10, // ✅ Subtítulo más pequeño en móvil
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}