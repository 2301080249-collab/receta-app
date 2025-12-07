import 'package:flutter/material.dart';
import 'package:recetario/data/models/dashboard_stats.dart';

class BarChartDocentes extends StatelessWidget {
  final List<DocenteCursos> docentesCursos;

  const BarChartDocentes({
    Key? key,
    required this.docentesCursos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tomar top 5 docentes
    final top5 = [...docentesCursos].take(5).toList();

    if (top5.isEmpty) {
      return _buildEmpty();
    }

    final maxCursos = top5.first.totalCursos.toDouble();

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50, // ✅ CAMBIADO
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.blue.shade700, // ✅ CAMBIADO
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Carga de Trabajo Docente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50, // ✅ CAMBIADO
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Top 5',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700, // ✅ CAMBIADO
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...top5.asMap().entries.map((entry) {
              final index = entry.key;
              final docente = entry.value;
              final porcentaje = (docente.totalCursos / maxCursos);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < top5.length - 1 ? 16 : 0,
                ),
                child: _buildDocenteBar(
                  docente: docente,
                  porcentaje: porcentaje,
                  index: index,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocenteBar({
    required DocenteCursos docente,
    required double porcentaje,
    required int index,
  }) {
    // ✅ CAMBIADO: Paleta de azules
    final colors = [
      Colors.blue.shade700,
      Colors.blue.shade600,
      Colors.blue.shade500,
      Colors.blue.shade400,
      Colors.blue.shade300,
    ];
    final color = colors[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Ranking badge
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nombre del docente
            Expanded(
              child: Text(
                docente.docenteNombre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Cantidad de cursos
            Text(
              '${docente.totalCursos} ${docente.totalCursos == 1 ? 'curso' : 'cursos'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra de progreso
        Stack(
          children: [
            // Fondo
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Barra coloreada
            FractionallySizedBox(
              widthFactor: porcentaje,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Info adicional
        Text(
          '${docente.totalEstudiantes} estudiantes',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No hay datos de docentes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}