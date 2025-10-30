import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/tarea.dart';
import '../../../data/models/entrega.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/tema.dart';
import '../../../data/repositories/entrega_repository.dart';
import '../../../data/repositories/tarea_repository.dart';
import '../../../data/repositories/tema_repository.dart';
import '../../../data/repositories/curso_repository.dart';
import '../../widgets/CursoSidebarWidget.dart';
import '../../widgets/custom_app_header.dart';

class EntregarTareaScreen extends StatefulWidget {
  final Tarea tarea;

  const EntregarTareaScreen({
    Key? key,
    required this.tarea,
  }) : super(key: key);

  @override
  State<EntregarTareaScreen> createState() => _EntregarTareaScreenState();
}

class _EntregarTareaScreenState extends State<EntregarTareaScreen> {
  late EntregaRepository _entregaRepository;
  late TareaRepository _tareaRepository;
  late TemaRepository _temaRepository;
  late CursoRepository _cursoRepository;
  
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  List<PlatformFile> _archivosNuevos = [];
  List<ArchivoEntrega> _archivosExistentes = [];
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isLoadingCurso = true;

  Entrega? _entregaExistente;
  Curso? _curso;

  // Sidebar
  List<Tema> _temas = [];
  bool _isLoadingTemas = true;
  bool _sidebarVisible = true;
  Map<int, bool> _temasExpandidos = {};

