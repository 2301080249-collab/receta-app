import 'package:flutter/material.dart';
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

      await _tareaRepository.crearTarea(tarea);

      if (mounted) {
        Navigator.pop(context);
        widget.onTareaCreada();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea creada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear tarea: $e')),
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
    // ✅ Detectar tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return AlertDialog(
      // ✅ Padding responsivo
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      contentPadding: EdgeInsets.zero,

      title: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 16 : 20,
          isMobile ? 16 : 24,
          isMobile ? 8 : 12,
        ),
        child: Text(
          'Crear Nueva Tarea',
          style: TextStyle(fontSize: isMobile ? 18 : 20),
        ),
      ),

      content: Container(
        // ✅ Ancho máximo adaptativo
        width: isMobile ? screenWidth * 0.9 : 550,
        constraints: BoxConstraints(
          maxHeight: screenHeight * (isMobile ? 0.75 : 0.8),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 8 : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Título
                TextFormField(
                  controller: _tituloController,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Título de la tarea *',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    hintText: 'Ej: Pan artesanal',
                    hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.assignment,
                      size: isMobile ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El título es obligatorio';
                    }
                    return null;
                  },
                ),

                SizedBox(height: isMobile ? 12 : 16),

                // ✅ Descripción
                TextFormField(
                  controller: _descripcionController,
                  maxLines: isMobile ? 2 : 3,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Instrucciones (Opcional)',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    hintText: 'Describe lo que deben hacer los estudiantes...',
                    hintStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                ),

                SizedBox(height: isMobile ? 12 : 16),

                // ✅ Tipo de tarea
                Text(
                  'Tipo de tarea',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Wrap(
                  spacing: isMobile ? 6 : 8,
                  runSpacing: isMobile ? 6 : 8,
                  children: _tipos.entries.map((entry) {
                    return ChoiceChip(
                      label: Text(
                        entry.value,
                        style: TextStyle(fontSize: isMobile ? 13 : 14),
                      ),
                      selected: _tipoSeleccionado == entry.key,
                      selectedColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 4 : 8,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _tipoSeleccionado = entry.key);
                        }
                      },
                    );
                  }).toList(),
                ),

                SizedBox(height: isMobile ? 12 : 16),

                // ✅ Fecha límite
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isMobile ? 20 : 24,
                            color: Colors.grey[700],
                          ),
                          SizedBox(width: isMobile ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha límite',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_fechaLimite.day}/${_fechaLimite.month}/${_fechaLimite.year} a las ${_fechaLimite.hour}:${_fechaLimite.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: isMobile ? 18 : 20,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isMobile ? 12 : 16),
                if (!isMobile) const Divider(),
                if (!isMobile) const SizedBox(height: 8),

                // ✅ Puntaje máximo
                TextFormField(
                  controller: _puntajeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Puntaje máximo',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.stars,
                      size: isMobile ? 20 : 24,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
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

                SizedBox(height: isMobile ? 12 : 16),

                // ✅ Switch entrega tardía
                Container(
                  decoration: isMobile
                      ? BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 0,
                      vertical: isMobile ? 4 : 0,
                    ),
                    title: Text(
                      'Permitir entrega tardía',
                      style: TextStyle(fontSize: isMobile ? 14 : 15),
                    ),
                    value: _permiteEntregaTardia,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _permiteEntregaTardia = value);
                    },
                  ),
                ),

                if (_permiteEntregaTardia) ...[
                  SizedBox(height: isMobile ? 10 : 8),
                  // ✅ Campos penalización y tolerancia responsivos
                  isMobile
                      ? Column(
                          children: [
                            TextFormField(
                              controller: _penalizacionController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Penalización/día',
                                labelStyle: TextStyle(fontSize: 13),
                                border: OutlineInputBorder(),
                                suffixText: 'pts',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _toleranciaController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                labelText: 'Días tolerancia',
                                labelStyle: TextStyle(fontSize: 13),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
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
                SizedBox(height: isMobile ? 8 : 0),
              ],
            ),
          ),
        ),
      ),

      // ✅ Botones de acción responsivos
      actions: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 0 : 8,
            isMobile ? 16 : 24,
            isMobile ? 16 : 20,
          ),
          child: isMobile
              // 📱 MÓVIL: Botones verticales
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              'Crear',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                )
              // 💻 DESKTOP: Botones horizontales
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _guardar,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}