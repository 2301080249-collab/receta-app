import 'package:flutter/material.dart';

// Core
import '../../core/mixins/loading_state_mixin.dart';
import '../../core/mixins/snackbar_mixin.dart';
import '../../core/mixins/auth_token_mixin.dart';

// Models & Services
import '../../data/models/matricula.dart';
import '../../data/services/matricula_service.dart';

// Widgets
import '../widgets/dialogs/base_form_dialog.dart';
import '../widgets/fields/specialized_dropdown_fields.dart';
import '../widgets/fields/specialized_text_fields.dart';
import '../widgets/fields/info_containers.dart';

/// Diálogo refactorizado para editar matrícula
/// ANTES: 182 líneas | DESPUÉS: ~90 líneas
class DialogoEditarMatricula extends StatefulWidget {
  final Matricula matricula;

  const DialogoEditarMatricula({
    super.key,
    required this.matricula,
  });

  @override
  State<DialogoEditarMatricula> createState() => _DialogoEditarMatriculaState();
}

class _DialogoEditarMatriculaState extends State<DialogoEditarMatricula>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  late String _estadoSeleccionado;
  final _notaController = TextEditingController();
  final _observacionesController = TextEditingController(); // ✅ NUEVO

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.matricula.estado;
    if (widget.matricula.notaFinal != null) {
      _notaController.text = widget.matricula.notaFinal.toString();
    }
    // ✅ NUEVO: Cargar observaciones si existen
    if (widget.matricula.observaciones != null) {
      _observacionesController.text = widget.matricula.observaciones!;
    }
  }

  @override
  void dispose() {
    _notaController.dispose();
    _observacionesController.dispose(); // ✅ NUEVO
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    double? nota;
    if (_notaController.text.isNotEmpty) {
      nota = double.tryParse(_notaController.text);
      if (nota == null || nota < 0 || nota > 20) {
        showError('La nota debe estar entre 0 y 20');
        return;
      }
    }

    try {
      await executeWithLoading(() async {
        final token = getToken();
        await MatriculaService.actualizarMatricula(
          token: token,
          matriculaId: widget.matricula.id,
          estado: _estadoSeleccionado,
          notaFinal: nota,
          observaciones: _observacionesController.text.trim().isEmpty 
              ? null 
              : _observacionesController.text.trim(), // ✅ NUEVO
        );
      });

      showSuccess('Matrícula actualizada exitosamente');
      Navigator.of(context).pop(true);
    } catch (e) {
      showError('Error al actualizar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseFormDialog(
      title: 'Editar Matrícula',
      icon: Icons.edit,
      isLoading: isLoading,
      onSave: _guardarCambios,
      saveButtonText: 'Guardar Cambios',
      maxWidth: 500,
      children: [
        // Container con información de la matrícula
        MatriculaInfoContainer(
          nombreEstudiante: widget.matricula.nombreEstudiante ?? 'Sin nombre',
          nombreCurso: widget.matricula.nombreCurso,
          nombreCiclo: widget.matricula.nombreCiclo,
        ),
        const SizedBox(height: 24),

        // Dropdown de estado usando widget especializado
        EstadoMatriculaDropdownField(
          value: _estadoSeleccionado,
          onChanged: (val) {
            if (val != null) {
              setState(() => _estadoSeleccionado = val);
            }
          },
        ),
        const SizedBox(height: 16),

        // Campo de nota usando widget especializado
        NotaField(
          controller: _notaController,
          label: 'Nota Final (0-20)',
          hint: 'Dejar vacío si aún no tiene nota',
        ),
        const SizedBox(height: 16),

        // ✅ NUEVO: Campo de observaciones
        TextField(
          controller: _observacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Observaciones sobre esta matrícula...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}