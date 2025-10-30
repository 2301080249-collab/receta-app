import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Diálogo base reutilizable para formularios CRUD
/// Unifica la estructura de todos los diálogos (crear curso, ciclo, matrícula, etc.)
class BaseFormDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final VoidCallback onSave;
  final String saveButtonText;
  final bool isLoading;
  final double maxWidth;
  final GlobalKey<FormState>? formKey;

  const BaseFormDialog({
    Key? key,
    required this.title,
    required this.children,
    required this.onSave,
    this.icon,
    this.saveButtonText = 'Guardar',
    this.isLoading = false,
    this.maxWidth = 600,
    this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              
              const Divider(height: 32),
              
              // Contenido del formulario
              Flexible(child: form),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              DialogActions(
                onCancel: () => Navigator.of(context).pop(false),
                onSave: isLoading ? null : onSave,
                saveText: saveButtonText,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: 'Cerrar',
        ),
      ],
    );
  }
}

/// Widget para los botones de acción del diálogo (Cancelar/Guardar)
class DialogActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final String cancelText;
  final String saveText;
  final bool isLoading;

  const DialogActions({
    Key? key,
    required this.onCancel,
    required this.onSave,
    this.cancelText = 'Cancelar',
    this.saveText = 'Guardar',
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isLoading ? null : onCancel,
          child: Text(cancelText),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: AppTheme.primaryColor,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(saveText),
        ),
      ],
    );
  }
}

/// Widget para títulos de secciones numeradas (Paso 1, Paso 2, etc.)
class StepSection extends StatelessWidget {
  final String title;
  final EdgeInsets padding;

  const StepSection({
    Key? key,
    required this.title,
    this.padding = const EdgeInsets.only(bottom: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}