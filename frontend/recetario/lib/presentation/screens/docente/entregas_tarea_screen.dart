import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/curso.dart';
import '../../../data/models/tema.dart';
import '../../../data/models/tarea.dart';
import '../../../data/models/entrega.dart';
import '../../../data/repositories/tarea_repository.dart';
import '../../../data/repositories/tema_repository.dart';
import '../../widgets/CursoSidebarWidget.dart';
import '../../widgets/custom_app_header.dart';
import 'calificar_entrega_screen.dart';

class EntregasTareaScreen extends StatefulWidget {
  final Tarea tarea;
  final Curso curso;

  const EntregasTareaScreen({
    Key? key,
    required this.tarea,
    required this.curso,
  }) : super(key: key);

  @override
  State<EntregasTareaScreen> createState() => _EntregasTareaScreenState();
}

class _EntregasTareaScreenState extends State<EntregasTareaScreen> {
  late TareaRepository _tareaRepository;
  late TemaRepository _temaRepository;
  List<Entrega> _entregas = [];
  List<Entrega> _entregasFiltradas = [];
  List<Tema> _temas = [];
  bool _isLoading = true;
  bool _isLoadingTemas = true;
  String _filtroActual = 'todas';
  String _busqueda = '';
  
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
    
    _cargarTemasSidebar();
    _cargarEntregas();
  }

  Future<void> _cargarTemasSidebar() async {
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

  Future<void> _cargarEntregas() async {
    setState(() => _isLoading = true);
    
    try {
      final entregas = await _tareaRepository.getEntregasByTareaId(widget.tarea.id);
      
      if (mounted) {
        setState(() {
          _entregas = entregas;
          _aplicarFiltros();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar entregas: $e')),
        );
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

  void _aplicarFiltros() {
    var filtradas = _entregas;

    switch (_filtroActual) {
      case 'sin_calificar':
        filtradas = filtradas.where((e) => !e.estaCalificada).toList();
        break;
      case 'calificadas':
        filtradas = filtradas.where((e) => e.estaCalificada).toList();
        break;
    }

    if (_busqueda.isNotEmpty) {
      filtradas = filtradas.where((e) {
        final nombreEstudiante = e.estudiante?.nombreCompleto.toLowerCase() ?? '';
        final searchLower = _busqueda.toLowerCase();
        return nombreEstudiante.contains(searchLower);
      }).toList();
    }

    setState(() => _entregasFiltradas = filtradas);
  }

  void _irACalificar(Entrega entrega) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalificarEntregaScreen(
          entrega: entrega,
          tarea: widget.tarea,
          curso: widget.curso,
        ),
      ),
    );

    if (resultado == true) {
      _cargarEntregas();
    }
  }

  Color _getColorFiltro(String filtro) {
    switch (filtro) {
      case 'todas':
        return Colors.blue;
      case 'sin_calificar':
        return Colors.orange;
      case 'calificadas':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final sinCalificar = _entregas.where((e) => !e.estaCalificada).length;
    final calificadas = _entregas.where((e) => e.estaCalificada).length;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          const CustomAppHeader(selectedMenu: 'cursos'),
          
          Expanded(
  child: Row(
    children: [
      // ✅ SIDEBAR - Solo visible si está abierto
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
            _buildContenido(sinCalificar, calificadas, isMobile),
            
            // ✅ Botón flotante cuando sidebar está oculto
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

  Widget _buildContenido(int sinCalificar, int calificadas, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', _entregas.length.toString(), Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Sin calificar', sinCalificar.toString(), Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Calificadas', calificadas.toString(), Colors.green),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Buscador y filtros - RESPONSIVE
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
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
              children: [
                // Buscador
                TextField(
                  onChanged: (value) {
                    setState(() => _busqueda = value);
                    _aplicarFiltros();
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                
                SizedBox(height: isMobile ? 12 : 16),
                
                // Filtros - En columna para móvil, fila para web
                isMobile
                    ? Column(
                        children: [
                          _buildFilterButton('Todas', 'todas'),
                          const SizedBox(height: 8),
                          _buildFilterButton('Sin calificar', 'sin_calificar'),
                          const SizedBox(height: 8),
                          _buildFilterButton('Calificadas', 'calificadas'),
                        ],
                      )
                    : Row(
                        children: [
                          _buildFilterButton('Todas', 'todas'),
                          const SizedBox(width: 8),
                          _buildFilterButton('Sin calificar', 'sin_calificar'),
                          const SizedBox(width: 8),
                          _buildFilterButton('Calificadas', 'calificadas'),
                        ],
                      ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lista de entregas - CARDS en móvil, TABLA en web
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entregasFiltradas.isEmpty
                    ? _buildEmptyState()
                    : isMobile
                        ? _buildListaCards()
                        : _buildTablaEntregas(),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCards() {
    return ListView.builder(
      itemCount: _entregasFiltradas.length,
      itemBuilder: (context, index) {
        final entrega = _entregasFiltradas[index];
        return _buildEntregaCard(entrega);
      },
    );
  }

  Widget _buildEntregaCard(Entrega entrega) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    (entrega.estudiante?.nombreCompleto ?? 'S')[0].toUpperCase(),
                    style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entrega.estudiante?.nombreCompleto ?? 'Sin nombre',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            _buildInfoRow(Icons.title, 'Título', entrega.titulo),
            const SizedBox(height: 8),
            
            _buildInfoRow(
              Icons.description_outlined,
              'Descripción',
              entrega.descripcion != null && entrega.descripcion!.isNotEmpty
                  ? entrega.descripcion!
                  : 'Sin descripción',
            ),
            const SizedBox(height: 8),
            
            _buildInfoRow(
              Icons.access_time,
              'Fecha',
              _formatearFecha(entrega.fechaEntrega),
            ),
            
            const Divider(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                entrega.estaCalificada
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${entrega.calificacion?.toStringAsFixed(0) ?? 0}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pending, color: Colors.orange, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Pendiente',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                
                ElevatedButton.icon(
                  onPressed: () => _irACalificar(entrega),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Ver', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay entregas para mostrar',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaEntregas() {
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
        child: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                children: [
                  _buildTableHeader('Estudiante'),
                  _buildTableHeader('Título'),
                  _buildTableHeader('Descripción'),
                  _buildTableHeader('Fecha entrega'),
                  _buildTableHeader('Calificación'),
                  _buildTableHeader('Acción'),
                ],
              ),
              ..._entregasFiltradas.map((entrega) {
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  children: [
                    _buildTableCell(entrega.estudiante?.nombreCompleto ?? 'Sin nombre', isName: true),
                    _buildTableCell(entrega.titulo),
                    _buildDescripcionCell(entrega.descripcion),
                    _buildTableCell(_formatearFecha(entrega.fechaEntrega)),
                    _buildCalificacionCell(entrega),
                    _buildAccionCell(entrega),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String valor) {
    final isSelected = _filtroActual == valor;
    final color = _getColorFiltro(valor);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SizedBox(
      width: isMobile ? double.infinity : null,
      child: ElevatedButton(
        onPressed: () {
          setState(() => _filtroActual = valor);
          _aplicarFiltros();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
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

  Widget _buildDescripcionCell(String? descripcion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        descripcion != null && descripcion.isNotEmpty
            ? (descripcion.length > 50 ? '${descripcion.substring(0, 50)}...' : descripcion)
            : 'Sin descripción',
        style: TextStyle(
          fontSize: 14,
          color: descripcion != null && descripcion.isNotEmpty ? Colors.black87 : Colors.grey[500],
          fontStyle: descripcion == null || descripcion.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildCalificacionCell(Entrega entrega) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: entrega.estaCalificada
          ? Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${entrega.calificacion?.toStringAsFixed(0) ?? 0}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.pending, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Pendiente',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAccionCell(Entrega entrega) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: ElevatedButton(
        onPressed: () => _irACalificar(entrega),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: const Text(
          'Ver',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}