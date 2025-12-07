import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:recetario/data/models/dashboard_stats.dart';

class DonutChartCiclos extends StatelessWidget {
  final List<EstudiantesPorCiclo> estudiantesPorCiclo;

  const DonutChartCiclos({
    Key? key,
    required this.estudiantesPorCiclo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (estudiantesPorCiclo.isEmpty) {
      return _buildEmptyCard();
    }

    final ciclosData = _completarCiclos(estudiantesPorCiclo);
    final totalEstudiantes = ciclosData.fold<int>(
      0, 
      (sum, item) => sum + item.cantidad,
    );

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
            // Header estilo Power BI
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0078D4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline,
                    color: Color(0xFF0078D4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Alumnos por ciclo',
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
                        '$totalEstudiantes',
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
            // Gráfico
            SizedBox(
              height: 280,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.right,
                  overflowMode: LegendItemOverflowMode.wrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                  itemPadding: 8,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                series: <CircularSeries>[
                  DoughnutSeries<EstudiantesPorCiclo, String>(
                    dataSource: ciclosData,
                    xValueMapper: (data, _) => data.cicloLabel,
                    yValueMapper: (data, _) => data.cantidad,
                    dataLabelMapper: (data, _) {
                      if (data.cantidad > 0) {
                        return '${data.porcentaje.toStringAsFixed(1)}%';
                      }
                      return '';
                    },
                    pointColorMapper: (data, index) => _getCicloColor(index!),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '10%',
                        width: 1,
                      ),
                    ),
                    innerRadius: '65%',
                    explode: false,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
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
                Icons.info_outline,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay datos de estudiantes por ciclo',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<EstudiantesPorCiclo> _completarCiclos(List<EstudiantesPorCiclo> datos) {
    final ciclosRomanos = ['I', 'II', 'III', 'IV', 'V', 'VI'];
    final resultado = <EstudiantesPorCiclo>[];

    for (int i = 1; i <= 6; i++) {
      final existe = datos.firstWhere(
        (d) => d.ciclo == i,
        orElse: () => EstudiantesPorCiclo(
          ciclo: i,
          cicloLabel: 'Ciclo ${ciclosRomanos[i - 1]}',
          cantidad: 0,
          porcentaje: 0,
        ),
      );
      resultado.add(existe);
    }

    return resultado;
  }

  // Paleta Power BI profesional
  Color _getCicloColor(int index) {
    final colors = [
      const Color(0xFF0078D4), // Azul Microsoft
      const Color(0xFF107C10), // Verde
      const Color(0xFFFF8C00), // Naranja
      const Color(0xFF5C2D91), // Púrpura
      const Color(0xFFE81123), // Rojo
      const Color(0xFF008272), // Teal
    ];
    return colors[index % colors.length];
  }
}