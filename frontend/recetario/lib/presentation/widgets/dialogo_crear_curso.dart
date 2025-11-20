import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

// Core
import '../../core/mixins/loading_state_mixin.dart';
import '../../core/mixins/snackbar_mixin.dart';
import '../../core/mixins/auth_token_mixin.dart';
import '../../core/theme/app_theme.dart';

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
  final Curso? curso;

  const DialogoCrearCurso({
    Key? key,
    required this.ciclos,
    required this.onGuardar,
    this.curso,
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

  bool get _esEdicion => widget.curso != null;

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
    
    if (_esEdicion) {
      _cargarDatosCurso();
    }
  }

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
      // ⚠️ ADVERTENCIA - NARANJA
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
        
        // 🎨 ÍCONO NARANJA DE ADVERTENCIA
        customHeader: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.orange[600],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 60,
          ),
        ),
        
        title: 'Campos Incompletos',
        desc: 'Por favor seleccione ciclo y docente para continuar.',
        btnOkText: 'Entendido',
        width: MediaQuery.of(context).size.width < 600 ? null : 500,
        btnOkOnPress: () {},
        btnOkColor: Colors.orange[600],
        dismissOnTouchOutside: false,
        headerAnimationLoop: false,
      ).show();
      return;
    }

    try {
      await executeWithLoading(() async {
        final token = getToken();
        final cursoRepo = CursoRepository();

        if (_esEdicion) {
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

      // ✅ ÉXITO - VERDE
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          
          // 🎨 ÍCONO VERDE DE ÉXITO
          customHeader: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          
          title: _esEdicion ? '¡Curso Actualizado!' : '¡Curso Creado!',
          desc: _esEdicion 
              ? 'Los datos del curso han sido actualizados correctamente.'
              : 'El curso ha sido creado exitosamente.',
          btnOkText: 'Aceptar',
          width: MediaQuery.of(context).size.width < 600 ? null : 500,
          btnOkOnPress: () {
            Navigator.pop(context);
            widget.onGuardar();
          },
          btnOkColor: AppTheme.successColor,
          dismissOnTouchOutside: false,
          headerAnimationLoop: false,
        ).show();
      }
      
    } catch (e) {
      // ❌ ERROR - ROJO
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
          
          // 🎨 ÍCONO ROJO DE ERROR
          customHeader: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.error_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          
          title: 'Error',
          desc: 'No se pudo ${_esEdicion ? "actualizar" : "crear"} el curso: ${e.toString()}',
          btnOkText: 'Cerrar',
          width: MediaQuery.of(context).size.width < 600 ? null : 500,
          btnOkOnPress: () {},
          btnOkColor: AppTheme.errorColor,
          headerAnimationLoop: false,
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BaseFormDialog(
      title: _esEdicion ? 'Editar Curso' : 'Crear Nuevo Curso',
      icon: Icons.book,
      formKey: _formKey,
      isLoading: isLoading,
      onSave: _guardar,
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

        DocenteDropdownField(
          docentes: _docentes,
          value: _docenteSeleccionado,
          onChanged: (val) => setState(() => _docenteSeleccionado = val),
          isLoading: _loadingDocentes,
        ),
        const SizedBox(height: 16),

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