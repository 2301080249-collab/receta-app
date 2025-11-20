import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../../data/models/ciclo.dart';
import '../../data/models/curso.dart';
import '../../data/models/usuario.dart';
import '../../data/services/ciclo_service.dart';
import '../../data/services/curso_service.dart';
import '../../data/services/admin_service.dart';
import '../../data/services/matricula_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class DialogoMatriculaMasiva extends StatefulWidget {
  const DialogoMatriculaMasiva({super.key});

  @override
  State<DialogoMatriculaMasiva> createState() => _DialogoMatriculaMasivaState();
}

class _DialogoMatriculaMasivaState extends State<DialogoMatriculaMasiva> {
  List<Ciclo> _ciclos = [];
  List<Curso> _cursos = [];
  List<Usuario> _todosEstudiantes = [];
  List<Usuario> _estudiantesFiltrados = [];
  
  Ciclo? _cicloSeleccionado;
  Curso? _cursoSeleccionado;
  Set<String> _estudiantesSeleccionados = {};
  
  final TextEditingController _busquedaController = TextEditingController();
  
  String _estadoSeleccionado = 'activo';
  final TextEditingController _observacionesController = TextEditingController();

  bool _isLoading = false;
  bool _seleccionarTodos = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _busquedaController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      final results = await Future.wait([
        CicloService.listarCiclos(token),
        CursoService.listarCursos(token),
        AdminService.obtenerUsuarios(token),
      ]);

      if (!mounted) return;

      final estudiantes = (results[2] as List<dynamic>)
          .map((json) => Usuario.fromJson(json))
          .where((u) => u.rol == 'estudiante')
          .toList();

