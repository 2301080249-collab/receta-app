import 'package:flutter/material.dart';
import 'package:recetario/data/models/horario_item.dart';
import 'package:recetario/data/services/horario_service.dart';
import 'package:recetario/data/services/token_service.dart';
import 'package:recetario/core/utils/horario_parser.dart';

class HorarioDocenteScreen extends StatefulWidget {
  const HorarioDocenteScreen({Key? key}) : super(key: key);

  @override
  State<HorarioDocenteScreen> createState() => _HorarioDocenteScreenState();
}

class _HorarioDocenteScreenState extends State<HorarioDocenteScreen> {
  bool _isLoading = true;
  List<HorarioItem> _horarios = [];
  String? _errorMessage;
  Map<String, Color> _cursosColores = {};

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  final List<Map<String, String>> _horas = [
    {'inicio': '8:00', 'fin': '8:45'},
    {'inicio': '8:45', 'fin': '9:30'},
    {'inicio': '9:30', 'fin': '10:15'},
    {'inicio': '10:15', 'fin': '11:00'},
    {'inicio': '11:00', 'fin': '11:45'},
    {'inicio': '11:45', 'fin': '12:30'},
    {'inicio': '12:30', 'fin': '13:15'},
    {'inicio': '13:15', 'fin': '14:00'},
    {'inicio': '14:00', 'fin': '14:45'},
    {'inicio': '14:45', 'fin': '15:30'},
    {'inicio': '15:30', 'fin': '16:15'},
    {'inicio': '16:15', 'fin': '17:00'},
    {'inicio': '17:00', 'fin': '17:45'},
    {'inicio': '17:45', 'fin': '18:30'},
    {'inicio': '18:30', 'fin': '19:15'},
    {'inicio': '19:15', 'fin': '20:00'},
    {'inicio': '20:00', 'fin': '20:45'},
  ];

