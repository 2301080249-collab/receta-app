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

  Future<void> _abrirMaterial(mat.Material material) async {
    try {
      final uri = Uri.parse(material.urlArchivo);
      
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!(material.vistoPorMi ?? false)) {
          try {
            await _materialRepository.marcarComoVisto(material.id);
            widget.onMaterialVisto();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Material abierto: ${material.titulo}'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            // Error silencioso al marcar como visto
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se puede abrir el archivo: ${material.titulo}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir material: $e'),
            backgroundColor: Colors.red,
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
        title: Text(material.titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material.descripcion ?? '',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              material.tamanoFormateado,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (material.vistoPorMi ?? false)
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _abrirMaterial(material),
              tooltip: 'Ver',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _descargarMaterial(material),
              tooltip: 'Descargar',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _descargarMaterial(mat.Material material) async {
    try {
      final uri = Uri.parse(material.urlArchivo);
      
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!(material.vistoPorMi ?? false)) {
          try {
            await _materialRepository.marcarComoVisto(material.id);
            widget.onMaterialVisto();
          } catch (e) {
            // Error silencioso
          }
        }
      
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Descargando: ${material.titulo}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede descargar el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        // ✅ NUEVO: Icono rosa igual al del docente
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