import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Core
import '../../core/mixins/loading_state_mixin.dart';
import '../../core/mixins/snackbar_mixin.dart';
import '../../core/mixins/auth_token_mixin.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';

// Repositories
import '../../data/repositories/curso_repository.dart';

// Models
import '../../data/models/ciclo.dart';
import '../../data/models/curso.dart';

// Widgets
import '../widgets/dialogs/base_form_dialog.dart';
import '../widgets/fields/specialized_dropdown_fields.dart';
import '../widgets/fields/specialized_text_fields.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/horario_selector_simple.dart';

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

  // ✅ SOLUCIÓN COMPLETA: Obtener docentes con usuario_id correcto
  Future<void> _cargarDocentes() async {
    try {
      final token = getToken();
      
      // ✅ Llamar al endpoint con header ngrok
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/docentes'),
        headers: {
          ...ApiConstants.headersWithAuth(token),
          'ngrok-skip-browser-warning': 'true', // ✅ NUEVO: Bypass ngrok
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        print('🔍 DATA COMPLETO: $data'); // ← DEBUG
        if (data.isNotEmpty) {
          print('🔍 PRIMER ITEM: ${data[0]}'); // ← DEBUG
        }
        
        final docentes = data
            .map((d) => {
                  // ✅ CAMBIO: Usar usuario_id del docente (no usuarios.id)
                  'id': (d['usuario_id'] ?? '').toString(),
                  'nombre_completo': (d['usuarios']?['nombre_completo'] ?? 'Sin nombre').toString(),
                })
            .where((d) => d['id']!.isNotEmpty)
            .toList();

        if (!mounted) return;
        setState(() {
          _docentes = docentes;
          _loadingDocentes = false;
        });
        
        print('✅ Docentes cargados: ${_docentes.length}');
        if (_docentes.isNotEmpty) {
          print('✅ Primer docente: ${_docentes[0]}');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error al cargar docentes: $e');
      if (!mounted) return;
      setState(() => _loadingDocentes = false);
      showError('Error al cargar docentes: $e');
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cicloSeleccionado == null || _docenteSeleccionado == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
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

    print('🎯 Guardando curso con docenteId: $_docenteSeleccionado');

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

      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
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
      print('❌ Error al guardar curso: $e');
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
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
          onChanged: (val) {
            print('🎯 Docente seleccionado: $val');
            setState(() => _docenteSeleccionado = val);
          },
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

        Column(
          children: [
            CreditosField(controller: _creditosController),
            const SizedBox(height: 16),
            HorarioSelector(controller: _horarioController),
          ],
        ),
      ],
    );
  }
}