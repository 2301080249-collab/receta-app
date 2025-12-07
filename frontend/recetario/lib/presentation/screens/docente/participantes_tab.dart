import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, File;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/matricula.dart';
import '../../../data/services/matricula_service.dart';
import '../../../core/utils/token_manager.dart';

import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

class ParticipantesTab extends StatefulWidget {
  final Curso curso;

  const ParticipantesTab({
    Key? key,
    required this.curso,
  }) : super(key: key);

  @override
  State<ParticipantesTab> createState() => _ParticipantesTabState();
}

class _ParticipantesTabState extends State<ParticipantesTab> {
  List<Matricula> _participantes = [];
  List<Matricula> _participantesFiltrados = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _searchQuery = '';
  String _filtroSeleccionado = 'Nombre';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ✅ Obtener URL base según la plataforma
  String _getBaseUrl() {
    // ⚠️ CAMBIA ESTAS URLs según tu configuración
    if (kIsWeb) {
      // Para desarrollo web local:
      return 'http://localhost:8080';
      
      // Para producción web, descomenta y usa:
      // return 'https://api.tuapp.com';
    } else {
      // Para desarrollo móvil:
      if (Platform.isAndroid) {
        // Emulador Android apunta a localhost de la PC:
        return 'http://10.0.2.2:8080';
        
        // Para dispositivo físico Android, usa la IP de tu PC:
        // return 'http://192.168.1.100:8080';
      } else {
        // iOS Simulator:
        return 'http://localhost:8080';
        
        // Para dispositivo iOS físico:
        // return 'http://192.168.1.100:8080';
      }
      
      // Para producción móvil, descomenta y usa:
      // return 'https://api.tuapp.com';
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token');

      final matriculas = await MatriculaService.listarMatriculasPorCurso(
        token: token,
        cursoId: widget.curso.id,
      );

      setState(() {
        _participantes = matriculas;
        _participantesFiltrados = matriculas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _filtrarParticipantes(String query) {
    setState(() {
      _searchQuery = query;
      
      if (query.isEmpty) {
        _participantesFiltrados = _participantes;
        return;
      }

      _participantesFiltrados = _participantes.where((matricula) {
        final queryLower = query.toLowerCase();
        
        switch (_filtroSeleccionado) {
          case 'Nombre':
            final nombre = (matricula.nombreEstudiante ?? '').toLowerCase();
            return nombre.contains(queryLower);
          
          case 'Código':
            final codigo = (matricula.codigoEstudiante ?? '').toLowerCase();
            return codigo.contains(queryLower);

          case 'Email':
            final email = (matricula.emailEstudiante ?? '').toLowerCase();
            return email.contains(queryLower);
          
          case 'Último acceso':
            final acceso = _calcularUltimoAcceso(matricula.createdAt).toLowerCase();
            return acceso.contains(queryLower);
          
          default:
            return false;
        }
      }).toList();
    });
  }

  // ✅ FUNCIÓN PRINCIPAL DE EXPORTACIÓN (Cross-platform)
  Future<void> _exportarAExcel() async {
    setState(() => _isExporting = true);

    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token');

      final baseUrl = _getBaseUrl();
      final url = '$baseUrl/api/admin/cursos/${widget.curso.id}/participantes/export';
      
      // Hacer petición HTTP con headers de autenticación
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
      );

      if (response.statusCode == 200) {
        final fileName = 'Participantes_${widget.curso.nombre}.xlsx';
        
       await _descargarArchivo(response.bodyBytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Archivo Excel descargado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al exportar: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }


 Future<void> _descargarArchivo(List<int> bytes, String fileName) async {
  try {
    await FileSaver.instance.saveFile(
      name: fileName.replaceAll('.xlsx', ''),
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  } catch (e) {
    throw Exception('Error al guardar archivo: $e');
  }
}

  String _calcularUltimoAcceso(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    
    if (diferencia.inDays > 0) {
      final horas = diferencia.inHours % 24;
      if (horas > 0) {
        return '${diferencia.inDays} días ${horas} horas';
      }
      return '${diferencia.inDays} días';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} horas';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }

  String _determinarRol(Matricula matricula) {
    return 'Estudiante';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE: Detectar tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 24 : 32)),
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
                  fontSize: isMobile ? 18 : (isTablet ? 24 : 28),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 16 : 32),

            // Buscador con filtro desplegable - RESPONSIVE
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
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
              child: isMobile
                  // Versión móvil: Columna
                  ? Column(
                      children: [
                        // Dropdown de filtros
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filtroSeleccionado,
                              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                              isExpanded: true,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                              items: ['Nombre', 'Código', 'Email', 'Último acceso']
                                  .map((filtro) => DropdownMenuItem(
                                        value: filtro,
                                        child: Row(
                                          children: [
                                            Icon(
                                              filtro == 'Nombre' 
                                                  ? Icons.person_outline
                                                  : filtro == 'Código'
                                                      ? Icons.numbers
                                                      : filtro == 'Email'
                                                          ? Icons.email_outlined
                                                          : Icons.access_time,
                                              size: 18,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(filtro),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filtroSeleccionado = value!;
                                  _filtrarParticipantes(_searchQuery);
                                });
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Campo de búsqueda
                        TextField(
                          onChanged: _filtrarParticipantes,
                          decoration: InputDecoration(
                            hintText: 'Buscar...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF37474F), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ BOTÓN EXPORTAR (Móvil - ancho completo)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportarAExcel,
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.file_download, size: 20),
                            label: Text(_isExporting ? 'Exportando...' : 'Exportar a Excel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  // Versión desktop/tablet: Fila
                  : Row(
                      children: [
                        // Dropdown de filtros
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filtroSeleccionado,
                              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                              items: ['Nombre', 'Código', 'Email', 'Último acceso']
                                  .map((filtro) => DropdownMenuItem(
                                        value: filtro,
                                        child: Row(
                                          children: [
                                            Icon(
                                              filtro == 'Nombre' 
                                                  ? Icons.person_outline
                                                  : filtro == 'Código'
                                                      ? Icons.numbers
                                                      : filtro == 'Email'
                                                          ? Icons.email_outlined
                                                          : Icons.access_time,
                                              size: 18,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(filtro),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filtroSeleccionado = value!;
                                  _filtrarParticipantes(_searchQuery);
                                });
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Campo de búsqueda
                        Expanded(
                          child: TextField(
                            onChanged: _filtrarParticipantes,
                            decoration: InputDecoration(
                              hintText: 'Buscar...',
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF37474F), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // ✅ BOTÓN EXPORTAR (Desktop/Tablet)
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : _exportarAExcel,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.file_download, size: 20),
                          label: Text(_isExporting ? 'Exportando...' : 'Exportar a Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: isMobile ? 16 : 24),

            // Contador de participantes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Mostrando ${_participantesFiltrados.length} participante${_participantesFiltrados.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tabla/Lista de participantes - RESPONSIVE
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_participantesFiltrados.isEmpty)
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
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron participantes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isMobile)
              // Versión móvil: Lista de cards
              ..._participantesFiltrados.map((matricula) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                        matricula.nombreEstudiante ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.numbers, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            matricula.codigoEstudiante ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              matricula.emailEstudiante ?? '-',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _determinarRol(matricula),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _calcularUltimoAcceso(matricula.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList()
            else
              // Versión desktop/tablet: Tabla
              Container(
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
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(2.5),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1.5),
                    },
                    children: [
                      // Header
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        children: [
                          _buildTableHeader('Nombre Completo'),
                          _buildTableHeader('Código'),
                          _buildTableHeader('Email'),
                          _buildTableHeader('Rol'),
                          _buildTableHeader('Último acceso'),
                        ],
                      ),
                      // Rows
                      ..._participantesFiltrados.map((matricula) {
                        return TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          children: [
                            _buildTableCell(
                              matricula.nombreEstudiante ?? 'Sin nombre',
                              isName: true,
                            ),
                            _buildTableCell(matricula.codigoEstudiante ?? '-'),
                            _buildTableCell(matricula.emailEstudiante ?? '-'),
                            _buildTableCell(_determinarRol(matricula)),
                            _buildTableCell(_calcularUltimoAcceso(matricula.createdAt)),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isName = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: isName ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}