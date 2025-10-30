import 'package:flutter/material.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/matricula.dart';
import '../../../data/repositories/matricula_repository.dart';
import '../../../core/utils/token_manager.dart';

class ParticipantesEstudianteTab extends StatefulWidget {
  final Curso curso;

  const ParticipantesEstudianteTab({
    Key? key,
    required this.curso,
  }) : super(key: key);

  @override
  State<ParticipantesEstudianteTab> createState() =>
      _ParticipantesEstudianteTabState();
}

class _ParticipantesEstudianteTabState
    extends State<ParticipantesEstudianteTab> {
  final MatriculaRepository _matriculaRepository = MatriculaRepository();
  List<Matricula> _participantes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarParticipantes();
  }

  Future<void> _cargarParticipantes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final matriculas = await _matriculaRepository.listarMatriculasPorCurso(
        token: token,
        cursoId: widget.curso.id,
      );

      setState(() {
        _participantes = matriculas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar participantes: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  String _calcularUltimoAcceso(DateTime? fecha) {
    if (fecha == null) return 'Nunca';

    final diferencia = DateTime.now().difference(fecha);

    if (diferencia.inDays > 30) {
      final meses = (diferencia.inDays / 30).floor();
      return meses == 1 ? '1 mes' : '$meses meses';
    } else if (diferencia.inDays > 0) {
      return diferencia.inDays == 1
          ? '1 día'
          : '${diferencia.inDays} días';
    } else if (diferencia.inHours > 0) {
      return diferencia.inHours == 1
          ? '1 hora'
          : '${diferencia.inHours} horas';
    } else if (diferencia.inMinutes > 0) {
      return diferencia.inMinutes == 1
          ? '1 minuto'
          : '${diferencia.inMinutes} minutos';
    } else {
      return 'Ahora mismo';
    }
  }

  String _determinarRol(Matricula matricula) {
    return 'Estudiante';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del curso
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${widget.curso.nombre.toUpperCase()}-${widget.curso.nivelRomano}-${widget.curso.seccion ?? "A"}${widget.curso.nivel ?? ""}-${widget.curso.cicloNombre ?? "2023-I"}',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: isMobile ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: isMobile ? 16 : 32),

            // Contador de participantes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Mostrando ${_participantes.length} participante${_participantes.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contenido
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar participantes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _cargarParticipantes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_participantes.isEmpty)
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay participantes en este curso',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              isMobile ? _buildListaCards() : _buildTablaParticipantes(),
          ],
        ),
      ),
    );
  }

  // 📱 CARDS para móvil
  Widget _buildListaCards() {
    return Column(
      children: _participantes.map((matricula) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(matricula.nombreEstudiante ?? ''),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(matricula.nombreEstudiante ?? ''),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matricula.nombreEstudiante ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _determinarRol(matricula),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _calcularUltimoAcceso(matricula.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 💻 TABLA para web
  Widget _buildTablaParticipantes() {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header de la tabla
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 4,
                    child: Text(
                      'Nombre Completo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'Rol',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Último acceso',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filas de participantes
            ..._participantes.map((matricula) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    // Nombre con avatar
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          // Avatar circular con iniciales
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getAvatarColor(
                                matricula.nombreEstudiante ?? '',
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(
                                  matricula.nombreEstudiante ?? '',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nombre
                          Expanded(
                            child: Text(
                              matricula.nombreEstudiante ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Rol
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          _determinarRol(matricula),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Último acceso
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _calcularUltimoAcceso(matricula.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Helper para obtener iniciales del nombre
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  // Helper para obtener color del avatar basado en el nombre
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF1967D2), // Azul
      const Color(0xFF34A853), // Verde
      const Color(0xFFE37400), // Naranja
      const Color(0xFFD93025), // Rojo
      const Color(0xFF8E24AA), // Púrpura
      const Color(0xFF0097A7), // Cyan
      const Color(0xFF00897B), // Teal
      const Color(0xFFC2185B), // Rosa
    ];

    if (name.isEmpty) return colors[0];

    final hash = name.codeUnits.fold(0, (prev, unit) => prev + unit);
    return colors[hash % colors.length];
  }
}