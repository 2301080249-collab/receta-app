import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/tema.dart';
import '../../../data/models/entrega.dart';
import '../../../data/models/tarea.dart';
import '../../../data/repositories/tarea_repository.dart';
import '../../../data/repositories/tema_repository.dart';
import '../../widgets/CursoSidebarWidget.dart';
import '../../widgets/custom_app_header.dart';

class CalificarEntregaScreen extends StatefulWidget {
  final Entrega entrega;
  final Tarea tarea;
  final Curso curso;

  const CalificarEntregaScreen({
    Key? key,
    required this.entrega,
    required this.tarea,
    required this.curso,
  }) : super(key: key);

  @override
  State<CalificarEntregaScreen> createState() => _CalificarEntregaScreenState();
}

class _CalificarEntregaScreenState extends State<CalificarEntregaScreen> {
  late TareaRepository _tareaRepository;
  late TemaRepository _temaRepository;
  final _formKey = GlobalKey<FormState>();
  final _calificacionController = TextEditingController();
  final _comentarioController = TextEditingController();
  bool _isSaving = false;
  bool _modoEdicion = false; // ✅ NUEVO: Controla si está editando
  
  List<Tema> _temas = [];
  bool _isLoadingTemas = true;
  bool _sidebarVisible = true;
  Map<int, bool> _temasExpandidos = {};

