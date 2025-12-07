import 'package:flutter/material.dart';
import '../../../data/models/ciclo.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/usuario.dart';

/// Dropdown especializado para seleccionar Ciclos Académicos
class CicloDropdownField extends StatelessWidget {
  final List<Ciclo> ciclos;
  final Ciclo? value;
  final ValueChanged<Ciclo?> onChanged;
  final String? label;
  final String? helperText;
  final bool isRequired;

  const CicloDropdownField({
    Key? key,
    required this.ciclos,
    required this.value,
    required this.onChanged,
    this.label = 'Ciclo Académico',
    this.helperText = '¿En qué periodo se dicta?',
    this.isRequired = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Ciclo>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        helperText: helperText,
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      items: ciclos.map((ciclo) {
        return DropdownMenuItem(
          value: ciclo,
          child: Text('${ciclo.nombre} ${ciclo.activo ? "✓ (Activo)" : ""}'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => value == null ? 'Requerido' : null
          : null,
    );
  }
}

/// Dropdown especializado para seleccionar Estudiantes
class EstudianteDropdownField extends StatelessWidget {
  final List<Usuario> estudiantes;
  final Usuario? value;
  final ValueChanged<Usuario?> onChanged;
  final String? label;
  final bool isRequired;
  final bool showEmptyWarning;

  const EstudianteDropdownField({
    Key? key,
    required this.estudiantes,
    required this.value,
    required this.onChanged,
    this.label = 'Estudiante',
    this.isRequired = true,
    this.showEmptyWarning = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (estudiantes.isEmpty && showEmptyWarning) {
      return _WarningMessage(
        message: 'No hay estudiantes registrados en el sistema',
      );
    }

    return DropdownButtonFormField<Usuario>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: const Icon(Icons.person),
        border: const OutlineInputBorder(),
      ),
      items: estudiantes.map((estudiante) {
        return DropdownMenuItem(
          value: estudiante,
          child: Text('${estudiante.nombreCompleto} (${estudiante.codigo})'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => value == null ? 'Requerido' : null
          : null,
    );
  }
}

/// Dropdown especializado para seleccionar Cursos (con filtro por ciclo)
class CursoDropdownField extends StatelessWidget {
  final List<Curso> cursos;
  final Curso? value;
  final ValueChanged<Curso?> onChanged;
  final String? cicloId; // Para filtrar cursos por ciclo
  final String? label;
  final bool isRequired;
  final bool showEmptyWarning;

  const CursoDropdownField({
    Key? key,
    required this.cursos,
    required this.value,
    required this.onChanged,
    this.cicloId,
    this.label = 'Curso',
    this.isRequired = true,
    this.showEmptyWarning = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtrar cursos por ciclo si se proporciona
    final cursosFiltrados = cicloId != null
        ? cursos.where((c) => c.cicloId == cicloId).toList()
        : cursos;

    if (cursosFiltrados.isEmpty && showEmptyWarning) {
      return _WarningMessage(
        message: cicloId != null
            ? 'No hay cursos disponibles para el ciclo seleccionado'
            : 'No hay cursos disponibles',
      );
    }

    return DropdownButtonFormField<Curso>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: const Icon(Icons.book),
        border: const OutlineInputBorder(),
      ),
      items: cursosFiltrados.map((curso) {
        return DropdownMenuItem(
          value: curso,
          child: Text(
            '${curso.nombre}${curso.seccion != null ? ' - Sección ${curso.seccion}' : ''}',
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => value == null ? 'Requerido' : null
          : null,
    );
  }
}

/// Dropdown especializado para seleccionar Docentes
class DocenteDropdownField extends StatelessWidget {
  final List<Map<String, String>> docentes;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? label;
  final bool isRequired;
  final bool isLoading;

  const DocenteDropdownField({
    Key? key,
    required this.docentes,
    required this.value,
    required this.onChanged,
    this.label = 'Docente',
    this.isRequired = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: const Icon(Icons.person),
        border: const OutlineInputBorder(),
      ),
      items: docentes.map((docente) {
        return DropdownMenuItem<String>(
          value: docente['id'],
          child: Text(docente['nombre_completo']!),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => value == null ? 'Requerido' : null
          : null,
    );
  }
}

/// Widget para mostrar mensajes de advertencia (lista vacía, sin datos, etc.)
class _WarningMessage extends StatelessWidget {
  final String message;

  const _WarningMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown para seleccionar nivel de curso (Ciclo I-X)
class NivelCursoDropdownField extends StatelessWidget {
  final int value;
  final ValueChanged<int?> onChanged;
  final String? label;
  final String? helperText;

  const NivelCursoDropdownField({
    Key? key,
    required this.value,
    required this.onChanged,
    this.label = 'Nivel del Curso',
    this.helperText = '¿Para qué ciclo es?',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: '$label *',
        helperText: helperText,
        prefixIcon: const Icon(Icons.stairs),
        border: const OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 1, child: Text('Ciclo I')),
        DropdownMenuItem(value: 2, child: Text('Ciclo II')),
        DropdownMenuItem(value: 3, child: Text('Ciclo III')),
        DropdownMenuItem(value: 4, child: Text('Ciclo IV')),
        DropdownMenuItem(value: 5, child: Text('Ciclo V')),
        DropdownMenuItem(value: 6, child: Text('Ciclo VI')),
      ],
      onChanged: onChanged,
    );
  }
}

/// Dropdown para estado de matrícula
class EstadoMatriculaDropdownField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final String? label;

  const EstadoMatriculaDropdownField({
    Key? key,
    required this.value,
    required this.onChanged,
    this.label = 'Estado',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.info),
      ),
      items: const [
        DropdownMenuItem(value: 'activo', child: Text('✅ Activo')),
        DropdownMenuItem(value: 'retirado', child: Text('⚠️ Retirado')),
        DropdownMenuItem(value: 'completado', child: Text('🎓 Completado')),
      ],
      onChanged: onChanged,
    );
  }
}
