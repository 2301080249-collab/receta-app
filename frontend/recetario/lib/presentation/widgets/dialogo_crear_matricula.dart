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

class DialogoCrearMatricula extends StatefulWidget {
  const DialogoCrearMatricula({super.key});

  @override
  State<DialogoCrearMatricula> createState() => _DialogoCrearMatriculaState();
}

class _DialogoCrearMatriculaState extends State<DialogoCrearMatricula> {
  List<Ciclo> _ciclos = [];
  List<Curso> _cursos = [];
  List<Usuario> _estudiantes = [];

  Ciclo? _cicloSeleccionado;
  Curso? _cursoSeleccionado;
  Usuario? _estudianteSeleccionado;
  String _estadoSeleccionado = 'activo';
  
  final TextEditingController _observacionesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
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
        _estudiantes = estudiantes;
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

  Future<void> _crearMatricula() async {
    if (_estudianteSeleccionado == null) {
      _mostrarAdvertencia('Seleccione un estudiante');
      return;
    }
    if (_cursoSeleccionado == null) {
      _mostrarAdvertencia('Seleccione un curso');
      return;
    }
    if (_cicloSeleccionado == null) {
      _mostrarAdvertencia('Seleccione un ciclo académico');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      await MatriculaService.crearMatricula(
  token: token,
  estudianteId: _estudianteSeleccionado!.id,  // ✅ Ya es correcto (es usuario_id)
  cursoId: _cursoSeleccionado!.id,
  cicloId: _cicloSeleccionado!.id,
  estado: _estadoSeleccionado,
  observaciones: _observacionesController.text.trim().isEmpty 
      ? null 
      : _observacionesController.text.trim(),
);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al crear matrícula: $e');
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
          maxWidth: isMobile ? screenWidth : 600,
          maxHeight: isMobile ? screenHeight * 0.9 : 750,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              const Divider(height: 32),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeccionTitulo('1. Ciclo Académico *', isMobile),
                        SizedBox(height: isMobile ? 8 : 12),
                        _buildDropdownCiclo(isMobile),
                        SizedBox(height: isMobile ? 16 : 24),
                        
                        _buildSeccionTitulo('2. Estudiante *', isMobile),
                        SizedBox(height: isMobile ? 8 : 12),
                        _buildDropdownEstudiante(isMobile),
                        if (_estudianteSeleccionado != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoEstudiante(isMobile),
                        ],
                        SizedBox(height: isMobile ? 16 : 24),
                        
                        _buildSeccionTitulo('3. Curso *', isMobile),
                        SizedBox(height: isMobile ? 8 : 12),
                        _buildDropdownCurso(isMobile),
                        if (_cursoSeleccionado != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoCurso(isMobile),
                        ],
                        SizedBox(height: isMobile ? 16 : 24),
                        
                        _buildSeccionTitulo('4. Estado (Opcional)', isMobile),
                        SizedBox(height: isMobile ? 8 : 12),
                        _buildDropdownEstado(isMobile),
                        SizedBox(height: isMobile ? 16 : 24),
                        
                        _buildSeccionTitulo('5. Observaciones (Opcional)', isMobile),
                        SizedBox(height: isMobile ? 8 : 12),
                        _buildObservacionesField(isMobile),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 32),
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
          child: Icon(
            Icons.add_circle,
            color: Color(0xFF475569),
            size: isMobile ? 20 : 24,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Text(
            'Nueva Matrícula',
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

  Widget _buildSeccionTitulo(String titulo, bool isMobile) {
    return Text(
      titulo,
      style: TextStyle(
        fontSize: isMobile ? 14 : 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDropdownCiclo(bool isMobile) {
    return DropdownButtonFormField<Ciclo>(
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
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Activo',
                    style: TextStyle(
                      fontSize: isMobile ? 9 : 10,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
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
        });
      },
    );
  }

  Widget _buildDropdownEstudiante(bool isMobile) {
    if (_estudiantes.isEmpty) {
      return _buildWarningBox('No hay estudiantes registrados en el sistema', isMobile);
    }

    return DropdownButtonFormField<Usuario>(
      value: _estudianteSeleccionado,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Estudiante',
        labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.person, size: isMobile ? 18 : 20),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 14,
        ),
      ),
      style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.black),
      items: _estudiantes.map((estudiante) {
        return DropdownMenuItem(
          value: estudiante,
          child: Text(
            '${estudiante.nombreCompleto} (${estudiante.codigo})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (estudiante) {
        setState(() {
          _estudianteSeleccionado = estudiante;
          _cursoSeleccionado = null;
        });
      },
    );
  }

  Widget _buildInfoEstudiante(bool isMobile) {
    if (_estudianteSeleccionado == null) return const SizedBox.shrink();
    
    final cicloActual = _estudianteSeleccionado!.cicloActual;
    final seccion = _estudianteSeleccionado!.seccion;
    
    String cicloRomano = '-';
    if (cicloActual != null) {
      const mapa = {
        1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
        6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X',
      };
      cicloRomano = mapa[cicloActual] ?? cicloActual.toString();
    }
    
    String infoTexto = cicloActual != null 
        ? 'Ciclo $cicloRomano'
        : 'Sin ciclo asignado';
    
    if (seccion != null && seccion.isNotEmpty) {
      infoTexto += ' - Sección $seccion';
    }
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: isMobile ? 16 : 18, color: Colors.blue.shade700),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              infoTexto,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCurso(bool isMobile) {
    final List<Curso> cursosFiltrados = _cicloSeleccionado != null && _estudianteSeleccionado != null
        ? _cursos.where((c) {
            final coincideCiclo = c.cicloId == _cicloSeleccionado!.id;
            final coincideNivel = c.nivel == _estudianteSeleccionado!.cicloActual;
            final coincideSeccion = c.seccion?.toUpperCase() == 
                                    _estudianteSeleccionado!.seccion?.toUpperCase();
            
            return coincideCiclo && coincideNivel && coincideSeccion;
          }).toList()
        : <Curso>[];

    if (_estudianteSeleccionado == null) {
      return _buildWarningBox(
        'Por favor, selecciona un estudiante primero para ver los cursos disponibles',
        isMobile,
      );
    }

    if (cursosFiltrados.isEmpty) {
      final cicloActual = _estudianteSeleccionado!.cicloActual;
      final seccion = _estudianteSeleccionado!.seccion;
      
      String cicloRomano = '-';
      if (cicloActual != null) {
        const mapa = {
          1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
          6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X',
        };
        cicloRomano = mapa[cicloActual] ?? cicloActual.toString();
      }
      
      String mensaje = 'No hay cursos disponibles para ';
      if (cicloActual != null) {
        mensaje += 'Ciclo $cicloRomano';
        if (seccion != null && seccion.isNotEmpty) {
          mensaje += ' - Sección $seccion';
        }
      } else {
        mensaje += 'este estudiante';
      }
      
      return _buildWarningBox(mensaje, isMobile);
    }

    return DropdownButtonFormField<Curso>(
      value: _cursoSeleccionado,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Curso',
        labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
        helperText: '${cursosFiltrados.length} curso(s) disponible(s)',
        helperStyle: TextStyle(
          color: Colors.green,
          fontSize: isMobile ? 11 : 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.book, size: isMobile ? 18 : 20),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 14,
        ),
      ),
      style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.black),
      items: cursosFiltrados.map<DropdownMenuItem<Curso>>((curso) {
        return DropdownMenuItem<Curso>(
          value: curso,
          child: Text(
            '${curso.nombre} - Sección ${curso.seccion ?? "?"}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (curso) {
        setState(() => _cursoSeleccionado = curso);
      },
    );
  }

  Widget _buildInfoCurso(bool isMobile) {
    if (_cursoSeleccionado == null) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: isMobile ? 16 : 18, color: Colors.blue.shade700),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              'Nivel ${_cursoSeleccionado!.nivelRomano} - Sección ${_cursoSeleccionado!.seccion ?? "?"} - Docente: ${_cursoSeleccionado!.docenteNombre ?? "Sin asignar"}',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownEstado(bool isMobile) {
    return DropdownButtonFormField<String>(
      value: _estadoSeleccionado,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Estado',
        labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.flag, size: isMobile ? 18 : 20),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 14,
        ),
      ),
      style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.black),
      items: const [
        DropdownMenuItem(value: 'activo', child: Text('Activo')),
        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
        DropdownMenuItem(value: 'condicional', child: Text('Condicional')),
      ],
      onChanged: (value) {
        setState(() => _estadoSeleccionado = value ?? 'activo');
      },
    );
  }

  Widget _buildObservacionesField(bool isMobile) {
    return TextField(
      controller: _observacionesController,
      maxLines: 3,
      style: TextStyle(fontSize: isMobile ? 13 : 14),
      decoration: InputDecoration(
        labelText: 'Observaciones',
        labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
        hintText: 'Ej: Matrícula con beca del 50%, Pendiente de pago...',
        hintStyle: TextStyle(fontSize: isMobile ? 12 : 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
      ),
    );
  }

  Widget _buildWarningBox(String mensaje, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF475569).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF475569).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Color(0xFF475569),
            size: isMobile ? 20 : 24,
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: Color(0xFF475569), 
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
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
        ElevatedButton(
          onPressed: _isLoading ? null : _crearMatricula,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF475569),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 10 : 12,
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: isMobile ? 16 : 20,
                  height: isMobile ? 16 : 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Crear Matrícula',
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
        ),
      ],
    );
  }
}