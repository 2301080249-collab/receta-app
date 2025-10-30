import 'package:flutter/material.dart';
import '../../data/models/tema.dart';
import '../../data/models/curso.dart';
import '../../data/models/material.dart' as mat;
import '../../data/models/tarea.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/tema_repository.dart';
import 'dialogo_crear_material.dart';
import 'dialogo_crear_tarea.dart';
import 'dialogo_crear_tema.dart';
import '../screens/docente/entregas_tarea_screen.dart';

class TemaCardDocente extends StatefulWidget {
  final Tema tema;
  final String cursoId;
  final Curso curso;
  final VoidCallback onTemaActualizado;

  const TemaCardDocente({
    Key? key,
    required this.tema,
    required this.cursoId,
    required this.curso,
    required this.onTemaActualizado,
  }) : super(key: key);

  @override
  State<TemaCardDocente> createState() => _TemaCardDocenteState();
}

class _TemaCardDocenteState extends State<TemaCardDocente> {
  late MaterialRepository _materialRepository;
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _materialRepository = MaterialRepository();
  }

  void _mostrarDialogoCrearMaterial() {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearMaterial(
        temaId: widget.tema.id,
      ),
    ).then((resultado) {
      if (resultado == true) {
        widget.onTemaActualizado();
      }
    });
  }

  void _mostrarDialogoCrearTarea() {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearTarea(
        cursoId: widget.cursoId,
        temaId: widget.tema.id,
        onTareaCreada: widget.onTemaActualizado,
      ),
    );
  }

  Future<void> _crearTemaReal() async {
    // ✅ Usar el nuevo diálogo minimalista
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => DialogoCrearTema(
        cursoId: widget.cursoId,
        temaExistente: widget.tema, // Pasar el placeholder para usar su orden
      ),
    );

    if (resultado == true) {
      widget.onTemaActualizado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final materiales = widget.tema.materiales ?? [];
    final tareas = widget.tema.tareas ?? [];
    final esPlaceholder = widget.tema.id.startsWith('placeholder');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header del tema
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _expandido ? Icons.expand_more : Icons.chevron_right,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema ${widget.tema.orden}: ${widget.tema.titulo}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.tema.descripcion != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.tema.descripcion!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ✅ REEMPLAZADO: PopupMenuButton profesional (solo Editar)
                  if (!esPlaceholder)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[700],
                      ),
                      tooltip: 'Opciones del tema',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      offset: const Offset(0, 45),
                      elevation: 4,
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              const Text('Editar tema'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'editar') {
                          _editarTema();
                        }
                      },
                    ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          if (_expandido) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Materiales
                  if (materiales.isNotEmpty) ...[
                    const Text(
                      'MATERIALES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...materiales.map((material) {
                      return _buildMaterialItemSimple(material);
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  // Tareas
                  if (tareas.isNotEmpty) ...[
                    const Text(
                      'TAREAS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tareas.map((tarea) {
                      return _buildTareaItemSimple(tarea);
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  // Botones para agregar
                  if (!esPlaceholder) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          child: OutlinedButton.icon(
                            onPressed: _mostrarDialogoCrearMaterial,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Material'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: const Color(0xFF37474F),
                              side: const BorderSide(color: Color(0xFF37474F)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: OutlinedButton.icon(
                            onPressed: _mostrarDialogoCrearTarea,
                            icon: const Icon(Icons.assignment, size: 18),
                            label: const Text('Tarea'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: const Color(0xFF37474F),
                              side: const BorderSide(color: Color(0xFF37474F)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _crearTemaReal,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear este tema'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialItemSimple(mat.Material material) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          radius: 20,
          child: Icon(Icons.insert_drive_file, color: Colors.blue[700], size: 20),
        ),
        title: Text(
          material.titulo,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          material.tipo.toUpperCase(),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
          onPressed: () => _mostrarMenuMaterial(material),
        ),
      ),
    );
  }

  Widget _buildTareaItemSimple(Tarea tarea) {
    final totalEntregas = tarea.totalEntregas ?? 0;
    final sinCalificar = tarea.entregasSinCalificar ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sinCalificar > 0 ? Colors.orange[300]! : Colors.green[300]!,
          width: 1.5,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.pink[100],
          radius: 20,
          child: Icon(
            Icons.assignment,
            color: Colors.pink[700],
            size: 24,
          ),
        ),
        title: Text(
          tarea.titulo,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                'Entregas: $totalEntregas',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (sinCalificar > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Sin calificar: $sinCalificar',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EntregasTareaScreen(
                tarea: tarea,
                curso: widget.curso,
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarMenuMaterial(mat.Material material) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar material'),
              onTap: () {
                Navigator.pop(context);
                _editarMaterial(material);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar material', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminarMaterial(material);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editarMaterial(mat.Material material) {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearMaterial(
        temaId: widget.tema.id,
        materialExistente: material,
      ),
    ).then((resultado) {
      if (resultado == true) {
        widget.onTemaActualizado();
      }
    });
  }

  // ✅ NUEVA FUNCIÓN: Editar tema
  void _editarTema() {
    showDialog(
      context: context,
      builder: (context) => DialogoCrearTema(
        cursoId: widget.cursoId,
        temaExistente: widget.tema,
      ),
    ).then((resultado) {
      if (resultado == true) {
        widget.onTemaActualizado();
      }
    });
  }

  void _confirmarEliminarMaterial(mat.Material material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar material'),
        content: Text('¿Eliminar "${material.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Eliminando material...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              
              try {
                await _materialRepository.eliminarMaterial(material.id);
                
                if (mounted) {
                  widget.onTemaActualizado();
                  
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Material eliminado exitosamente'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}