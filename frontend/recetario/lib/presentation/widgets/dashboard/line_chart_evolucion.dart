import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:recetario/data/models/dashboard_stats.dart';

class LineChartEvolucion extends StatelessWidget {
  final List<EvolucionMatriculas> evolucionMatriculas;

  const LineChartEvolucion({
    Key? key,
    required this.evolucionMatriculas,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (evolucionMatriculas.isEmpty) {
      return _buildEmptyCard();
    }

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
                    color: const Color(0xFF5C2D91).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF5C2D91),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Evolución de Matrículas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                // Badge tendencia
                _buildTrendBadge(),
              ],
            ),
            const SizedBox(height: 20),
            // Gráfico
            SizedBox(
              height: 280,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
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
                  format: 'point.x: point.y matrículas',
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                series: <CartesianSeries>[
                  // Línea
                  LineSeries<EvolucionMatriculas, String>(
                    dataSource: evolucionMatriculas,
                    xValueMapper: (data, _) => data.cicloNombre,
                    yValueMapper: (data, _) => data.cantidad,
                    color: const Color(0xFF5C2D91),
                    width: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      height: 8,
                      width: 8,
                      color: Color(0xFF5C2D91),
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      labelAlignment: ChartDataLabelAlignment.top,
                      offset: Offset(0, -8),
                    ),
                  ),
                  // Área bajo la línea
                  SplineAreaSeries<EvolucionMatriculas, String>(
                    dataSource: evolucionMatriculas,
                    xValueMapper: (data, _) => data.cicloNombre,
                    yValueMapper: (data, _) => data.cantidad,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5C2D91).withOpacity(0.3),
                        const Color(0xFF5C2D91).withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderWidth: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    if (evolucionMatriculas.length < 2) {
      return const SizedBox.shrink();
    }

    final first = evolucionMatriculas.first.cantidad;
    final last = evolucionMatriculas.last.cantidad;
    final change = last - first;
    final isPositive = change > 0;
    final percentage = first > 0 ? ((change / first) * 100).abs() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF107C10).withOpacity(0.08)
            : const Color(0xFFE81123).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPositive
              ? const Color(0xFF107C10).withOpacity(0.3)
              : const Color(0xFFE81123).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: isPositive
                ? const Color(0xFF107C10)
                : const Color(0xFFE81123),
          ),
          const SizedBox(width: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPositive
                  ? const Color(0xFF107C10)
                  : const Color(0xFFE81123),
            ),
          ),
        ],
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
                Icons.trending_up,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay datos de evolución',
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
}