import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';

import '../../../data/models/curso.dart';
import '../../../data/models/matricula.dart';
import '../../../data/services/matricula_service.dart';
import '../../../core/utils/token_manager.dart';
import '../../../core/constants/api_constants.dart'; // ✅ IMPORTAR

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

  // ✅ FUNCIÓN CORREGIDA - USA ApiConstants.baseUrl
  Future<void> _exportarAExcel() async {
    setState(() => _isExporting = true);

    try {
      final token = await TokenManager.getToken();
      if (token == null) throw Exception('No hay token');

      // ✅ CORRECCIÓN: Usar ApiConstants en lugar de localhost
      final url = '${ApiConstants.baseUrl}${ApiConstants.exportarParticipantes(widget.curso.id)}';
      
      print('🔍 DEBUG - URL de exportación: $url'); // Para verificar
      
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
      print('❌ ERROR en exportación: $e'); // Para debug
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

            // Buscador con filtro desplegable
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
                  ? Column(
                      children: [
                        _buildFiltroDropdown(),
                        const SizedBox(height: 12),
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildExportButton(true),
                      ],
                    )
                  : Row(
                      children: [
                        _buildFiltroDropdown(),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSearchField()),
                        const SizedBox(width: 16),
                        _buildExportButton(false),
                      ],
                    ),
            ),

            SizedBox(height: isMobile ? 16 : 24),

            // Contador
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

            // Lista/Tabla
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_participantesFiltrados.isEmpty)
              _buildEmptyState()
            else if (isMobile)
              ..._participantesFiltrados.map((m) => _buildMobileCard(m)).toList()
            else
              _buildDesktopTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filtroSeleccionado,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
          isExpanded: MediaQuery.of(context).size.width < 600,
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
    );
  }

  Widget _buildSearchField() {
    return TextField(
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
    );
  }

  Widget _buildExportButton(bool isFullWidth) {
    final button = ElevatedButton.icon(
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
        padding: EdgeInsets.symmetric(
          horizontal: isFullWidth ? 0 : 24,
          vertical: isFullWidth ? 14 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildEmptyState() {
    return Container(
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
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCard(Matricula matricula) {
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
          _buildInfoRow(Icons.numbers, matricula.codigoEstudiante ?? '-'),
          _buildInfoRow(Icons.email_outlined, matricula.emailEstudiante ?? '-'),
          _buildInfoRow(Icons.person_outline, _determinarRol(matricula)),
          _buildInfoRow(Icons.access_time, _calcularUltimoAcceso(matricula.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
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
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(2.5),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              children: [
                _buildTableHeader('Nombre Completo'),
                _buildTableHeader('Código'),
                _buildTableHeader('Email'),
                _buildTableHeader('Rol'),
                _buildTableHeader('Último acceso'),
              ],
            ),
            ..._participantesFiltrados.map((m) {
              return TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                children: [
                  _buildTableCell(m.nombreEstudiante ?? 'Sin nombre', isName: true),
                  _buildTableCell(m.codigoEstudiante ?? '-'),
                  _buildTableCell(m.emailEstudiante ?? '-'),
                  _buildTableCell(_determinarRol(m)),
                  _buildTableCell(_calcularUltimoAcceso(m.createdAt)),
                ],
              );
            }).toList(),
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