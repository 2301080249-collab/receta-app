import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? warningMessage;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final Widget? content;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.warningMessage,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    required this.onConfirm,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (content != null) ...[
            const SizedBox(height: 12),
            content!,
          ],
          if (warningMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              warningMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}