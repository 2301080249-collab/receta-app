import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Item de actividad reutilizable en listas del dashboard
class ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String time;

  const ActivityItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(time, style: AppTheme.caption),
      ],
    );
  }
}
