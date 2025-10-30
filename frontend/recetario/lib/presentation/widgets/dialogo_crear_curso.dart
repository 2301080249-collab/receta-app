import 'package:flutter/material.dart';

// Core
import '../../core/mixins/loading_state_mixin.dart';
import '../../core/mixins/snackbar_mixin.dart';
import '../../core/mixins/auth_token_mixin.dart';

// Repositories
import '../../data/repositories/curso_repository.dart';
import '../../data/repositories/admin_repository.dart';

// Models
import '../../data/models/ciclo.dart';
import '../../data/models/curso.dart';

// Widgets
import '../widgets/dialogs/base_form_dialog.dart';
import '../widgets/fields/specialized_dropdown_fields.dart';
import '../widgets/fields/specialized_text_fields.dart';
import '../widgets/custom_textfield.dart';

/// Diálogo para crear o editar un curso
class DialogoCrearCurso extends StatefulWidget {
  final List<Ciclo> ciclos;
  final VoidCallback onGuardar;
  final Curso? curso; // ✅ NUEVO: curso a editar (null = crear)

  const DialogoCrearCurso({
    Key? key,
    required this.ciclos,
    required this.onGuardar,
    this.curso, // ✅ NUEVO
  }) : super(key: key);

  @override
  State<DialogoCrearCurso> createState() => _DialogoCrearCursoState();
}

class _DialogoCrearCursoState extends State<DialogoCrearCurso>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _seccionController = TextEditingController();
  final _creditosController = TextEditingController(text: '3');
  final _horarioController = TextEditingController();

  String? _cicloSeleccionado;
  String? _docenteSeleccionado;
  int _nivelSeleccionado = 1;
  List<Map<String, String>> _docentes = [];
  bool _loadingDocentes = true;

  // ✅ NUEVO: variable para saber si estamos editando
  bool get _esEdicion => widget.curso != null;

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
    
    // ✅ NUEVO: Si hay un curso, cargar sus datos
    if (_esEdicion) {
      _cargarDatosCurso();
    }
  }

  // ✅ NUEVO: Método para cargar los datos del curso en el formulario
  void _cargarDatosCurso() {
    final curso = widget.curso!;
    
    _nombreController.text = curso.nombre;
    _descripcionController.text = curso.descripcion ?? '';
    _seccionController.text = curso.seccion ?? '';
    _creditosController.text = curso.creditos.toString();
    _horarioController.text = curso.horario ?? '';
    
    _cicloSeleccionado = curso.cicloId;
    _docenteSeleccionado = curso.docenteId;
    _nivelSeleccionado = curso.nivel ?? 1;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _seccionController.dispose();
    _creditosController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  Future<void> _cargarDocentes() async {
    try {
      final token = getToken();
      final adminRepo = AdminRepository();
      final usuarios = await adminRepo.obtenerUsuarios(token);

      final docentes = usuarios
          .where((u) => u['rol'] == 'docente')
          .map((u) => {
                'id': (u['id'] ?? '').toString(),
                'nombre_completo': (u['nombre_completo'] ?? 'Sin nombre').toString(),
              })
          .where((u) => u['id']!.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _docentes = docentes;
        _loadingDocentes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDocentes = false);
      showError('Error al cargar docentes: $e');
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cicloSeleccionado == null || _docenteSeleccionado == null) {
      showError('Seleccione ciclo y docente');
      return;
    }

    try {
      await executeWithLoading(() async {
        final token = getToken();
        final cursoRepo = CursoRepository();

        // ✅ MODIFICADO: Crear o actualizar según el modo
        if (_esEdicion) {
          // Modo edición
          await cursoRepo.actualizarCurso(
            token: token,
            cursoId: widget.curso!.id,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim(),
            docenteId: _docenteSeleccionado!,
            cicloId: _cicloSeleccionado!,
            nivel: _nivelSeleccionado,
            seccion: _seccionController.text.trim().isNotEmpty 
                ? _seccionController.text.trim() 
                : null,
            creditos: int.parse(_creditosController.text),
            horario: _horarioController.text.trim().isNotEmpty
                ? _horarioController.text.trim()
                : null,
          );
        } else {
          // Modo creación
          await cursoRepo.crearCurso(
            token: token,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim(),
            docenteId: _docenteSeleccionado!,
            cicloId: _cicloSeleccionado!,
            nivel: _nivelSeleccionado,
            seccion: _seccionController.text.trim().isNotEmpty 
                ? _seccionController.text.trim() 
                : null,
            creditos: int.parse(_creditosController.text),
            horario: _horarioController.text.trim().isNotEmpty
                ? _horarioController.text.trim()
                : null,
          );
        }
      });

      // ✅ MODIFICADO: Mensaje según el modo
      showSuccess(_esEdicion 
          ? 'Curso actualizado exitosamente' 
          : 'Curso creado exitosamente');
      Navigator.pop(context);
      widget.onGuardar();
    } catch (e) {
      showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📱 Detectar si es móvil
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BaseFormDialog(
      // ✅ MODIFICADO: Título según el modo
      title: _esEdicion ? 'Editar Curso' : 'Crear Nuevo Curso',
      icon: Icons.book,
      formKey: _formKey,
      isLoading: isLoading,
      onSave: _guardar,
      // ✅ MODIFICADO: Texto del botón según el modo
      saveButtonText: _esEdicion ? 'Actualizar Curso' : 'Crear Curso',
      children: [
        CustomTextField(
          controller: _nombreController,
          label: 'Nombre del Curso *',
          hint: 'Repostería Avanzada',
          prefixIcon: Icons.book,
          validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),

        CustomTextField(
          controller: _descripcionController,
          label: 'Descripción',
          prefixIcon: Icons.description,
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Dropdown de Ciclo
        DropdownButtonFormField<String>(
          value: _cicloSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Ciclo Académico (Periodo) *',
            helperText: '¿En qué periodo se dicta?',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          items: widget.ciclos.map((ciclo) {
            return DropdownMenuItem(
              value: ciclo.id,
              child: Text(
                '${ciclo.nombre} ${ciclo.activo ? "(Activo)" : ""}',
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _cicloSeleccionado = value),
          validator: (value) => value == null ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),

        // Dropdown de Docente
        DocenteDropdownField(
          docentes: _docentes,
          value: _docenteSeleccionado,
          onChanged: (val) => setState(() => _docenteSeleccionado = val),
          isLoading: _loadingDocentes,
        ),
        const SizedBox(height: 16),

        // ✅ RESPONSIVO: Nivel y Sección
        isMobile
            ? Column(
                children: [
                  NivelCursoDropdownField(
                    value: _nivelSeleccionado,
                    onChanged: (val) => setState(() => _nivelSeleccionado = val!),
                  ),
                  const SizedBox(height: 16),
                  SeccionField(controller: _seccionController),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: NivelCursoDropdownField(
                      value: _nivelSeleccionado,
                      onChanged: (val) => setState(() => _nivelSeleccionado = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SeccionField(controller: _seccionController),
                  ),
                ],
              ),
        const SizedBox(height: 16),

        // ✅ RESPONSIVO: Créditos y Horario
        isMobile
            ? Column(
                children: [
                  CreditosField(controller: _creditosController),
                  const SizedBox(height: 16),
                  HorarioField(controller: _horarioController),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: CreditosField(controller: _creditosController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HorarioField(controller: _horarioController),
                  ),
                ],
              ),
      ],
    );
  }
}