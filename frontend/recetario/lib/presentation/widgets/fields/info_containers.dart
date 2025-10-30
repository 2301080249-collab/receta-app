import 'package:flutter/material.dart';

/// Container para mostrar información contextual de matrícula
class MatriculaInfoContainer extends StatelessWidget {
  final String nombreEstudiante;
  final String? nombreCurso;
  final String? nombreCiclo;
  final Color? backgroundColor;

  const MatriculaInfoContainer({
    Key? key,
    required this.nombreEstudiante,
    this.nombreCurso,
    this.nombreCiclo,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombreEstudiante,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (nombreCurso != null) ...[
            const SizedBox(height: 8),
            Text('Curso: $nombreCurso'),
          ],
          if (nombreCiclo != null) Text('Ciclo: $nombreCiclo'),
        ],
      ),
    );
  }
}

/// Container genérico para mostrar información destacada
class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? backgroundColor;
  final List<Widget>? additionalInfo;

  const InfoCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.backgroundColor,
    this.additionalInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
          if (additionalInfo != null) ...additionalInfo!,
        ],
      ),
    );
  }
}