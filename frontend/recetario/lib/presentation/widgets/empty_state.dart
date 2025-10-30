import 'package:flutter/material.dart';

/// Widget: Estado vacío genérico reutilizable
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Theme.of(context).primaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: effectiveIconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: effectiveIconColor.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: Icon(Icons.add),
              label: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}