  @override
  void initState() {
    super.initState();
    _entregaRepository = EntregaRepository();
    _tareaRepository = TareaRepository();
    _temaRepository = TemaRepository();
    _cursoRepository = CursoRepository();
    
    // Inicializar temas expandidos
    for (int i = 1; i <= 16; i++) {
      _temasExpandidos[i] = false;
    }
    
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarCurso(),
      _cargarTemas(),
      _verificarEntregaExistente(),
    ]);
  }

  Future<void> _cargarCurso() async {
    try {
      final curso = await _cursoRepository.obtenerCursoPorId('', widget.tarea.cursoId);
      if (mounted) {
        setState(() {
          _curso = curso;
          _isLoadingCurso = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCurso = false);
      }
    }
  }

  Future<void> _cargarTemas() async {
    try {
      final temas = await _temaRepository.getTemasByCursoId(widget.tarea.cursoId);
      if (mounted) {
        setState(() {
          _temas = temas;
          _isLoadingTemas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTemas = false);
      }
    }
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarVisible = !_sidebarVisible;
    });
  }

  void _toggleTema(int orden) {
    setState(() {
      _temasExpandidos[orden] = !(_temasExpandidos[orden] ?? false);
    });
  }

  Future<void> _verificarEntregaExistente() async {
    try {
      final entrega = await _tareaRepository.getMiEntrega(widget.tarea.id);

      if (entrega != null && mounted) {
        setState(() {
          _entregaExistente = entrega;
          _tituloController.text = entrega.titulo;
          _descripcionController.text = entrega.descripcion ?? '';
          _archivosExistentes = entrega.archivos ?? [];
        });
      }
    } catch (e) {
      print('✅ No tiene entrega previa');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seleccionarArchivos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'mp4', 'mov'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _archivosNuevos.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivos: $e')),
        );
      }
    }
  }

  void _eliminarArchivoNuevo(int index) {
    setState(() {
      _archivosNuevos.removeAt(index);
    });
  }

  Future<void> _eliminarArchivoExistente(ArchivoEntrega archivo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('¿Deseas eliminar "${archivo.nombreArchivo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      await _entregaRepository.eliminarArchivoEntrega(archivo.id, archivo.urlArchivo);

      if (mounted) {
        setState(() {
          _archivosExistentes.removeWhere((a) => a.id == archivo.id);
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo eliminado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar archivo: $e')),
        );
      }
    }
  }

  Future<void> _descargarArchivo(ArchivoEntrega archivo) async {
    try {
      final uri = Uri.parse(archivo.urlArchivo);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede abrir el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _entregarTarea() async {
    if (!_formKey.currentState!.validate()) return;

    if (_archivosNuevos.isEmpty && _entregaExistente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes adjuntar al menos un archivo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_entregaExistente != null) {
        // Actualizar entrega existente
        await _entregaRepository.editarEntrega(
          entregaId: _entregaExistente!.id,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
        );
        
        // Subir archivos nuevos
        for (final archivo in _archivosNuevos) {
          await _entregaRepository.subirArchivo(
            entregaId: _entregaExistente!.id,
            archivo: archivo,
          );
        }
      } else {
        // Crear nueva entrega
        final nuevaEntrega = await _entregaRepository.crearEntrega(
          tareaId: widget.tarea.id,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
        );
        
        // Subir archivos
        for (final archivo in _archivosNuevos) {
          await _entregaRepository.subirArchivo(
            entregaId: nuevaEntrega.id,
            archivo: archivo,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea entregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al entregar tarea: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estaCalificada = _entregaExistente?.estaCalificada ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const CustomAppHeader(selectedMenu: 'cursos'),
          
          Expanded(
            child: Row(
              children: [
                // Sidebar
                if (_curso != null)
                  CursoSidebarWidget(
                    curso: _curso!,
                    temas: _temas,
                    isLoading: _isLoadingTemas,
                    isVisible: _sidebarVisible,
                    temasExpandidos: _temasExpandidos,
                    onClose: _toggleSidebar,
                    onTemaToggle: _toggleTema,
                  ),
                
                // Contenido
                Expanded(
                  child: _isLoading || _isLoadingCurso
                      ? const Center(child: CircularProgressIndicator())
                      : Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Información de la tarea
                                _buildInfoTarea(),
                                
                                const SizedBox(height: 24),
                                
                                // Calificación (si existe)
                                if (estaCalificada) ...[
                                  _buildCalificacionCard(),
                                  const SizedBox(height: 24),
                                ],
                                
                                // Formulario de entrega
                                _buildFormularioEntrega(estaCalificada),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTarea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'INFORMACIÓN DE LA TAREA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.tarea.titulo,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.tarea.descripcion != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.tarea.descripcion!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Fecha límite: ${DateFormat('dd/MM/yyyy').format(widget.tarea.fechaLimite)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.grade, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Puntaje: ${widget.tarea.puntajeMaximo}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalificacionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Text(
                'TAREA CALIFICADA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Calificación: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${_entregaExistente!.calificacion?.toStringAsFixed(0) ?? 0} / ${widget.tarea.puntajeMaximo}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          if (_entregaExistente!.comentarioDocente != null) ...[
            const SizedBox(height: 16),
            Text(
              'Comentario del docente:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _entregaExistente!.comentarioDocente!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormularioEntrega(bool estaCalificada) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            estaCalificada ? 'TU ENTREGA' : 'ENTREGAR TAREA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          
          // Título
          TextFormField(
            controller: _tituloController,
            enabled: !estaCalificada,
            decoration: InputDecoration(
              labelText: 'Título de la entrega',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: estaCalificada ? Colors.grey[100] : Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa un título';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Descripción
          TextFormField(
            controller: _descripcionController,
            enabled: !estaCalificada,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: estaCalificada ? Colors.grey[100] : Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Archivos existentes
          if (_archivosExistentes.isNotEmpty) ...[
            Text(
              'Archivos actuales',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ..._archivosExistentes.map((archivo) {
              return _buildArchivoExistente(archivo, estaCalificada);
            }).toList(),
            const SizedBox(height: 24),
          ],
          
          // Archivos nuevos
          if (_archivosNuevos.isNotEmpty) ...[
            Text(
              'Archivos nuevos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ..._archivosNuevos.asMap().entries.map((entry) {
              return _buildArchivoNuevo(entry.value, entry.key);
            }).toList(),
            const SizedBox(height: 24),
          ],
          
          // Botones
          if (!estaCalificada) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _seleccionarArchivos,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Adjuntar archivos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _entregarTarea,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_entregaExistente != null ? 'Actualizar' : 'Entregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArchivoExistente(ArchivoEntrega archivo, bool estaCalificada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileColor(archivo.tipoArchivo),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getFileIcon(archivo.tipoArchivo),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archivo.nombreArchivo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  archivo.tamanoFormateado,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: () => _descargarArchivo(archivo),
          ),
          if (!estaCalificada)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarArchivoExistente(archivo),
            ),
        ],
      ),
    );
  }

  Widget _buildArchivoNuevo(PlatformFile archivo, int index) {
    final sizeInMB = (archivo.size / (1024 * 1024)).toStringAsFixed(2);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.insert_drive_file,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archivo.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$sizeInMB MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _eliminarArchivoNuevo(index),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}