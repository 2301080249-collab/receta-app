import 'package:flutter/material.dart';
import 'package:recetario/data/models/ciclo.dart';

class CicloSelectorCard extends StatelessWidget {
  final List<Ciclo> ciclos;
  final String? cicloIdSeleccionado;
  final Function(String) onCicloChanged;

  const CicloSelectorCard({
    Key? key,
    required this.ciclos,
    required this.cicloIdSeleccionado,
    required this.onCicloChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ciclos.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    final cicloSeleccionado = cicloIdSeleccionado != null
        ? ciclos.firstWhere(
            (c) => c.id == cicloIdSeleccionado,
            orElse: () => ciclos.first,
          )
        : null;

    if (isMobile) {
      return _buildMobileLayout(cicloSeleccionado);
    } else if (isTablet) {
      return _buildTabletLayout(cicloSeleccionado);
    } else {
      return _buildDesktopLayout(cicloSeleccionado);
    }
  }

  // ✅ LAYOUT MÓVIL: Todo apilado verticalmente
  Widget _buildMobileLayout(Ciclo? cicloSeleccionado) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0078D4).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF0078D4),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Ciclo Académico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButton<String>(
              value: cicloIdSeleccionado,
              hint: const Text(
                'Seleccionar ciclo',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              isExpanded: true,
              isDense: true,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.expand_more,
                size: 18,
                color: Color(0xFF666666),
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              dropdownColor: Colors.white,
              items: ciclos.map((ciclo) {
                return DropdownMenuItem(
                  value: ciclo.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ciclo.nombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (ciclo.activo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF107C10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Activo',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? nuevoId) {
                if (nuevoId != null) {
                  onCicloChanged(nuevoId);
                }
              },
            ),
          ),
          // Info adicional (debajo del dropdown)
          if (cicloSeleccionado != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: Color(0xFF666666),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${cicloSeleccionado.duracionSemanas} sem',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.date_range_outlined,
                          size: 14,
                          color: Color(0xFF666666),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _formatearRangoFechas(
                              cicloSeleccionado.fechaInicio,
                              cicloSeleccionado.fechaFin,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ✅ LAYOUT TABLET: Híbrido
  Widget _buildTabletLayout(Ciclo? cicloSeleccionado) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Primera fila: Icono + Label + Dropdown
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0078D4).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 19,
                  color: Color(0xFF0078D4),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ciclo Académico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButton<String>(
                    value: cicloIdSeleccionado,
                    hint: const Text(
                      'Seleccionar ciclo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    isExpanded: true,
                    isDense: true,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.expand_more,
                      size: 19,
                      color: Color(0xFF666666),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    dropdownColor: Colors.white,
                    items: ciclos.map((ciclo) {
                      return DropdownMenuItem(
                        value: ciclo.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ciclo.nombre,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (ciclo.activo)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF107C10),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Activo',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? nuevoId) {
                      if (nuevoId != null) {
                        onCicloChanged(nuevoId);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          // Segunda fila: Info adicional
          if (cicloSeleccionado != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 15,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${cicloSeleccionado.duracionSemanas} sem',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.date_range_outlined,
                        size: 15,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatearRangoFechas(
                          cicloSeleccionado.fechaInicio,
                          cicloSeleccionado.fechaFin,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ✅ LAYOUT DESKTOP: Original (todo en una fila)
  Widget _buildDesktopLayout(Ciclo? cicloSeleccionado) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0078D4).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Color(0xFF0078D4),
            ),
          ),
          const SizedBox(width: 16),
          // Label
          const Text(
            'Ciclo Académico',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 20),
          // Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButton<String>(
                value: cicloIdSeleccionado,
                hint: const Text(
                  'Seleccionar ciclo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                isExpanded: true,
                isDense: true,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.expand_more,
                  size: 20,
                  color: Color(0xFF666666),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                dropdownColor: Colors.white,
                items: ciclos.map((ciclo) {
                  return DropdownMenuItem(
                    value: ciclo.id,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ciclo.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (ciclo.activo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF107C10),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Activo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? nuevoId) {
                  if (nuevoId != null) {
                    onCicloChanged(nuevoId);
                  }
                },
              ),
            ),
          ),
          // Info adicional
          if (cicloSeleccionado != null) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cicloSeleccionado.duracionSemanas} sem',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.date_range_outlined,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatearRangoFechas(
                      cicloSeleccionado.fechaInicio,
                      cicloSeleccionado.fechaFin,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatearRangoFechas(String fechaInicio, String fechaFin) {
    final inicio = _formatearFecha(fechaInicio);
    final fin = _formatearFecha(fechaFin);
    return '$inicio - $fin';
  }

  String _formatearFecha(String fecha) {
    final partes = fecha.split('-');
    if (partes.length == 3) {
      return '${partes[2]}/${partes[1]}';
    }
    return fecha;
  }
}