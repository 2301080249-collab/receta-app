import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
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
  bool _modoEdicion = false; // ✅ NUEVO: Controla si está editando

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

void _mostrarDialogoExito() {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.success,
    animType: AnimType.scale,
    
    customHeader: Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: Colors.white,
        size: 60,
      ),
    ),
    
    title: '¡Tarea entregada!',
    desc: _entregaExistente != null 
        ? 'Tu tarea se actualizó correctamente.'
        : 'Tu tarea se entregó exitosamente.',
    
    btnOkText: 'Aceptar',
    width: MediaQuery.of(context).size.width < 600 ? null : 500,
    
    // ✅ CORRECTO: Volver a la pantalla anterior con true
    btnOkOnPress: () {
      // El diálogo se cierra automáticamente
      // Solo necesitas hacer pop para volver al curso
      Navigator.of(context).pop(true); // ← El true indica que hubo cambios
    },
    
    btnOkColor: const Color(0xFF10B981),
    dismissOnTouchOutside: false,
    dismissOnBackKeyPress: false,
    headerAnimationLoop: false,
  ).show();
}
  // ✅ NUEVA FUNCIÓN: Activar modo edición
  void _activarEdicion() {
    setState(() {
      _modoEdicion = true;
    });
  }

  // ✅ NUEVA FUNCIÓN: Cancelar edición
  void _cancelarEdicion() {
    setState(() {
      _modoEdicion = false;
      _archivosNuevos.clear();
      if (_entregaExistente != null) {
        _tituloController.text = _entregaExistente!.titulo;
        _descripcionController.text = _entregaExistente!.descripcion ?? '';
      }
    });
  }

  Future<void> _entregarTarea() async {
    if (!_formKey.currentState!.validate()) return;

    if (_archivosNuevos.isEmpty && _entregaExistente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Debes adjuntar al menos un archivo'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_entregaExistente != null) {
        await _entregaRepository.editarEntrega(
          entregaId: _entregaExistente!.id,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
        );
        
        for (final archivo in _archivosNuevos) {
          await _entregaRepository.subirArchivo(
            entregaId: _entregaExistente!.id,
            archivo: archivo,
          );
        }
      } else {
        final nuevaEntrega = await _entregaRepository.crearEntrega(
          tareaId: widget.tarea.id,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
        );
        
        for (final archivo in _archivosNuevos) {
          await _entregaRepository.subirArchivo(
            entregaId: nuevaEntrega.id,
            archivo: archivo,
          );
        }
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        _mostrarDialogoExito();
      }
    } catch (e) {
  if (mounted) {
    setState(() => _isSubmitting = false);
    
    // ❌ DIALOG DE ERROR IDÉNTICO
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      
      // 🎨 ÍCONO ROJO CIRCULAR CON SOMBRA
      customHeader: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444), // ✅ Rojo exacto
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.error_rounded,
          color: Colors.white,
          size: 60,
        ),
      ),
      
      title: 'Error',
      desc: 'No se pudo entregar la tarea: $e',
      
      btnOkText: 'Cerrar',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      
      btnOkOnPress: () {},
      btnOkColor: const Color(0xFFEF4444),
      headerAnimationLoop: false,
    ).show();
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
    final yaEntrego = _entregaExistente != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const CustomAppHeader(selectedMenu: 'cursos'),
          
          Expanded(
            child: Row(
              children: [
                if (_curso != null && !isMobile)
                  CursoSidebarWidget(
                    curso: _curso!,
                    temas: _temas,
                    isLoading: _isLoadingTemas,
                    isVisible: _sidebarVisible,
                    temasExpandidos: _temasExpandidos,
                    onClose: _toggleSidebar,
                    onTemaToggle: _toggleTema,
                  ),
                
                Expanded(
                  child: _isLoading || _isLoadingCurso
                      ? const Center(child: CircularProgressIndicator())
                      : Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(kIsWeb ? 24 : (isMobile ? 16.w : 24)),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: kIsWeb ? 900 : double.infinity,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildInfoTarea(isMobile),
                                    SizedBox(height: kIsWeb ? 24 : (isMobile ? 16.h : 24)),
                                    
                                    if (estaCalificada) ...[
                                      _buildCalificacionCard(isMobile),
                                      SizedBox(height: kIsWeb ? 24 : (isMobile ? 16.h : 24)),
                                    ],
                                    
                                    _buildFormularioEntrega(estaCalificada, yaEntrego, isMobile),
                                  ],
                                ),
                              ),
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

  Widget _buildInfoTarea(bool isMobile) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(kIsWeb ? 24 : (isMobile ? 16.w : 24)),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF37474F), Color(0xFF455A64)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
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
        // ✅ AGREGAR BOTÓN DE RETROCESO AQUÍ
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: isMobile ? 24 : 28,
            ),
            SizedBox(width: kIsWeb ? 12 : (isMobile ? 10.w : 12)),
            Icon(
              Icons.assignment,
              color: Colors.white70,
              size: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
            ),
            SizedBox(width: kIsWeb ? 8 : (isMobile ? 6.w : 8)),
            Text(
              'INFORMACIÓN DE LA TAREA',
              style: TextStyle(
                fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        // ... resto del código sin cambios
          SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
          Text(
            widget.tarea.titulo,
            style: TextStyle(
              fontSize: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.tarea.descripcion != null) ...[
            SizedBox(height: kIsWeb ? 12 : (isMobile ? 8.h : 12)),
            Text(
              widget.tarea.descripcion!,
              style: TextStyle(
                fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                color: Colors.white70,
              ),
            ),
          ],
          SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.white70, size: 14.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Fecha límite: ${DateFormat('dd/MM/yyyy').format(widget.tarea.fechaLimite)}',
                          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.grade, color: Colors.white70, size: 14.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Puntaje: ${widget.tarea.puntajeMaximo}',
                          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
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

  Widget _buildCalificacionCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(kIsWeb ? 24 : (isMobile ? 16.w : 24)),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
        border: Border.all(color: Colors.green[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: kIsWeb ? 24 : (isMobile ? 22.sp : 24),
              ),
              SizedBox(width: kIsWeb ? 12 : (isMobile ? 10.w : 12)),
              Text(
                'TAREA CALIFICADA',
                style: TextStyle(
                  fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
          Row(
            children: [
              Text(
                'Calificación: ',
                style: TextStyle(
                  fontSize: kIsWeb ? 16 : (isMobile ? 15.sp : 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${_entregaExistente!.calificacion?.toStringAsFixed(0) ?? 0} / ${widget.tarea.puntajeMaximo}',
                style: TextStyle(
                  fontSize: kIsWeb ? 24 : (isMobile ? 22.sp : 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          if (_entregaExistente!.comentarioDocente != null) ...[
            SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
            Text(
              'Comentario del docente:',
              style: TextStyle(
                fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
            Text(
              _entregaExistente!.comentarioDocente!,
              style: TextStyle(
                fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormularioEntrega(bool estaCalificada, bool yaEntrego, bool isMobile) {
    // ✅ Si ya entregó y NO está en modo edición, los campos están deshabilitados
    final camposHabilitados = !estaCalificada && (!yaEntrego || _modoEdicion);

    return Container(
      padding: EdgeInsets.all(kIsWeb ? 24 : (isMobile ? 16.w : 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
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
            estaCalificada ? 'TU ENTREGA' : (yaEntrego ? 'TU ENTREGA' : 'ENTREGAR TAREA'),
            style: TextStyle(
              fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: kIsWeb ? 24 : (isMobile ? 16.h : 24)),
          
          // Título
          TextFormField(
            controller: _tituloController,
            enabled: camposHabilitados,
            style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
            decoration: InputDecoration(
              labelText: 'Título de la entrega',
              labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
              ),
              filled: true,
              fillColor: camposHabilitados ? Colors.white : Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa un título';
              }
              return null;
            },
          ),
          
          SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
          
          // Descripción
          TextFormField(
            controller: _descripcionController,
            enabled: camposHabilitados,
            maxLines: kIsWeb ? 4 : (isMobile ? 3 : 4),
            style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
              ),
              filled: true,
              fillColor: camposHabilitados ? Colors.white : Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
              ),
            ),
          ),
          
          SizedBox(height: kIsWeb ? 24 : (isMobile ? 16.h : 24)),
          
          // Archivos existentes
          if (_archivosExistentes.isNotEmpty) ...[
            Text(
              'Archivos actuales',
              style: TextStyle(
                fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: kIsWeb ? 12 : (isMobile ? 10.h : 12)),
            ..._archivosExistentes.map((archivo) {
              return _buildArchivoExistente(archivo, estaCalificada, isMobile, camposHabilitados);
            }).toList(),
            SizedBox(height: kIsWeb ? 24 : (isMobile ? 16.h : 24)),
          ],
          
          // Archivos nuevos
          if (_archivosNuevos.isNotEmpty) ...[
            Text(
              'Archivos nuevos',
              style: TextStyle(
                fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: kIsWeb ? 12 : (isMobile ? 10.h : 12)),
            ..._archivosNuevos.asMap().entries.map((entry) {
              return _buildArchivoNuevo(entry.value, entry.key, isMobile);
            }).toList(),
            SizedBox(height: kIsWeb ? 24 : (isMobile ? 16.h : 24)),
          ],
          
          // ✅ BOTONES DINÁMICOS
          if (!estaCalificada) ...[
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildBotones(yaEntrego, isMobile),
                  )
                : Row(
                    children: _buildBotones(yaEntrego, isMobile),
                  ),
          ],
        ],
      ),
    );
  }

  // ✅ NUEVA FUNCIÓN: Construir botones dinámicos
 // ✅ NUEVA FUNCIÓN: Construir botones dinámicos CON ADJUNTAR EN EDICIÓN
List<Widget> _buildBotones(bool yaEntrego, bool isMobile) {
  if (!yaEntrego) {
    // NO ha entregado → Botones: Adjuntar + Entregar
    return isMobile
        ? [
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _seleccionarArchivos,
              icon: Icon(Icons.attach_file, size: 18.sp),
              label: Text('Adjuntar archivos', style: TextStyle(fontSize: 14.sp)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(color: _isSubmitting ? Colors.grey : const Color(0xFF455A64)),
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _entregarTarea,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.send, size: 18.sp),
              label: Text('Entregar', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ]
        : [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _seleccionarArchivos,
                icon: const Icon(Icons.attach_file),
                label: const Text('Adjuntar archivos'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _isSubmitting ? Colors.grey : const Color(0xFF455A64)),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: const Text('Entregar', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ];
  } else if (!_modoEdicion) {
    // YA entregó y NO está editando → Botón: Editar
    return [
      if (isMobile)
        ElevatedButton.icon(
          onPressed: _activarEdicion,
          icon: Icon(Icons.edit, size: 18.sp),
          label: Text('Editar entrega', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        )
      else
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _activarEdicion,
            icon: const Icon(Icons.edit),
            label: const Text('Editar entrega', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
    ];
  } else {
    // ✅ Está en modo edición → Botones: Adjuntar + Actualizar + Cancelar
    return isMobile
        ? [
            // ✅ AGREGADO: Botón adjuntar en modo edición móvil
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _seleccionarArchivos,
              icon: Icon(Icons.attach_file, size: 18.sp),
              label: Text('Adjuntar archivos', style: TextStyle(fontSize: 14.sp)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: BorderSide(color: _isSubmitting ? Colors.grey : const Color(0xFF455A64)),
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _entregarTarea,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.check, size: 18.sp),
              label: Text('Actualizar', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _cancelarEdicion,
              icon: Icon(Icons.close, size: 18.sp),
              label: Text('Cancelar', style: TextStyle(fontSize: 14.sp)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ]
        : [
            // ✅ AGREGADO: Botón adjuntar en modo edición desktop
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _seleccionarArchivos,
                icon: const Icon(Icons.attach_file),
                label: const Text('Adjuntar archivos'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _isSubmitting ? Colors.grey : const Color(0xFF455A64)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _cancelarEdicion,
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _entregarTarea,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: const Text('Actualizar', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ];
  }
}

  Widget _buildArchivoExistente(ArchivoEntrega archivo, bool estaCalificada, bool isMobile, bool camposHabilitados) {
    return Container(
      margin: EdgeInsets.only(bottom: kIsWeb ? 12 : (isMobile ? 10.h : 12)),
      padding: EdgeInsets.all(kIsWeb ? 16 : (isMobile ? 12.w : 16)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: kIsWeb ? 40 : (isMobile ? 36.w : 40),
            height: kIsWeb ? 40 : (isMobile ? 36.h : 40),
            decoration: BoxDecoration(
              color: _getFileColor(archivo.tipoArchivo),
              borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
            ),
            child: Center(
              child: Icon(
                _getFileIcon(archivo.tipoArchivo),
                color: Colors.white,
                size: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
              ),
            ),
          ),
          SizedBox(width: kIsWeb ? 12 : (isMobile ? 10.w : 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archivo.nombreArchivo,
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  archivo.tamanoFormateado,
                  style: TextStyle(
                    fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: Colors.blue,
              size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
            ),
            onPressed: () => _descargarArchivo(archivo),
          ),
          if (camposHabilitados)
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
                size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
              ),
              onPressed: () => _eliminarArchivoExistente(archivo),
            ),
        ],
      ),
    );
  }

  Widget _buildArchivoNuevo(PlatformFile archivo, int index, bool isMobile) {
    final sizeInMB = (archivo.size / (1024 * 1024)).toStringAsFixed(2);
    
    return Container(
      margin: EdgeInsets.only(bottom: kIsWeb ? 12 : (isMobile ? 10.h : 12)),
      padding: EdgeInsets.all(kIsWeb ? 16 : (isMobile ? 12.w : 16)),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: kIsWeb ? 40 : (isMobile ? 36.w : 40),
            height: kIsWeb ? 40 : (isMobile ? 36.h : 40),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: Colors.white,
              size: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
            ),
          ),
          SizedBox(width: kIsWeb ? 12 : (isMobile ? 10.w : 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archivo.name,
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$sizeInMB MB',
                  style: TextStyle(
                    fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.red,
              size: kIsWeb ? 24 : (isMobile ? 20.sp : 24),
            ),
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