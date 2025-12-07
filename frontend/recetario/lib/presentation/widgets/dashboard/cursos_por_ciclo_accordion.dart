import 'package:flutter/material.dart';
import 'package:recetario/data/models/cursos_por_ciclo.dart';

class CursosPorCicloAccordion extends StatefulWidget {
  final List<CursosPorCiclo> cursosPorCiclo;

  const CursosPorCicloAccordion({
    Key? key,
    required this.cursosPorCiclo,
  }) : super(key: key);

  @override
  State<CursosPorCicloAccordion> createState() =>
      _CursosPorCicloAccordionState();
}

class _CursosPorCicloAccordionState extends State<CursosPorCicloAccordion> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.cursosPorCiclo.isEmpty) {
      return _buildEmptyState();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 900 ? 500 : double.infinity,
      ),
      child: Card(
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header estilo Power BI
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Color(0xFFFF8C00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cursos por Ciclo Académico',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  // Badge total cursos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          size: 16,
                          color: Color(0xFFFF8C00),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_calcularTotalCursos()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'cursos',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 16),
              // Acordeón
              ...widget.cursosPorCiclo.asMap().entries.map((entry) {
                final index = entry.key;
                final ciclo = entry.value;
                final isExpanded = _expandedIndex == index;

                return _buildCicloCard(ciclo, index, isExpanded);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCicloCard(CursosPorCiclo ciclo, int index, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpanded 
              ? const Color(0xFF0078D4).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header compacto
          InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: const Color(0xFF666666),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    ciclo.cicloLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isExpanded 
                          ? const Color(0xFF0078D4)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  // Badge cursos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0078D4).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${ciclo.totalCursos}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0078D4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge alumnos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF107C10).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 12,
                          color: Color(0xFF107C10),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ciclo.totalAlumnos}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF107C10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lista de cursos
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: ciclo.cursos.map((curso) {
                  return _buildCursoItem(curso);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCursoItem(CursoDetalle curso) {
    final isLowEnrollment = curso.alumnos < 15;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Punto indicador
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isLowEnrollment 
                  ? const Color(0xFFFF8C00)
                  : const Color(0xFF0078D4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Info del curso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curso.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (curso.docenteNombre != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 12,
                        color: Color(0xFF999999),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          curso.docenteNombre!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Badge alumnos con warning
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLowEnrollment
                      ? const Color(0xFFFF8C00).withOpacity(0.08)
                      : const Color(0xFF0078D4).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isLowEnrollment
                        ? const Color(0xFFFF8C00).withOpacity(0.3)
                        : const Color(0xFF0078D4).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: isLowEnrollment
                          ? const Color(0xFFFF8C00)
                          : const Color(0xFF0078D4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${curso.alumnos}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isLowEnrollment
                            ? const Color(0xFFFF8C00)
                            : const Color(0xFF0078D4),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLowEnrollment) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Baja matrícula',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: const Color(0xFFFF8C00),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay cursos disponibles',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calcularTotalCursos() {
    return widget.cursosPorCiclo.fold(0, (sum, ciclo) => sum + ciclo.totalCursos);
  }
}