import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/tema.dart';
import '../../data/models/curso.dart';
import '../../data/models/material.dart' as mat;
import '../../data/models/tarea.dart';
import '../../data/repositories/material_repository.dart';
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
        cursoId: widget.cursoId, // ✅ AGREGADO
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
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => DialogoCrearTema(
        cursoId: widget.cursoId,
        temaExistente: widget.tema,
      ),
    );

    if (resultado == true) {
      widget.onTemaActualizado();
    }
  }

  Future<void> _abrirMaterial(mat.Material material) async {
    final url = material.urlArchivo;
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El material no tiene URL disponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede abrir el material'),
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

  @override
  Widget build(BuildContext context) {
    final materiales = widget.tema.materiales ?? [];
    final tareas = widget.tema.tareas ?? [];
    final esPlaceholder = widget.tema.id.startsWith('placeholder');
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      margin: EdgeInsets.only(bottom: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 10.r),
      ),
      child: Column(
        children: [
          // Header del tema
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(kIsWeb ? 12 : 10.r),
            ),
            child: Container(
              padding: EdgeInsets.all(kIsWeb ? 16 : (isMobile ? 12.w : 16)),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(kIsWeb ? 12 : 10.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _expandido ? Icons.expand_more : Icons.chevron_right,
                    color: Theme.of(context).primaryColor,
                    size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
                  ),
                  SizedBox(width: kIsWeb ? 12 : (isMobile ? 8.w : 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema ${widget.tema.orden}: ${widget.tema.titulo}',
                          style: TextStyle(
                            fontSize: kIsWeb ? 18 : (isMobile ? 15.sp : 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.tema.descripcion != null) ...[
                          SizedBox(height: kIsWeb ? 4 : 3.h),
                          Text(
                            widget.tema.descripcion!,
                            style: TextStyle(
                              fontSize: kIsWeb ? 14 : (isMobile ? 12.sp : 14),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!esPlaceholder)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[700],
                        size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
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
              padding: EdgeInsets.all(kIsWeb ? 16 : (isMobile ? 12.w : 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Materiales
                  if (materiales.isNotEmpty) ...[
                    Text(
                      'MATERIALES',
                      style: TextStyle(
                        fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
                    ...materiales.map((material) {
                      return _buildMaterialItemSimple(material, isMobile);
                    }).toList(),
                    SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
                  ],

                  // Tareas
                  if (tareas.isNotEmpty) ...[
                    Text(
                      'TAREAS',
                      style: TextStyle(
                        fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
                    ...tareas.map((tarea) {
                      return _buildTareaItemSimple(tarea, isMobile);
                    }).toList(),
                    SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
                  ],

                  // Botones para agregar
                  if (!esPlaceholder) ...[
                    isMobile
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _mostrarDialogoCrearMaterial,
                                  icon: Icon(Icons.add, size: 16.sp),
                                  label: const Text('Material'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    foregroundColor: const Color(0xFF37474F),
                                    side: const BorderSide(color: Color(0xFF37474F)),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _mostrarDialogoCrearTarea,
                                  icon: Icon(Icons.assignment, size: 16.sp),
                                  label: const Text('Tarea'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    foregroundColor: const Color(0xFF37474F),
                                    side: const BorderSide(color: Color(0xFF37474F)),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
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
                        icon: Icon(Icons.add, size: kIsWeb ? 20 : 18.sp),
                        label: const Text('Crear este tema'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: kIsWeb ? 24 : (isMobile ? 16.w : 20),
                            vertical: kIsWeb ? 12 : (isMobile ? 10.h : 12),
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

  Widget _buildMaterialItemSimple(mat.Material material, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 12 : (isMobile ? 10.w : 12),
          vertical: kIsWeb ? 4 : (isMobile ? 3.h : 4),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          radius: kIsWeb ? 20 : (isMobile ? 18.r : 20),
          child: Icon(
            Icons.insert_drive_file,
            color: Colors.blue[700],
            size: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
          ),
        ),
        title: Text(
          material.titulo,
          style: TextStyle(
            fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          material.tipo.toUpperCase(),
          style: TextStyle(
            fontSize: kIsWeb ? 11 : (isMobile ? 10.sp : 11),
            color: Colors.grey[600],
          ),
        ),
        onTap: () => _abrirMaterial(material),
        trailing: IconButton(
          icon: Icon(
            Icons.more_vert,
            color: Colors.grey[600],
            size: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
          ),
          onPressed: () => _mostrarMenuMaterial(material),
        ),
      ),
    );
  }

  Widget _buildTareaItemSimple(Tarea tarea, bool isMobile) {
    final totalEntregas = tarea.totalEntregas ?? 0;
    final sinCalificar = tarea.entregasSinCalificar ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
        border: Border.all(
          color: sinCalificar > 0 ? Colors.orange[300]! : Colors.green[300]!,
          width: 1.5,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 12 : (isMobile ? 10.w : 12),
          vertical: kIsWeb ? 4 : (isMobile ? 3.h : 4),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.pink[100],
          radius: kIsWeb ? 20 : (isMobile ? 18.r : 20),
          child: Icon(
            Icons.assignment,
            color: Colors.pink[700],
            size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
          ),
        ),
        title: Text(
          tarea.titulo,
          style: TextStyle(
            fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: kIsWeb ? 4 : 3.h),
          child: Row(
            children: [
              Text(
                'Entregas: $totalEntregas',
                style: TextStyle(
                  fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                  color: Colors.grey[600],
                ),
              ),
              if (sinCalificar > 0) ...[
                SizedBox(width: kIsWeb ? 12 : (isMobile ? 8.w : 12)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 6 : (isMobile ? 5.w : 6),
                    vertical: kIsWeb ? 2 : (isMobile ? 2.h : 2),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(kIsWeb ? 4 : 4.r),
                  ),
                  child: Text(
                    'Sin calificar: $sinCalificar',
                    style: TextStyle(
                      fontSize: kIsWeb ? 11 : (isMobile ? 10.sp : 11),
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[600],
          size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
        ),
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
              leading: const Icon(Icons.open_in_new, color: Colors.blue),
              title: const Text('Abrir material'),
              onTap: () {
                Navigator.pop(context);
                _abrirMaterial(material);
              },
            ),
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
        cursoId: widget.cursoId, // ✅ AGREGADO
        materialExistente: material,
      ),
    ).then((resultado) {
      if (resultado == true) {
        widget.onTemaActualizado();
      }
    });
  }

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