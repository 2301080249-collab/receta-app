import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Campo especializado para ingresar notas (0-20)
class NotaField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool isRequired;

  const NotaField({
    Key? key,
    required this.controller,
    this.label = 'Nota Final',
    this.hint = 'Dejar vacío si aún no tiene nota',
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.grade),
        helperText: 'Entre 0 y 20',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (isRequired && (value?.isEmpty ?? true)) {
          return 'Requerido';
        }
        if (value != null && value.isNotEmpty) {
          final nota = double.tryParse(value);
          if (nota == null || nota < 0 || nota > 20) {
            return 'La nota debe estar entre 0 y 20';
          }
        }
        return null;
      },
    );
  }
}

/// Campo especializado para créditos (1-10)
class CreditosField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final bool isRequired;
  final int min;
  final int max;

  const CreditosField({
    Key? key,
    required this.controller,
    this.label = 'Créditos',
    this.isRequired = true,
    this.min = 1,
    this.max = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.star),
        helperText: '$min-$max créditos',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (isRequired && (value?.isEmpty ?? true)) {
          return 'Requerido';
        }
        if (value != null && value.isNotEmpty) {
          final num = int.tryParse(value);
          if (num == null || num < min || num > max) {
            return '$min-$max';
          }
        }
        return null;
      },
    );
  }
}

/// Campo especializado para duración en semanas
class DurationField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final bool isRequired;
  final int min;
  final int max;

  const DurationField({
    Key? key,
    required this.controller,
    this.label = 'Duración (semanas)',
    this.isRequired = true,
    this.min = 1,
    this.max = 52,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.access_time),
        helperText: 'Entre $min y $max semanas',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (isRequired && (value?.isEmpty ?? true)) {
          return 'Requerido';
        }
        if (value != null && value.isNotEmpty) {
          final num = int.tryParse(value);
          if (num == null || num < min || num > max) {
            return 'Debe ser entre $min y $max';
          }
        }
        return null;
      },
    );
  }
}

/// Widget para seleccionar un rango de fechas (inicio y fin)
class DateRangePickerField extends StatelessWidget {
  final String labelStart;
  final String labelEnd;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateRangePickerField({
    Key? key,
    required this.labelStart,
    required this.labelEnd,
    required this.dateStart,
    required this.dateEnd,
    required this.onStartChanged,
    required this.onEndChanged,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  Future<void> _selectDate(
    BuildContext context,
    bool isStart,
  ) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
    );

    if (fecha != null) {
      if (isStart) {
        onStartChanged(fecha);
      } else {
        onEndChanged(fecha);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(context, true),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              dateStart == null
                  ? labelStart
                  : DateFormat('dd/MM/yyyy').format(dateStart!),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(context, false),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              dateEnd == null
                  ? labelEnd
                  : DateFormat('dd/MM/yyyy').format(dateEnd!),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo especializado para sección (A, B, C)
class SeccionField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;

  const SeccionField({
    Key? key,
    required this.controller,
    this.label = 'Sección',
    this.hint = 'A, B, C...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: 'Grupo del curso',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.group),
      ),
      textCapitalization: TextCapitalization.characters,
      maxLength: 2,
    );
  }
}

/// Campo especializado para horario
class HorarioField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;

  const HorarioField({
    Key? key,
    required this.controller,
    this.label = 'Horario',
    this.hint = 'Lun-Mie 8-10am',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.access_time),
      ),
    );
  }
}