  @override
  void initState() {
    super.initState();
    _tareaRepository = TareaRepository();
    _temaRepository = TemaRepository();
    
    for (int i = 1; i <= 16; i++) {
      _temasExpandidos[i] = false;
    }
    
    // ✅ Cargar calificación existente si ya está calificada
    if (widget.entrega.estaCalificada) {
      _calificacionController.text = widget.entrega.calificacion.toString();
      _comentarioController.text = widget.entrega.comentarioDocente ?? '';
    }
    
    _cargarTemas();
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

  // ✅ NUEVO: Activar modo edición
  void _activarEdicion() {
    setState(() {
      _modoEdicion = true;
    });
  }

  // ✅ NUEVO: Cancelar edición
  void _cancelarEdicion() {
    setState(() {
      _modoEdicion = false;
      // Restaurar valores originales
      _calificacionController.text = widget.entrega.calificacion.toString();
      _comentarioController.text = widget.entrega.comentarioDocente ?? '';
    });
  }

  @override
  void dispose() {
    _calificacionController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _guardarCalificacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final calificacion = double.parse(_calificacionController.text);
      await _tareaRepository.calificarEntrega(
        entregaId: widget.entrega.id,
        calificacion: calificacion,
        comentario: _comentarioController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calificación guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Volver con resultado
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _abrirArchivo(ArchivoEntrega archivo) async {
    final uri = Uri.parse(archivo.urlArchivo);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    // ✅ Determinar si los campos están habilitados
    final yaCalificada = widget.entrega.estaCalificada;
    final camposHabilitados = !yaCalificada || _modoEdicion;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const CustomAppHeader(selectedMenu: 'cursos'),
          
          Expanded(
            child: Row(
              children: [
                if (_sidebarVisible)
                  CursoSidebarWidget(
                    curso: widget.curso,
                    temas: _temas,
                    isLoading: _isLoadingTemas,
                    isVisible: _sidebarVisible,
                    temasExpandidos: _temasExpandidos,
                    onClose: _toggleSidebar,
                    onTemaToggle: _toggleTema,
                  ),
                
                Expanded(
                  child: Stack(
                    children: [
                      Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // SECCIÓN 1: DATOS DEL ESTUDIANTE
                              Container(
                                width: double.infinity,
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
                                padding: EdgeInsets.all(isMobile ? 16 : 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.white70, size: isMobile ? 18 : 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'DATOS DEL ESTUDIANTE',
                                          style: TextStyle(
                                            fontSize: isMobile ? 11 : 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withOpacity(0.8),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 12 : 16),
                                    Text(
                                      widget.entrega.estudiante?.nombreCompleto ?? 'Sin nombre',
                                      style: TextStyle(
                                        fontSize: isMobile ? 20 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRowWhite(
                                      Icons.email,
                                      'Email',
                                      widget.entrega.estudiante?.email ?? 'No disponible',
                                      isMobile,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isMobile ? 16 : 24),

                              // SECCIÓN 2: DATOS DE LA ENTREGA
                              Container(
                                width: double.infinity,
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
                                padding: EdgeInsets.all(isMobile ? 16 : 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.assignment, color: Colors.grey[700], size: isMobile ? 18 : 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ENTREGA DEL ESTUDIANTE',
                                          style: TextStyle(
                                            fontSize: isMobile ? 11 : 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 12 : 16),
                                    _buildInfoRow(Icons.title, 'Título', widget.entrega.titulo, isMobile),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.description,
                                      'Descripción',
                                      widget.entrega.descripcion ?? 'Sin descripción',
                                      isMobile,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.calendar_today,
                                      'Fecha de entrega',
                                      _formatearFecha(widget.entrega.fechaEntrega),
                                      isMobile,
                                    ),
                                    const SizedBox(height: 16),
                                    if (widget.entrega.archivos != null &&
                                        widget.entrega.archivos!.isNotEmpty) ...[
                                      Text(
                                        'Archivos adjuntos',
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...widget.entrega.archivos!.map((archivo) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: InkWell(
                                            onTap: () => _abrirArchivo(archivo),
                                            child: Container(
                                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.blue[200]!),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.insert_drive_file,
                                                      color: Colors.blue[700], size: isMobile ? 20 : 24),
                                                  SizedBox(width: isMobile ? 8 : 12),
                                                  Expanded(
                                                    child: Text(
                                                      archivo.nombreArchivo,
                                                      style: TextStyle(
                                                        color: Colors.blue[700],
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: isMobile ? 13 : 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(Icons.download, color: Colors.blue[700], size: isMobile ? 20 : 24),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(height: isMobile ? 16 : 24),

                              // SECCIÓN 3: CALIFICACIÓN
                              _buildSeccionCalificacion(isMobile, camposHabilitados, yaCalificada),
                            ],
                          ),
                        ),
                      ),
                      
                      if (!_sidebarVisible)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF455A64),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: _toggleSidebar,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVA FUNCIÓN: Sección de calificación con modos
  Widget _buildSeccionCalificacion(bool isMobile, bool camposHabilitados, bool yaCalificada) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grade, color: Colors.green[700], size: isMobile ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                'CALIFICACIÓN',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          
          // Campo de nota
          _buildCampoNota(isMobile, camposHabilitados),
          
          SizedBox(height: isMobile ? 20 : 24),
          
          // Campo de comentarios
          Text(
            'Comentarios para el estudiante',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _comentarioController,
            enabled: camposHabilitados, // ✅ Deshabilitar si ya calificó
            maxLines: isMobile ? 4 : 5,
            style: TextStyle(
              color: camposHabilitados ? Colors.black87 : Colors.grey[600],
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: camposHabilitados ? Colors.white : Colors.grey[100],
              hintText: 'Escribe tu retroalimentación aquí...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 13 : 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.green[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.green[300]!),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un comentario';
              }
              return null;
            },
          ),
          
          SizedBox(height: isMobile ? 20 : 24),
          
          // ✅ BOTONES DINÁMICOS
          _buildBotones(isMobile, yaCalificada),
        ],
      ),
    );
  }

  // ✅ NUEVA FUNCIÓN: Campo de nota responsive
  Widget _buildCampoNota(bool isMobile, bool camposHabilitados) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nota',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _calificacionController,
                      enabled: camposHabilitados,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: camposHabilitados ? Colors.black87 : Colors.grey[600],
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: camposHabilitados ? Colors.white : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.green[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.green[300]!),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una calificación';
                        }
                        final nota = double.tryParse(value);
                        if (nota == null) {
                          return 'Ingrese un número válido';
                        }
                        if (nota < 0 || nota > widget.tarea.puntajeMaximo) {
                          return 'Entre 0 y ${widget.tarea.puntajeMaximo}';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '/ ${widget.tarea.puntajeMaximo}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _calificacionController,
                      enabled: camposHabilitados,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: camposHabilitados ? Colors.black87 : Colors.grey[600],
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: camposHabilitados ? Colors.white : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.green[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.green[300]!),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una calificación';
                        }
                        final nota = double.tryParse(value);
                        if (nota == null) {
                          return 'Ingrese un número válido';
                        }
                        if (nota < 0 || nota > widget.tarea.puntajeMaximo) {
                          return 'Entre 0 y ${widget.tarea.puntajeMaximo}';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  '/ ${widget.tarea.puntajeMaximo}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          );
  }

  // ✅ NUEVA FUNCIÓN: Botones dinámicos según estado
  Widget _buildBotones(bool isMobile, bool yaCalificada) {
    if (!yaCalificada) {
      // NO ha calificado → Botón: Guardar
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _guardarCalificacion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'GUARDAR CALIFICACIÓN',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      );
    } else if (!_modoEdicion) {
      // YA calificó y NO está editando → Botón: Editar
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _activarEdicion,
          icon: const Icon(Icons.edit),
          label: Text(
            'EDITAR CALIFICACIÓN',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      );
    } else {
      // Está en modo edición → Botones: Cancelar + Actualizar
      return isMobile
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardarCalificacion,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('ACTUALIZAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _cancelarEdicion,
                    icon: const Icon(Icons.close),
                    label: const Text('CANCELAR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _cancelarEdicion,
                    icon: const Icon(Icons.close),
                    label: const Text('CANCELAR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardarCalificacion,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('ACTUALIZAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isMobile ? 16 : 18, color: Colors.grey[600]),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWhite(IconData icon, String label, String value, bool isMobile, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: isMobile ? 16 : 18, color: color ?? Colors.white70),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}