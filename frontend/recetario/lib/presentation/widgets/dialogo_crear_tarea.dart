import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/tarea.dart';
import '../../data/repositories/tarea_repository.dart';

class DialogoCrearTarea extends StatefulWidget {
  final String cursoId;
  final String? temaId;
  final VoidCallback onTareaCreada;

  const DialogoCrearTarea({
    Key? key,
    required this.cursoId,
    this.temaId,
    required this.onTareaCreada,
  }) : super(key: key);

  @override
  State<DialogoCrearTarea> createState() => _DialogoCrearTareaState();
}

class _DialogoCrearTareaState extends State<DialogoCrearTarea> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _puntajeController = TextEditingController(text: '20');
  final _penalizacionController = TextEditingController(text: '1');
  final _toleranciaController = TextEditingController(text: '7');
  late TareaRepository _tareaRepository;

  bool _isLoading = false;
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 7));
  bool _permiteEntregaTardia = true;
  String _tipoSeleccionado = 'practica';

  final Map<String, String> _tipos = {
    'practica': 'Práctica',
    'evaluacion': 'Evaluación',
    'proyecto': 'Proyecto',
  };

  @override
  void initState() {
    super.initState();
    _tareaRepository = TareaRepository();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _puntajeController.dispose();
    _penalizacionController.dispose();
    _toleranciaController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaLimite,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaLimite),
      );

      if (hora != null) {
        setState(() {
          _fechaLimite = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            hora.hour,
            hora.minute,
          );
        });
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tarea = Tarea(
        id: '',
        cursoId: widget.cursoId,
        temaId: widget.temaId,
        titulo: _tituloController.text,
        descripcion: _descripcionController.text.isEmpty
            ? null
            : _descripcionController.text,
        fechaPublicacion: DateTime.now(),
        fechaLimite: _fechaLimite,
        puntajeMaximo: double.parse(_puntajeController.text),
        permiteEntregaTardia: _permiteEntregaTardia,
        penalizacionPorDia: _permiteEntregaTardia
            ? double.parse(_penalizacionController.text)
            : 0,
        diasTolerancia: _permiteEntregaTardia
            ? int.parse(_toleranciaController.text)
            : 0,
        tipo: _tipoSeleccionado,
        activo: true,
        createdAt: DateTime.now(),
      );

    // Línea ~112-120 (en el método _guardar)

await _tareaRepository.crearTarea(tarea);