      setState(() {
        _ciclos = results[0] as List<Ciclo>;
        _cursos = results[1] as List<Curso>;
        _todosEstudiantes = estudiantes;
        _estudiantesFiltrados = [];
        
        if (_ciclos.isNotEmpty) {
          _cicloSeleccionado = _ciclos.firstWhere(
            (c) => c.activo,
            orElse: () => _ciclos.first,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar datos: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _aplicarFiltros() {
    final query = _busquedaController.text.toLowerCase().trim();
    
    setState(() {
      if (_cursoSeleccionado == null) {
        _estudiantesFiltrados = [];
      } else {
        _estudiantesFiltrados = _todosEstudiantes.where((estudiante) {
          final coincideNivel = estudiante.cicloActual == _cursoSeleccionado!.nivel;
          final coincideSeccion = estudiante.seccion?.toUpperCase() == 
                                  _cursoSeleccionado!.seccion?.toUpperCase();
          final cumpleBusqueda = query.isEmpty ||
              estudiante.nombreCompleto.toLowerCase().contains(query) ||
              (estudiante.codigo?.toLowerCase().contains(query) ?? false);
          
          return coincideNivel && coincideSeccion && cumpleBusqueda;
        }).toList();
      }
      
      _estudiantesSeleccionados.removeWhere(
        (id) => !_estudiantesFiltrados.any((e) => e.id == id)
      );
      
      _actualizarSeleccionTodos();
    });
  }

  void _actualizarSeleccionTodos() {
    _seleccionarTodos = _estudiantesFiltrados.isNotEmpty &&
        _estudiantesFiltrados.every((e) => _estudiantesSeleccionados.contains(e.id));
  }

  void _toggleSeleccionTodos() {
    setState(() {
      if (_seleccionarTodos) {
        for (var estudiante in _estudiantesFiltrados) {
          _estudiantesSeleccionados.remove(estudiante.id);
        }
      } else {
        for (var estudiante in _estudiantesFiltrados) {
          _estudiantesSeleccionados.add(estudiante.id);
        }
      }
      _actualizarSeleccionTodos();
    });
  }

  void _toggleEstudiante(String estudianteId) {
    setState(() {
      if (_estudiantesSeleccionados.contains(estudianteId)) {
        _estudiantesSeleccionados.remove(estudianteId);
      } else {
        _estudiantesSeleccionados.add(estudianteId);
      }
      _actualizarSeleccionTodos();
    });
  }

  Future<void> _matricularEstudiantes() async {
    if (_cursoSeleccionado == null) {
      _mostrarAdvertencia('Seleccione un curso');
      return;
    }
    if (_cicloSeleccionado == null) {
      _mostrarAdvertencia('Seleccione un ciclo académico');
      return;
    }
    if (_estudiantesSeleccionados.isEmpty) {
      _mostrarAdvertencia('Seleccione al menos un estudiante');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      final resultado = await MatriculaService.crearMatriculaMasiva(
        token: token,
        estudiantesIds: _estudiantesSeleccionados.toList(),
        cursoId: _cursoSeleccionado!.id,
        cicloId: _cicloSeleccionado!.id,
        estado: _estadoSeleccionado,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );

      if (mounted) {
        final exitosos = resultado['exitosos'] ?? 0;
        final fallidos = resultado['fallidos'] ?? 0;
        
        if (fallidos > 0) {
          _mostrarDialogoResultados(resultado);
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al matricular: $e');
      }
    }
  }

  // ⚠️ ADVERTENCIA CON AWESOME DIALOG
  void _mostrarAdvertencia(String mensaje) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      customHeader: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.orange[600],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 60,
        ),
      ),
      title: 'Campos Incompletos',
      desc: mensaje,
      btnOkText: 'Entendido',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      btnOkOnPress: () {},
      btnOkColor: Colors.orange[600],
      dismissOnTouchOutside: false,
      headerAnimationLoop: false,
    ).show();
  }

  // ❌ ERROR CON AWESOME DIALOG
  void _mostrarError(String mensaje) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      customHeader: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withOpacity(0.3),
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
      desc: mensaje,
      btnOkText: 'Cerrar',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      btnOkOnPress: () {},
      btnOkColor: AppTheme.errorColor,
      headerAnimationLoop: false,
    ).show();
  }

  // ℹ️ RESULTADOS PARCIALES CON AWESOME DIALOG
  void _mostrarDialogoResultados(Map<String, dynamic> resultado) {
    final exitosos = resultado['exitosos'] ?? 0;
    final fallidos = resultado['fallidos'] ?? 0;
    final errores = resultado['errores'] as List? ?? [];

    String erroresTexto = '';
    if (errores.isNotEmpty) {
      erroresTexto = '\n\nErrores:\n${errores.map((e) => '• $e').join('\n')}';
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.scale,
      customHeader: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.orange[600],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.info_rounded,
          color: Colors.white,
          size: 60,
        ),
      ),
      title: 'Proceso Completado',
      desc: '✅ Exitosos: $exitosos\n❌ Fallidos: $fallidos$erroresTexto',
      btnOkText: 'Cerrar',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      btnOkOnPress: () {
        Navigator.pop(context, true);
      },
      btnOkColor: Colors.orange[600],
      dismissOnTouchOutside: false,
      headerAnimationLoop: false,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : 800,
          maxHeight: isMobile ? screenHeight * 0.9 : 700,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              Divider(height: isMobile ? 24 : 32),
              if (_isLoading)
                Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPaso1(isMobile),
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildPaso2(isMobile),
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildPaso3(isMobile),
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildOpcionesAdicionales(isMobile),
                      ],
                    ),
                  ),
                ),
              Divider(height: isMobile ? 24 : 32),
              _buildActions(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
           color: Color(0xFF475569).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.groups, color: Color(0xFF475569), size: isMobile ? 20 : 24),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Text(
            'Matrícula Masiva',
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: isMobile ? 20 : 24),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _buildPaso1(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 1: Seleccionar Curso',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              DropdownButtonFormField<Ciclo>(
                value: _cicloSeleccionado,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Ciclo Académico',
                  labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.calendar_today, size: isMobile ? 18 : 20),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 12 : 14,
                  ),
                ),
                style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.black),
                items: _ciclos.map((ciclo) {
                  return DropdownMenuItem(
                    value: ciclo,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ciclo.nombre,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ciclo.activo) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 6 : 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Activo',
                              style: TextStyle(
                                fontSize: isMobile ? 9 : 10,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (ciclo) {
                  setState(() {
                    _cicloSeleccionado = ciclo;
                    _cursoSeleccionado = null;
                    _estudiantesFiltrados = [];
                    _estudiantesSeleccionados.clear();
                  });
                },
              ),
              SizedBox(height: isMobile ? 12 : 16),
              DropdownButtonFormField<Curso>(
                value: _cursoSeleccionado,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Curso',
                  labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.book, size: isMobile ? 18 : 20),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 12 : 14,
                  ),
                ),
                style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.black),
                items: _cicloSeleccionado != null
                    ? _cursos.where((c) => c.cicloId == _cicloSeleccionado!.id).map((curso) {
                        return DropdownMenuItem(
                          value: curso,
                          child: Text(
                            '${curso.nombre} - Nivel ${curso.nivelRomano} - Sección ${curso.seccion ?? "?"}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList()
                    : [],
                onChanged: (curso) {
                  setState(() {
                    _cursoSeleccionado = curso;
                    _estudiantesSeleccionados.clear();
                    _aplicarFiltros();
                  });
                },
              ),
              if (_cursoSeleccionado != null) ...[
                SizedBox(height: isMobile ? 8 : 12),
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: isMobile ? 16 : 18, color: Colors.blue[700]),
                      SizedBox(width: isMobile ? 6 : 8),
                      Expanded(
                        child: Text(
                          'Nivel ${_cursoSeleccionado!.nivelRomano} - Sección ${_cursoSeleccionado!.seccion ?? "?"} - Docente: ${_cursoSeleccionado!.docenteNombre ?? "Sin asignar"}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaso2(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 2: Buscar Estudiantes',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        
        if (_cursoSeleccionado == null)
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Color(0xFF475569).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF475569).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF475569),
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    'Selecciona un curso primero para ver los estudiantes compatibles',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: isMobile ? 16 : 18, color: Colors.green[700]),
                      SizedBox(width: isMobile ? 6 : 8),
                      Expanded(
                        child: Text(
                          'Mostrando estudiantes de: Ciclo ${_cursoSeleccionado!.nivelRomano} - Sección ${_cursoSeleccionado!.seccion ?? "?"}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.green[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                TextField(
                  controller: _busquedaController,
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                  decoration: InputDecoration(
                    labelText: '🔍 Buscar estudiante',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    hintText: 'Nombre o código...',
                    hintStyle: TextStyle(fontSize: isMobile ? 12 : 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: EdgeInsets.all(isMobile ? 10 : 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaso3(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'PASO 3: Seleccionar Estudiantes',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isMobile || _estudiantesSeleccionados.isNotEmpty)
              Text(
                '📊 ${_estudiantesSeleccionados.length}/${_estudiantesFiltrados.length}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Container(
          height: isMobile ? 250 : 300,
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              if (_estudiantesFiltrados.isNotEmpty)
                CheckboxListTile(
                  title: Text(
                    'Seleccionar todos (${_estudiantesFiltrados.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  value: _seleccionarTodos,
                  onChanged: (_) => _toggleSeleccionTodos(),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: isMobile,
                ),
              if (_estudiantesFiltrados.isNotEmpty) Divider(),
              Expanded(
                child: _cursoSeleccionado == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book_outlined, size: isMobile ? 40 : 48, color: Colors.grey),
                            SizedBox(height: isMobile ? 8 : 12),
                            Text(
                              'Selecciona un curso primero',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _estudiantesFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_outlined, size: isMobile ? 40 : 48, color: Colors.orange),
                                SizedBox(height: isMobile ? 8 : 12),
                                Text(
                                  'No hay estudiantes disponibles',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Para: Ciclo ${_cursoSeleccionado!.nivelRomano} - Sección ${_cursoSeleccionado!.seccion ?? "?"}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isMobile ? 12 : 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _estudiantesFiltrados.length,
                            itemBuilder: (context, index) {
                              final estudiante = _estudiantesFiltrados[index];
                              final seleccionado = _estudiantesSeleccionados.contains(estudiante.id);
                              
                              return CheckboxListTile(
                                title: Text(
                                  estudiante.nombreCompleto,
                                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                                ),
                                subtitle: Text(
                                  'Código: ${estudiante.codigo ?? "Sin código"} • ${estudiante.cicloSeccionCompleto}',
                                  style: TextStyle(fontSize: isMobile ? 11 : 12),
                                ),
                                value: seleccionado,
                                onChanged: (_) => _toggleEstudiante(estudiante.id),
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: isMobile,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpcionesAdicionales(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones Adicionales',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        DropdownButtonFormField<String>(
          value: _estadoSeleccionado,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Estado por defecto',
            labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: Icon(Icons.flag, size: isMobile ? 18 : 20),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
          ),
          style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.black),
          items: [
            DropdownMenuItem(value: 'activo', child: Text('Activo')),
            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
            DropdownMenuItem(value: 'condicional', child: Text('Condicional')),
          ],
          onChanged: (value) {
            setState(() => _estadoSeleccionado = value ?? 'activo');
          },
        ),
        SizedBox(height: isMobile ? 12 : 16),
        TextField(
          controller: _observacionesController,
          maxLines: 2,
          style: TextStyle(fontSize: isMobile ? 13 : 14),
          decoration: InputDecoration(
            labelText: 'Observaciones (Opcional)',
            labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
            hintText: 'Se aplicará a todos los estudiantes seleccionados...',
            hintStyle: TextStyle(fontSize: isMobile ? 12 : 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _matricularEstudiantes,
            icon: Icon(Icons.check_circle, size: isMobile ? 18 : 20),
            label: Text(
              isMobile
                  ? 'Matricular (${_estudiantesSeleccionados.length})'
                  : 'Matricular Estudiantes (${_estudiantesSeleccionados.length})',
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF475569),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 10 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}