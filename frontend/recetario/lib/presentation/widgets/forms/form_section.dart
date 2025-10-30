import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Widget reutilizable para secciones de formularios con título e ícono
/// Ejemplo: _buildDatosGeneralesSection(), _buildEstudianteSection()
class FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final List<Widget> children;
  final EdgeInsets? padding;

  const FormSection({
    Key? key,
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la sección
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(title, style: AppTheme.heading3),
          ],
        ),
        SizedBox(height: padding?.top ?? 16),
        
        // Contenido de la sección
        ...children,
      ],
    );
  }
}

/// Widget para agrupar campos del formulario con espaciado consistente
class FormFieldGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const FormFieldGroup({
    Key? key,
    required this.children,
    this.spacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children
          .map((child) => Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: child,
              ))
          .toList(),
    );
  }
}