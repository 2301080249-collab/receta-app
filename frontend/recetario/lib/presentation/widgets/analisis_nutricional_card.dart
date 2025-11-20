import 'package:flutter/material.dart';
import '../../data/services/gemini_service.dart';

/// Widget que muestra el análisis nutricional de una receta
class AnalisisNutricionalCard extends StatefulWidget {
  final String recetaId;
  final String nombreReceta;
  final String categoria;
  final List<String> ingredientes;

  const AnalisisNutricionalCard({
    Key? key,
    required this.recetaId,
    required this.nombreReceta,
    required this.categoria,
    required this.ingredientes,
  }) : super(key: key);

  @override
  State<AnalisisNutricionalCard> createState() => _AnalisisNutricionalCardState();
}

class _AnalisisNutricionalCardState extends State<AnalisisNutricionalCard> {
  AnalisisNutricional? _analisis;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _cargarAnalisis();
  }

  Future<void> _cargarAnalisis() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Obtener API key desde tu env.dart
      final apiKey = 'AIzaSyDzVX0e1hmW2U-An4A_BBzVIFSXoxylq2k'; // Tu API key
      final service = GeminiNutritionService(apiKey);

      final analisis = await service.analizarReceta(
        recetaId: widget.recetaId,
        nombreReceta: widget.nombreReceta,
        categoria: widget.categoria,
        ingredientes: widget.ingredientes,
      );

      if (mounted) {
        setState(() {
          _analisis = analisis;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando análisis: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    if (_isLoading) {
      return _buildLoadingCard(isWeb);
    }

    if (_hasError || _analisis == null) {
      return const SizedBox.shrink();
    }

    return _buildAnalisisCard(isWeb);
  }

  Widget _buildLoadingCard(bool isWeb) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Analizando receta con IA...',
              style: TextStyle(
                fontSize: isWeb ? 15 : 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalisisCard(bool isWeb) {
    final analisis = _analisis!;
    
    // Determinar color según tipo
    Color colorPrincipal;
    Color colorFondo;
    IconData icono;

    switch (analisis.tipo) {
      case 'advertencia':
        colorPrincipal = Colors.orange[800]!;
        colorFondo = Colors.orange[50]!;
        icono = Icons.warning_amber_rounded;
        break;
      case 'beneficio':
        colorPrincipal = Colors.green[700]!;
        colorFondo = Colors.green[50]!;
        icono = Icons.check_circle_rounded;
        break;
      default:
        colorPrincipal = Colors.blue[700]!;
        colorFondo = Colors.blue[50]!;
        icono = Icons.info_rounded;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorFondo, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorPrincipal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icono, color: colorPrincipal, size: isWeb ? 24 : 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Análisis Nutricional',
                              style: TextStyle(
                                fontSize: isWeb ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF37474F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: Colors.purple[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'IA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Powered by Gemini AI',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Resumen principal
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorPrincipal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorPrincipal.withOpacity(0.3)),
                ),
                child: Text(
                  analisis.resumen,
                  style: TextStyle(
                    fontSize: isWeb ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: colorPrincipal,
                    height: 1.4,
                  ),
                ),
              ),

              // Puntos clave (si existen)
              if (analisis.puntosClave.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...analisis.puntosClave.map((punto) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorPrincipal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          punto,
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}