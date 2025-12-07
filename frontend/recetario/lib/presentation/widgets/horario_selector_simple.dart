import 'package:flutter/material.dart';

/// Selector de horario simple con días y horas
class HorarioSelector extends StatefulWidget {
  final TextEditingController controller;
  final String? label;

  const HorarioSelector({
    Key? key,
    required this.controller,
    this.label = 'Horario',
  }) : super(key: key);

  @override
  State<HorarioSelector> createState() => _HorarioSelectorState();
}

class _HorarioSelectorState extends State<HorarioSelector> {
  final List<String> _diasSeleccionados = [];
  String? _horaInicio;
  String? _periodoInicio = 'am';
  String? _horaFin;
  String? _periodoFin = 'pm';

  final List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  
  // ✅ Bloques de 45 minutos SIN DUPLICADOS (eliminado 8:00 PM del final)
  final List<String> _horas = [
    '8:00', '8:45', '9:30', '10:15', '11:00', '11:45',
    '12:30', '1:15', '2:00', '2:45', '3:30', '4:15',
    '5:00', '5:45', '6:30', '7:15'
  ];

  bool _yaParseo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.text.isNotEmpty && !_yaParseo) {
        _parsearHorarioInicial();
        _yaParseo = true;
      }
    });
  }

  void _parsearHorarioInicial() {
    final texto = widget.controller.text.trim();
    if (texto.isEmpty) return;

    try {
      final partes = texto.split(' ');
      if (partes.isEmpty) return;

      // Parsear días
      final diasTexto = partes[0];
      final diasArray = diasTexto.split('-');
      
      for (var dia in diasArray) {
        final diaLimpio = dia.trim();
        for (var diaDisponible in _dias) {
          if (_compararDias(diaLimpio, diaDisponible)) {
            if (!_diasSeleccionados.contains(diaDisponible)) {
              _diasSeleccionados.add(diaDisponible);
            }
            break;
          }
        }
      }

      // Parsear horas
      if (partes.length > 1) {
        final horasTexto = partes.sublist(1).join(' ');
        
        final regexHoras = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)\s*[-–]\s*(\d{1,2}):(\d{2})\s*(am|pm)', 
            caseSensitive: false);
        
        final match = regexHoras.firstMatch(horasTexto);
        
        if (match != null) {
          String horaInicioStr = match.group(1)!;
          String minutosInicioStr = match.group(2)!;
          String horaFinStr = match.group(4)!;
          String minutosFinStr = match.group(5)!;
          
          int horaInicioNum = int.parse(horaInicioStr);
          int horaFinNum = int.parse(horaFinStr);
          
          _horaInicio = '$horaInicioNum:$minutosInicioStr';
          _periodoInicio = match.group(3)?.toLowerCase();
          _horaFin = '$horaFinNum:$minutosFinStr';
          _periodoFin = match.group(6)?.toLowerCase();
          
          if (!_horas.contains(_horaInicio)) {
            print('⚠️ Hora inicio "$_horaInicio" no está en la lista');
            _horaInicio = null;
          }
          
          if (!_horas.contains(_horaFin)) {
            print('⚠️ Hora fin "$_horaFin" no está en la lista');
            _horaFin = null;
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Error parseando horario: $e');
    }
  }

  bool _compararDias(String dia1, String dia2) {
    final d1 = dia1.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    
    final d2 = dia2.toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    
    return d1 == d2;
  }

  void _actualizarHorario() {
    if (_diasSeleccionados.isEmpty || _horaInicio == null || _horaFin == null) {
      widget.controller.text = '';
      return;
    }

    final dias = _diasSeleccionados.join('-');
    final inicio = '$_horaInicio$_periodoInicio';
    final fin = '$_horaFin$_periodoFin';
    
    widget.controller.text = '$dias $inicio-$fin';
  }

  void _toggleDia(String dia) {
    setState(() {
      if (_diasSeleccionados.contains(dia)) {
        _diasSeleccionados.remove(dia);
      } else {
        _diasSeleccionados.add(dia);
      }
      _actualizarHorario();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              widget.label ?? 'Horario',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bloques de 45 minutos • 8:00 AM - 7:15 PM',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Días de clase',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dias.map((dia) {
            final isSelected = _diasSeleccionados.contains(dia);
            return FilterChip(
              label: Text(
                dia.substring(0, 3),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _toggleDia(dia),
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue[700],
              backgroundColor: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora inicio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _horaInicio,
                          hint: const Text('8:00', style: TextStyle(fontSize: 13)),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _horas.map((h) => DropdownMenuItem(
                            value: h,
                            child: Text(h, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _horaInicio = val;
                              _actualizarHorario();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _periodoInicio,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'am', child: Text('AM', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'pm', child: Text('PM', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _periodoInicio = val;
                              _actualizarHorario();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora fin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _horaFin,
                          hint: const Text('12:30', style: TextStyle(fontSize: 13)),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _horas.map((h) => DropdownMenuItem(
                            value: h,
                            child: Text(h, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _horaFin = val;
                              _actualizarHorario();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _periodoFin,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'am', child: Text('AM', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'pm', child: Text('PM', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _periodoFin = val;
                              _actualizarHorario();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (widget.controller.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.controller.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
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