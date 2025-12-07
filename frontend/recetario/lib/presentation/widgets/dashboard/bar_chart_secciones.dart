import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:recetario/data/models/dashboard_stats.dart';

class BarChartSecciones extends StatefulWidget {
  final List<EstudiantesPorSeccion> estudiantesPorSeccion;
  final int totalEstudiantes;

  const BarChartSecciones({
    Key? key,
    required this.estudiantesPorSeccion,
    required this.totalEstudiantes,
  }) : super(key: key);

  @override
  State<BarChartSecciones> createState() => _BarChartSeccionesState();
}

class _BarChartSeccionesState extends State<BarChartSecciones> {
  late int _cicloSeleccionado;
  final List<int> _ciclosDisponibles = [1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _cicloSeleccionado = _ciclosDisponibles.first;
  }

  @override
  Widget build(BuildContext context) {
    final seccionesData = _obtenerDatosPorCiclo(_cicloSeleccionado);
    final totalDelCiclo = seccionesData.fold<int>(0, (sum, item) => sum + item.cantidad);

    return Card(
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF107C10).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Color(0xFF107C10),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Estudiantes por sección',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                // Badge total
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
                        Icons.people_outline,
                        size: 16,
                        color: Color(0xFF0078D4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.totalEstudiantes}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'total',
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
            // Selector de ciclo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list_outlined,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _cicloSeleccionado,
                    underline: const SizedBox(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Color(0xFF666666),
                    ),
                    items: _ciclosDisponibles.map((ciclo) {
                      return DropdownMenuItem(
                        value: ciclo,
                        child: Text(_getCicloLabel(ciclo)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _cicloSeleccionado = value);
                      }
                    },
                  ),
                  const Spacer(),
                  // Total del ciclo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      '$totalDelCiclo estudiantes',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Gráfico
            SizedBox(
              height: 260,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                    letterSpacing: 0.5,
                  ),
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: seccionesData.isEmpty ? 5 : 
                    (seccionesData.map((e) => e.cantidad).reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                  interval: 1,
                  labelFormat: '{value}',
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF999999),
                  ),
                  majorGridLines: MajorGridLines(
                    width: 1,
                    color: const Color(0xFFF3F4F6),
                  ),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                ),
                plotAreaBorderWidth: 0,
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'Sección point.x: point.y estudiantes',
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                series: <CartesianSeries<_SeccionData, String>>[
                  ColumnSeries<_SeccionData, String>(
                    dataSource: seccionesData,
                    xValueMapper: (data, _) => data.seccion,
                    yValueMapper: (data, _) => data.cantidad,
                    pointColorMapper: (data, index) => _getSeccionColor(index!),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      labelAlignment: ChartDataLabelAlignment.top,
                      offset: Offset(0, -8),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    width: 0.6,
                    spacing: 0.2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SeccionData> _obtenerDatosPorCiclo(int ciclo) {
    final datos = widget.estudiantesPorSeccion
        .where((e) => e.ciclo == ciclo)
        .toList();

    final Map<String, int> seccionesMap = {
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
    };

    for (var item in datos) {
      seccionesMap[item.seccion] = item.cantidad;
    }

    return seccionesMap.entries
        .map((e) => _SeccionData(e.key, e.value))
        .toList()
      ..sort((a, b) => a.seccion.compareTo(b.seccion));
  }

  String _getCicloLabel(int ciclo) {
    const romanos = {
      1: 'I', 2: 'II', 3: 'III', 4: 'IV',
      5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII',
      9: 'IX', 10: 'X'
    };
    return 'Ciclo ${romanos[ciclo] ?? ciclo.toString()}';
  }

  // Paleta Power BI
  Color _getSeccionColor(int index) {
    final colors = [
      const Color(0xFF0078D4), // Azul
      const Color(0xFF107C10), // Verde
      const Color(0xFFFF8C00), // Naranja
      const Color(0xFF5C2D91), // Púrpura
    ];
    return colors[index % colors.length];
  }
}

class _SeccionData {
  final String seccion;
  final int cantidad;
  _SeccionData(this.seccion, this.cantidad);
}