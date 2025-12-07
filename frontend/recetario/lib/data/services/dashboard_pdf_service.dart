import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recetario/data/models/dashboard_stats.dart';

class DashboardPdfService {
  /// Genera y descarga el PDF del dashboard
  static Future<void> exportarDashboard({
    required DashboardStats stats,
    required String cicloNombre,
  }) async {
    final pdf = pw.Document();

    // Crear el PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(cicloNombre),
          pw.SizedBox(height: 24),
          _buildKPIs(stats),
          pw.SizedBox(height: 24),
          _buildEstudiantesPorCiclo(stats),
          pw.SizedBox(height: 24),
          _buildEstudiantesPorSeccion(stats),
          pw.SizedBox(height: 24),
          _buildCursosPorCiclo(stats),
          pw.SizedBox(height: 24),
          // ✅ NUEVO: Evolución de Matrículas
          _buildEvolucionMatriculas(stats),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    // Descargar o imprimir
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Dashboard_${cicloNombre}_${DateTime.now().toString().substring(0, 10)}.pdf',
    );
  }

  /// Header del PDF
  static pw.Widget _buildHeader(String cicloNombre) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Dashboard Analytics',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Ciclo Academico: $cicloNombre',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Fecha de generacion: ${DateTime.now().toString().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// KPIs en formato de tarjetas (ahora incluye Ciclos)
  static pw.Widget _buildKPIs(DashboardStats stats) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Indicadores Clave',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildKpiCard('Estudiantes', stats.totalEstudiantes, PdfColors.blue),
            _buildKpiCard('Docentes', stats.totalDocentes, PdfColors.green),
            _buildKpiCard('Cursos', stats.totalCursos, PdfColors.orange),
            _buildKpiCard('Matriculas', stats.totalMatriculas, PdfColors.purple),
          ],
        ),
        pw.SizedBox(height: 8),
        // ✅ Segunda fila con Ciclos centrado
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildKpiCard('Ciclos', stats.totalCiclos, PdfColors.teal),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildKpiCard(String title, int value, PdfColor color) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: color.shade(0.8),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value.toString(),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Tabla: Estudiantes por ciclo
  static pw.Widget _buildEstudiantesPorCiclo(DashboardStats stats) {
    if (stats.estudiantesPorCiclo.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Alumnos por Ciclo',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Ciclo', isHeader: true),
                _buildTableCell('Cantidad', isHeader: true),
                _buildTableCell('Porcentaje', isHeader: true),
              ],
            ),
            // Datos
            ...stats.estudiantesPorCiclo.map((item) {
              return pw.TableRow(
                children: [
                  _buildTableCell(item.cicloLabel),
                  _buildTableCell(item.cantidad.toString()),
                  _buildTableCell('${item.porcentaje.toStringAsFixed(1)}%'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Tabla: Estudiantes por sección
  static pw.Widget _buildEstudiantesPorSeccion(DashboardStats stats) {
    if (stats.estudiantesPorSeccion.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Estudiantes por Seccion',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Ciclo', isHeader: true),
                _buildTableCell('Seccion', isHeader: true),
                _buildTableCell('Cantidad', isHeader: true),
              ],
            ),
            // Datos
            ...stats.estudiantesPorSeccion.map((item) {
              return pw.TableRow(
                children: [
                  _buildTableCell('Ciclo ${_getCicloRomano(item.ciclo)}'),
                  _buildTableCell(item.seccion),
                  _buildTableCell(item.cantidad.toString()),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Tabla: Cursos por ciclo
  static pw.Widget _buildCursosPorCiclo(DashboardStats stats) {
    if (stats.cursosPorCiclo.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cursos por Ciclo Academico',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...stats.cursosPorCiclo.map((cicloData) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.orange50,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      cicloData.cicloLabel,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${cicloData.totalCursos} cursos - ${cicloData.totalAlumnos} alumnos',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('Curso', isHeader: true, fontSize: 9),
                      _buildTableCell('Docente', isHeader: true, fontSize: 9),
                      _buildTableCell('Alumnos', isHeader: true, fontSize: 9),
                    ],
                  ),
                  ...cicloData.cursos.map((curso) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(curso.nombre, fontSize: 8),
                        _buildTableCell(curso.docenteNombre ?? 'Sin docente', fontSize: 8),
                        _buildTableCell(curso.alumnos.toString(), fontSize: 8),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  /// ✅ NUEVO: Tabla de Evolución de Matrículas
  static pw.Widget _buildEvolucionMatriculas(DashboardStats stats) {
    if (stats.evolucionMatriculas.isEmpty) {
      return pw.SizedBox();
    }

    // Calcular tendencia
    final primerValor = stats.evolucionMatriculas.first.cantidad;
    final ultimoValor = stats.evolucionMatriculas.last.cantidad;
    final diferencia = ultimoValor - primerValor;
    final porcentajeCambio = primerValor > 0 
        ? ((diferencia / primerValor) * 100).toStringAsFixed(1)
        : '0.0';
    final tendencia = diferencia > 0 
        ? '↗ Crecimiento' 
        : diferencia < 0 
            ? '↘ Decrecimiento' 
            : '→ Estable';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Evolucion de Matriculas',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: diferencia >= 0 ? PdfColors.green50 : PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(
                  color: diferencia >= 0 ? PdfColors.green : PdfColors.red,
                ),
              ),
              child: pw.Text(
                '$tendencia $porcentajeCambio%',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: diferencia >= 0 ? PdfColors.green900 : PdfColors.red900,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Ciclo Academico', isHeader: true),
                _buildTableCell('Matriculas', isHeader: true),
              ],
            ),
            // Datos
            ...stats.evolucionMatriculas.map((item) {
              return pw.TableRow(
                children: [
                 _buildTableCell(item.cicloNombre), 
                  _buildTableCell(item.cantidad.toString()),
                ],
              );
            }),
            // Total
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('TOTAL', isHeader: true),
                _buildTableCell(
                  stats.evolucionMatriculas
                      .fold<int>(0, (sum, item) => sum + item.cantidad)
                      .toString(),
                  isHeader: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Celda de tabla
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Footer del PDF
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        'Sistema de Gestion Academica - Generado automaticamente',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Convertir número a romano
  static String _getCicloRomano(int ciclo) {
    const romanos = {
      1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
      6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X'
    };
    return romanos[ciclo] ?? ciclo.toString();
  }
}