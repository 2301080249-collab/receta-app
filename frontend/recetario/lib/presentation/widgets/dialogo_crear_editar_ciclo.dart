import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/ciclo_repository.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/ciclo.dart';

/// Dialogo reutilizable para crear o editar ciclos - RESPONSIVO
class DialogoCrearEditarCiclo extends StatefulWidget {
  final VoidCallback onGuardar;
  final Ciclo? ciclo;

  const DialogoCrearEditarCiclo({
    Key? key,
    required this.onGuardar,
    this.ciclo,
  }) : super(key: key);

  @override
  State<DialogoCrearEditarCiclo> createState() =>
      _DialogoCrearEditarCicloState();
}

class _DialogoCrearEditarCicloState extends State<DialogoCrearEditarCiclo> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _duracionController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isLoading = false;

  bool get _esEdicion => widget.ciclo != null;

  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      _cargarDatosCiclo();
    } else {
      _duracionController.text = '16';
    }
  }

  void _cargarDatosCiclo() {
    final ciclo = widget.ciclo!;

    _nombreController.text = ciclo.nombre;
    _duracionController.text = ciclo.duracionSemanas.toString();

    _fechaInicio = DateTime.parse(ciclo.fechaInicio);
    _fechaFin = DateTime.parse(ciclo.fechaFin);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF475569),
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_fechaInicio == null || _fechaFin == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        animType: AnimType.scale,
        
        customHeader: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.formColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.formColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.info_rounded,
            color: Colors.white,
            size: 60,
          ),
        ),
        
        title: 'Fechas requeridas',
        desc: 'Por favor, seleccione las fechas de inicio y fin del ciclo.',
        btnOkText: 'Entendido',
        btnOkColor: AppTheme.formColor,
        btnOkOnPress: () {},
        width: MediaQuery.of(context).size.width < 600 ? null : 500,
        headerAnimationLoop: false,
      ).show();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;
      final cicloRepo = CicloRepository();

      if (_esEdicion) {
        await cicloRepo.actualizarCiclo(
          token: token,
          cicloId: widget.ciclo!.id,
          nombre: _nombreController.text.trim(),
          fechaInicio: DateFormat('yyyy-MM-dd').format(_fechaInicio!),
          fechaFin: DateFormat('yyyy-MM-dd').format(_fechaFin!),
          duracionSemanas: int.parse(_duracionController.text),
        );
      } else {
        await cicloRepo.crearCiclo(
          token: token,
          nombre: _nombreController.text.trim(),
          fechaInicio: DateFormat('yyyy-MM-dd').format(_fechaInicio!),
          fechaFin: DateFormat('yyyy-MM-dd').format(_fechaFin!),
          duracionSemanas: int.parse(_duracionController.text),
        );
      }

      if (!mounted) return;

      // ✅ Muestra el éxito
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
        
        title: _esEdicion ? '¡Ciclo Actualizado!' : '¡Ciclo Creado!',
        desc: _esEdicion
            ? 'El ciclo "${_nombreController.text.trim()}" ha sido actualizado correctamente.'
            : 'El ciclo "${_nombreController.text.trim()}" ha sido creado exitosamente.',
        btnOkText: 'Aceptar',
        btnOkColor: AppTheme.successColor,
        dismissOnTouchOutside: false,
   btnOkOnPress: () {
  Navigator.of(context).pop(true);
},
        width: MediaQuery.of(context).size.width < 600 ? null : 500,
        headerAnimationLoop: false,
      ).show();
      
    } catch (e) {
      setState(() => _isLoading = false);
      
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
          desc: e.toString().replaceAll('Exception: ', ''),
          btnOkText: 'Entendido',
          btnOkColor: AppTheme.errorColor,
          btnOkOnPress: () {},
          width: MediaQuery.of(context).size.width < 600 ? null : 500,
          headerAnimationLoop: false,
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth * 0.9 : 500,
        ),
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF475569),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF475569).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.event_rounded,
                        color: Colors.white,
                        size: isMobile ? 20 : 22,
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Text(
                        _esEdicion ? 'Editar Ciclo' : 'Crear Nuevo Ciclo',
                        style: AppTheme.heading2.copyWith(
                          fontSize: isMobile ? 18 : 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 20 : 24),

                TextFormField(
                  controller: _nombreController,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Ciclo *',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    hintText: '2024-I, 2024-II, etc.',
                    hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    prefixIcon: Icon(
                      Icons.label,
                      color: const Color(0xFF475569),
                      size: isMobile ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 14 : 16,
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                SizedBox(height: isMobile ? 14 : 16),

                isMobile
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _seleccionarFecha(context, true),
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _fechaInicio == null
                                    ? 'Fecha Inicio'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_fechaInicio!),
                                style: const TextStyle(fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(
                                  color: Color(0xFF475569),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _seleccionarFecha(context, false),
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _fechaFin == null
                                    ? 'Fecha Fin'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_fechaFin!),
                                style: const TextStyle(fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(
                                  color: Color(0xFF475569),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _seleccionarFecha(context, true),
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _fechaInicio == null
                                    ? 'Fecha Inicio'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_fechaInicio!),
                                style: const TextStyle(fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(
                                  color: Color(0xFF475569),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _seleccionarFecha(context, false),
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _fechaFin == null
                                    ? 'Fecha Fin'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_fechaFin!),
                                style: const TextStyle(fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(
                                  color: Color(0xFF475569),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: isMobile ? 14 : 16),

                TextFormField(
                  controller: _duracionController,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Duración (semanas) *',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    prefixIcon: Icon(
                      Icons.access_time,
                      color: const Color(0xFF475569),
                      size: isMobile ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 14 : 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Requerido';
                    final num = int.tryParse(value!);
                    if (num == null || num < 1 || num > 52) {
                      return 'Debe ser entre 1 y 52';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isMobile ? 20 : 24),

                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF475569),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              elevation: 2,
                              shadowColor:
                                  const Color(0xFF475569).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _esEdicion
                                        ? 'Actualizar Ciclo'
                                        : 'Crear Ciclo',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF475569),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              elevation: 2,
                              shadowColor:
                                  const Color(0xFF475569).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _esEdicion
                                        ? 'Actualizar Ciclo'
                                        : 'Crear Ciclo',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}