  final List<List<Color>> _paletaColores = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFF30CFD0), Color(0xFF330867)],
    [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
    [Color(0xFFFF9A56), Color(0xFFFF6A88)],
    [Color(0xFF88D3CE), Color(0xFF6E45E2)],
    [Color(0xFFD299C2), Color(0xFFFEF9D7)],
  ];

  final Map<int, String> _nivelRomano = {
    1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
    6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X',
  };

  @override
  void initState() {
    super.initState();
    _cargarHorario();
  }

  Future<void> _cargarHorario() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenService.getToken();
      final userData = await TokenService.getUserData();
      
      if (token == null || userData == null) {
        throw Exception('No hay sesión activa');
      }

      final docenteId = userData['id'];
      final horarios = await HorarioService.getHorarioDocente(token, docenteId);

      _asignarColoresACursos(horarios);

      setState(() {
        _horarios = horarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _asignarColoresACursos(List<HorarioItem> horarios) {
    int colorIndex = 0;
    for (var horario in horarios) {
      if (!_cursosColores.containsKey(horario.nombreCurso)) {
        _cursosColores[horario.nombreCurso] = 
            _paletaColores[colorIndex % _paletaColores.length][0];
        colorIndex++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_horarios.isEmpty) {
      return _buildEmpty();
    }

    return _buildCalendarioSemanal();
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar horario',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarHorario,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes cursos asignados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacta al administrador',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarioSemanal() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return RefreshIndicator(
      onRefresh: _cargarHorario,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) _buildLeyendaLateral(),
          
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) ...[
                        _buildLeyendaMobile(),
                        const SizedBox(height: 16),
                      ],
                      _buildHeaderDias(isMobile),
                      _buildGridHorarios(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaLateral() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Mis Cursos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _horarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final curso = _horarios[index];
                final color = _cursosColores[curso.nombreCurso] ?? Colors.blue;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              curso.nombreCurso,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (curso.docenteNombre != null)
                        _buildInfoChip(Icons.person, curso.docenteNombre!),
                      const SizedBox(height: 4),
                      _buildInfoChip(Icons.layers, curso.cicloNombre),
                      const SizedBox(height: 4),
                      _buildInfoChip(Icons.group, curso.seccion ?? 'Sin sección'),
                      if (curso.nivel != null) ...[
                        const SizedBox(height: 4),
                        _buildInfoChip(Icons.stairs, 'Ciclo ${_nivelRomano[curso.nivel] ?? curso.nivel}'),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLeyendaMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Cursos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _horarios.map((curso) {
            final color = _cursosColores[curso.nombreCurso] ?? Colors.blue;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    curso.nombreCurso,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeaderDias(bool isMobile) {
    // ✅ Adaptación móvil: celdas más pequeñas
    final cellWidth = isMobile ? 70.0 : 120.0;
    final colHorasWidth = isMobile ? 90.0 : 115.0;
    
    return Row(
      children: [
        SizedBox(
          width: colHorasWidth,
          child: Container(),
        ),
        ..._diasSemana.map((dia) {
          final diasCortos = {
            'Lunes': 'LUN',
            'Martes': 'MAR',
            'Miércoles': 'MIÉ',
            'Jueves': 'JUE',
            'Viernes': 'VIE',
            'Sábado': 'SÁB',
          };
          
          return Container(
            width: cellWidth,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              diasCortos[dia] ?? dia.substring(0, 3).toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 10 : 13,
                letterSpacing: 0.5,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGridHorarios(bool isMobile) {
    // ✅ Adaptación móvil: celdas más pequeñas
    final cellWidth = isMobile ? 70.0 : 120.0;
    final cellHeight = isMobile ? 55.0 : 70.0;
    final colHorasWidth = isMobile ? 90.0 : 115.0;

    return Column(
      children: _horas.map((rango) {
        final horaInicio = rango['inicio']!;
        final horaFin = rango['fin']!;
        final horaFormateada = _convertirRangoA12Horas(horaInicio, horaFin);
        
        return Row(
          children: [
            Container(
              width: colHorasWidth,
              height: cellHeight,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!, width: 0.5),
              ),
              child: Center(
                child: Text(
                  horaFormateada,
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ..._diasSemana.map((dia) {
              final cursoEnHora = _obtenerCursoPorDiaHora(dia, horaInicio);
              
              return Container(
                width: cellWidth,
                height: cellHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
                child: cursoEnHora != null
                    ? _buildCeldaCurso(cursoEnHora, isMobile)
                    : null,
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  String _convertirRangoA12Horas(String horaInicio24, String horaFin24) {
    final inicio = _convertirHoraSimpleA12(horaInicio24);
    final fin = _convertirHoraSimpleA12(horaFin24);
    return '$inicio-$fin';
  }

  String _convertirHoraSimpleA12(String hora24) {
    final partes = hora24.split(':');
    int hora = int.parse(partes[0]);
    final minutos = partes[1];
    
    String periodo = 'AM';
    
    if (hora >= 12) {
      periodo = 'PM';
      if (hora > 12) {
        hora = hora - 12;
      }
    }
    
    if (hora == 0) {
      hora = 12;
    }
    
    return '$hora:$minutos$periodo';
  }

  Widget _buildCeldaCurso(HorarioItem curso, bool isMobile) {
    final color = _cursosColores[curso.nombreCurso] ?? Colors.blue;
    
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _mostrarDetalleCurso(curso),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 3 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  curso.nombreCurso,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 8 : 10,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                if (curso.seccion != null && curso.seccion!.isNotEmpty)
                  Text(
                    'Sección ${curso.seccion}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: isMobile ? 7 : 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 1),
                if (curso.nivel != null)
                  Text(
                    'Ciclo ${_nivelRomano[curso.nivel] ?? curso.nivel}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isMobile ? 6 : 8,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleCurso(HorarioItem curso) {
    final color = _cursosColores[curso.nombreCurso] ?? Colors.blue;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    curso.nombreCurso,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (curso.docenteNombre != null) ...[
                    _buildInfoRow(Icons.person, 'Docente', curso.docenteNombre!),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(Icons.layers, 'Ciclo', curso.cicloNombre),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.group, 'Sección', curso.seccion ?? 'Sin sección'),
                  if (curso.nivel != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.stairs, 'Nivel', 'Ciclo ${_nivelRomano[curso.nivel] ?? curso.nivel}'),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time, 'Horario', curso.horario ?? 'No especificado'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  HorarioItem? _obtenerCursoPorDiaHora(String dia, String hora) {
    for (var curso in _horarios) {
      if (curso.horario == null || curso.horario!.isEmpty) continue;
      
      final bloques = HorarioParser.parsear(curso.horario!);
      
      for (var bloque in bloques) {
        if (bloque.dia == dia && HorarioParser.estaEnRango(hora, bloque.horaInicio, bloque.horaFin)) {
          return curso;
        }
      }
    }
    
    return null;
  }
}