import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/models/tema.dart';
import '../../data/models/material.dart' as mat;
import '../../data/models/tarea.dart';
import '../../data/repositories/material_repository.dart';
import '../screens/estudiante/entregar_tarea_screen.dart';

class TemaCardEstudiante extends StatefulWidget {
  final Tema tema;
  final VoidCallback onMaterialVisto;

  const TemaCardEstudiante({
    Key? key,
    required this.tema,
    required this.onMaterialVisto,
  }) : super(key: key);

  @override
  State<TemaCardEstudiante> createState() => _TemaCardEstudianteState();
}

class _TemaCardEstudianteState extends State<TemaCardEstudiante> {
  late MaterialRepository _materialRepository;
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _materialRepository = MaterialRepository();
  }

  // ✅ FUNCIÓN ÚNICA: Descargar/abrir material
  Future<void> _abrirMaterial(mat.Material material) async {
    try {
      final uri = Uri.parse(material.urlArchivo);
      
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        // Marcar como visto
        if (!(material.vistoPorMi ?? false)) {
          try {
            await _materialRepository.marcarComoVisto(material.id);
            widget.onMaterialVisto();
          } catch (e) {
            // Error silencioso al marcar como visto
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.download, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Abriendo: ${material.titulo}'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('No se puede abrir el archivo'),
                  ),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error al abrir material: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatearFechaCorta(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final materiales = widget.tema.materiales ?? [];
    final tareas = widget.tema.tareas ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandido = !_expandido;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tema ${widget.tema.orden}: ${widget.tema.titulo}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expandido) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (materiales.isNotEmpty) ...[
                    const Text(
                      'MATERIALES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...materiales.map((material) =>
                        _buildMaterialItem(material)).toList(),
                    const SizedBox(height: 16),
                  ],
                  if (tareas.isNotEmpty) ...[
                    const Text(
                      'TAREAS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tareas.map((tarea) => _buildTareaItem(tarea)).toList(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialItem(mat.Material material) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: material.vistoPorMi ?? false ? Colors.green[50] : null,
      child: ListTile(
        // ✅ SOLO ESTO: Hacer clic para descargar
        onTap: () => _abrirMaterial(material),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: material.vistoPorMi ?? false
                ? Colors.green[100]
                : Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.insert_drive_file,
            color: material.vistoPorMi ?? false
                ? Colors.green[800]
                : Colors.blue[800],
          ),
        ),
        title: Text(
          material.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (material.descripcion != null && material.descripcion!.isNotEmpty)
              Text(
                material.descripcion!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '${material.tipo.toUpperCase()} • ${material.tamanoFormateado}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        // ✅ SOLO ÍCONO DE CHECK SI YA LO VIO
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (material.vistoPorMi ?? false)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Visto',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.download,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTareaItem(Tarea tarea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: tarea.yaEntregue
          ? (tarea.estaCalificada ? Colors.green[50] : Colors.blue[50])
          : (tarea.estaVencida ?? false)
              ? Colors.red[50]
              : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.pink[100],
          radius: 20,
          child: Icon(
            Icons.assignment,
            color: Colors.pink[700],
            size: 24,
          ),
        ),
        title: Text(tarea.titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vence: ${_formatearFechaCorta(tarea.fechaLimite)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (tarea.yaEntregue) ...[
              if (tarea.estaCalificada)
                Text(
                  'Calificación: ${tarea.miEntrega!.calificacion}/${tarea.puntajeMaximo}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                )
              else
                Text(
                  'Entregado - Pendiente de calificación',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
            ] else ...[
              Text(
                tarea.tiempoHastaVencimientoTexto,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (tarea.estaVencida ?? false)
                      ? Colors.red[800]
                      : Colors.orange[800],
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntregarTareaScreen(tarea: tarea),
            ),
          ).then((resultado) {
            if (resultado == true) {
              widget.onMaterialVisto();
            }
          });
        },
      ),
    );
  }
}