if (mounted) {
  Navigator.pop(context);
  
  // ✅ FORZAR RECARGA (ya no solo llamar callback)
  widget.onTareaCreada(); // Esto llamará a _cargarTemas en el layout
  
  // ✅ SnackBar bonito y profesional
  ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Tarea creada!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('La tarea "${tarea.titulo}" se creó exitosamente.'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // ✅ SnackBar de error también bonito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error al crear tarea: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 40 : (isMobile ? 16.w : 40),
        vertical: kIsWeb ? 40 : (isMobile ? 24.h : 40),
      ),
      contentPadding: EdgeInsets.zero,

      title: Padding(
        padding: EdgeInsets.fromLTRB(
          kIsWeb ? 24 : (isMobile ? 16.w : 24),
          kIsWeb ? 20 : (isMobile ? 16.h : 20),
          kIsWeb ? 24 : (isMobile ? 16.w : 24),
          kIsWeb ? 12 : (isMobile ? 8.h : 12),
        ),
        child: Text(
          'Crear Nueva Tarea',
          style: TextStyle(
            fontSize: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      content: Container(
        width: kIsWeb ? 550 : (isMobile ? screenWidth * 0.9 : 550),
        constraints: BoxConstraints(
          maxHeight: screenHeight * (kIsWeb ? 0.8 : (isMobile ? 0.75 : 0.8)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 24 : (isMobile ? 16.w : 24),
              vertical: kIsWeb ? 0 : (isMobile ? 8.h : 0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                TextFormField(
                  controller: _tituloController,
                  style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                  decoration: InputDecoration(
                    labelText: 'Título de la tarea *',
                    labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    hintText: 'Ej: Pan artesanal',
                    hintStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment, size: kIsWeb ? 24 : (isMobile ? 20.sp : 24)),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                      vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El título es obligatorio';
                    }
                    return null;
                  },
                ),

                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),

                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  maxLines: kIsWeb ? 3 : (isMobile ? 2 : 3),
                  style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                  decoration: InputDecoration(
                    labelText: 'Instrucciones (Opcional)',
                    labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    hintText: 'Describe lo que deben hacer los estudiantes...',
                    hintStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 12.sp : 14)),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                      vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
                    ),
                  ),
                ),

                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),

                // Tipo de tarea
                Text(
                  'Tipo de tarea',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                  ),
                ),
                SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
                Wrap(
                  spacing: kIsWeb ? 8 : (isMobile ? 6.w : 8),
                  runSpacing: kIsWeb ? 8 : (isMobile ? 6.h : 8),
                  children: _tipos.entries.map((entry) {
                    final isSelected = _tipoSeleccionado == entry.key;
                    return ChoiceChip(
                      label: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                          color: isSelected ? Colors.white : const Color(0xFF455A64),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF455A64),
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 12 : (isMobile ? 8.w : 12),
                        vertical: kIsWeb ? 8 : (isMobile ? 4.h : 8),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _tipoSeleccionado = entry.key);
                        }
                      },
                    );
                  }).toList(),
                ),

                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),

                // Fecha límite
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                        vertical: kIsWeb ? 12 : (isMobile ? 10.h : 12),
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
                            color: Colors.grey[700],
                          ),
                          SizedBox(width: kIsWeb ? 12 : (isMobile ? 10.w : 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha límite',
                                  style: TextStyle(
                                    fontSize: kIsWeb ? 13 : (isMobile ? 12.sp : 13),
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${_fechaLimite.day}/${_fechaLimite.month}/${_fechaLimite.year} a las ${_fechaLimite.hour}:${_fechaLimite.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: kIsWeb ? 15 : (isMobile ? 14.sp : 15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
                if (!isMobile) const Divider(),
                if (!isMobile) SizedBox(height: 8.h),

                // Puntaje máximo
                TextFormField(
                  controller: _puntajeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                  decoration: InputDecoration(
                    labelText: 'Puntaje máximo',
                    labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stars, size: kIsWeb ? 24 : (isMobile ? 20.sp : 24)),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                      vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El puntaje es obligatorio';
                    }
                    final numero = double.tryParse(value);
                    if (numero == null || numero <= 0) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),

                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),

                // Switch entrega tardía
                Container(
                  decoration: isMobile
                      ? BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8.r),
                        )
                      : null,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 0 : (isMobile ? 12.w : 0),
                      vertical: kIsWeb ? 0 : (isMobile ? 4.h : 0),
                    ),
                    title: Text(
                      'Permitir entrega tardía',
                      style: TextStyle(fontSize: kIsWeb ? 15 : (isMobile ? 14.sp : 15)),
                    ),
                    value: _permiteEntregaTardia,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _permiteEntregaTardia = value);
                    },
                  ),
                ),

                if (_permiteEntregaTardia) ...[
                  SizedBox(height: kIsWeb ? 8 : (isMobile ? 10.h : 8)),
                  isMobile
                      ? Column(
                          children: [
                            TextFormField(
                              controller: _penalizacionController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 14.sp),
                              decoration: InputDecoration(
                                labelText: 'Penalización/día',
                                labelStyle: TextStyle(fontSize: 13.sp),
                                border: const OutlineInputBorder(),
                                suffixText: 'pts',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            TextFormField(
                              controller: _toleranciaController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 14.sp),
                              decoration: InputDecoration(
                                labelText: 'Días tolerancia',
                                labelStyle: TextStyle(fontSize: 13.sp),
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _penalizacionController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Penalización/día',
                                  border: OutlineInputBorder(),
                                  suffixText: 'pts',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _toleranciaController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Días tolerancia',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
                SizedBox(height: kIsWeb ? 0 : (isMobile ? 8.h : 0)),
              ],
            ),
          ),
        ),
      ),

      // Botones de acción
      actions: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            kIsWeb ? 24 : (isMobile ? 16.w : 24),
            kIsWeb ? 8 : (isMobile ? 0 : 8),
            kIsWeb ? 24 : (isMobile ? 16.w : 24),
            kIsWeb ? 20 : (isMobile ? 16.h : 20),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF455A64),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Crear',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    SizedBox(height: 10.h),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 14.h,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 15.sp),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF455A64),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Crear',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}