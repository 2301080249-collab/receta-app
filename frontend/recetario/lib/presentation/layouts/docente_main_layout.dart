import 'package:flutter/material.dart';
import '../screens/docente/home_docente_screen.dart';
import '../screens/shared/portafolio_screen.dart';
import '../../providers/user_provider.dart';
import 'package:provider/provider.dart';

/// Layout principal del docente que mantiene el estado de las tabs
class DocenteMainLayout extends StatefulWidget {
  final int initialIndex;
  
  const DocenteMainLayout({
    Key? key,
    this.initialIndex = 0, // 0 = Portafolio, 1 = Cursos
  }) : super(key: key);

  @override
  State<DocenteMainLayout> createState() => _DocenteMainLayoutState();
}

class _DocenteMainLayoutState extends State<DocenteMainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header personalizado con tabs RESPONSIVE
          _buildCustomHeader(),
          
          // Contenido - IndexedStack mantiene el estado de ambas pantallas
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                // Tab 0: Portafolio
                PortafolioScreen(),
                // Tab 1: Cursos
                HomeDocenteScreen(showHeader: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Obtener inicial según el rol
    String userInitial = 'D';
    if (userProvider.docente != null) {
      userInitial = 'D'; // D de Docente
    }
    
    // ✅ RESPONSIVE: Detectar tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            children: [
              // Logo - MÁS PEQUEÑO EN MÓVIL
              Container(
                width: isMobile ? 40 : 55,
                height: isMobile ? 40 : 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isMobile ? 4 : 6),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 4 : 6),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.school,
                          color: Colors.blue,
                          size: isMobile ? 24 : 32,
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: isMobile ? 8 : 12),
              
              // Texto - ADAPTADO PARA MÓVIL
              if (isMobile)
                // Versión móvil: Texto más corto
                const Expanded(
                  child: Text(
                    'CFT Cañete',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                // Versión desktop: Texto completo
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Centro de Formación Técnica',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'de Cañete',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              
              const Spacer(),
              
              // Tabs - ADAPTADAS PARA MÓVIL
              if (isMobile)
                // Versión móvil: Solo iconos
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _onTabSelected(0),
                      icon: Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: _currentIndex == 0
                            ? Colors.blue[700]
                            : Colors.grey[600],
                      ),
                      tooltip: 'Portafolio',
                      style: IconButton.styleFrom(
                        backgroundColor: _currentIndex == 0
                            ? Colors.blue[50]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _onTabSelected(1),
                      icon: Icon(
                        Icons.school_outlined,
                        size: 20,
                        color: _currentIndex == 1
                            ? Colors.blue[700]
                            : Colors.grey[600],
                      ),
                      tooltip: 'Cursos',
                      style: IconButton.styleFrom(
                        backgroundColor: _currentIndex == 1
                            ? Colors.blue[50]
                            : null,
                      ),
                    ),
                  ],
                )
              else
                // Versión desktop: Tabs con texto
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _onTabSelected(0),
                      style: TextButton.styleFrom(
                        backgroundColor: _currentIndex == 0
                            ? Colors.blue[50]
                            : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'Portafolio',
                        style: TextStyle(
                          fontSize: 13,
                          color: _currentIndex == 0
                              ? Colors.blue[700]
                              : Colors.black87,
                          fontWeight: _currentIndex == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onTabSelected(1),
                      style: TextButton.styleFrom(
                        backgroundColor: _currentIndex == 1
                            ? Colors.blue[50]
                            : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'Cursos',
                        style: TextStyle(
                          color: _currentIndex == 1
                              ? Colors.blue[700]
                              : Colors.black87,
                          fontWeight: _currentIndex == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              
              SizedBox(width: isMobile ? 4 : 16),
              
              // Notificaciones
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: isMobile ? 20 : 20,
                ),
                onPressed: () {
                  // TODO: Ir a notificaciones
                },
                tooltip: 'Notificaciones',
                color: Colors.grey[700],
                padding: EdgeInsets.all(isMobile ? 4 : 8),
              ),
              
              SizedBox(width: isMobile ? 4 : 8),
              
              // Avatar
              Container(
                width: isMobile ? 28 : 32,
                height: isMobile ? 28 : 32,
                decoration: BoxDecoration(
                  color: Colors.purple[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userInitial,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}