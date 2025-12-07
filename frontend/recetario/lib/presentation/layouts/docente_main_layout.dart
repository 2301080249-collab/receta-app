import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ✅ Import condicional para dart:html (solo web)
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import '../screens/docente/home_docente_screen.dart';
import '../screens/shared/portafolio_screen.dart';
import '../screens/docente/horario_docente_screen.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import 'package:provider/provider.dart';
import '../widgets/notification_bell.dart';

/// Layout principal del docente que mantiene el estado de las tabs
class DocenteMainLayout extends StatefulWidget {
  final int initialIndex;
  
  const DocenteMainLayout({
    Key? key,
    this.initialIndex = 0, // 0 = Portafolio, 1 = Cursos, 2 = Horario
  }) : super(key: key);

  @override
  State<DocenteMainLayout> createState() => _DocenteMainLayoutState();
}

class _DocenteMainLayoutState extends State<DocenteMainLayout> {
  late int _currentIndex;
  // ✅ NUEVO: Key única para forzar reconstrucción
  late Key _portafolioKey;
  late Key _cursosKey;
  late Key _horarioKey;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _regenerarKeys();
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🟢 DocenteMainLayout.initState()');
    print('🟢 initialIndex: $_currentIndex');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // ✅ NUEVO: Regenerar keys para forzar rebuild
  void _regenerarKeys() {
    _portafolioKey = UniqueKey();
    _cursosKey = UniqueKey();
    _horarioKey = UniqueKey();
  }

  @override
  void didUpdateWidget(DocenteMainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Si cambió el initialIndex, cambiar tab y regenerar keys
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
        _regenerarKeys();
      });
      print('🔄 initialIndex cambió a: $_currentIndex - Keys regenerados');
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _regenerarKeys(); // ✅ Regenerar keys al cambiar tab
      });
      
      if (kIsWeb) {
        _updateUrl(index);
      }
    }
  }

  void _updateUrl(int index) {
    try {
      String newUrl;
      switch (index) {
        case 0:
          newUrl = '/docente/home';
          break;
        case 1:
          newUrl = '/docente/home?tab=1';
          break;
        case 2:
          newUrl = '/docente/home?tab=2';
          break;
        default:
          newUrl = '/docente/home';
      }
      
      html.window.history.pushState(null, '', newUrl);
    } catch (e) {
      print('⚠️ Error actualizando URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildCustomHeader(),
          
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // ✅ Cada widget tiene key única que se regenera
                KeyedSubtree(
                  key: _portafolioKey,
                  child: const PortafolioScreen(),
                ),
                KeyedSubtree(
                  key: _cursosKey,
                  child: const HomeDocenteScreen(showHeader: false),
                ),
                KeyedSubtree(
                  key: _horarioKey,
                  child: const HorarioDocenteScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    String userInitial = 'D';
    String userName = 'Usuario';
    String userRole = 'docente';
    
    if (authProvider.currentUser != null) {
      userName = authProvider.currentUser!.nombreCompleto;
      userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'D';
      userRole = authProvider.currentUser!.rol;
    }
    
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
              // Logo
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
              
              if (isMobile)
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
              
              if (isMobile)
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
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _onTabSelected(2),
                      icon: Icon(
                        Icons.schedule_outlined,
                        size: 20,
                        color: _currentIndex == 2
                            ? Colors.blue[700]
                            : Colors.grey[600],
                      ),
                      tooltip: 'Horario',
                      style: IconButton.styleFrom(
                        backgroundColor: _currentIndex == 2
                            ? Colors.blue[50]
                            : null,
                      ),
                    ),
                  ],
                )
              else
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
                    TextButton(
                      onPressed: () => _onTabSelected(2),
                      style: TextButton.styleFrom(
                        backgroundColor: _currentIndex == 2
                            ? Colors.blue[50]
                            : null,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        'Horario',
                        style: TextStyle(
                          fontSize: 13,
                          color: _currentIndex == 2
                              ? Colors.blue[700]
                              : Colors.black87,
                          fontWeight: _currentIndex == 2
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              
              SizedBox(width: isMobile ? 4 : 16),
              
              const NotificationBell(),
              
              SizedBox(width: isMobile ? 4 : 8),
              
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 8,
                padding: EdgeInsets.zero,
                child: Container(
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
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Consumer<UserProvider>(
                          builder: (context, userProv, _) {
                            String? codigo;
                            if (userProv.estudiante != null) {
                              codigo = userProv.estudiante!.codigoEstudiante;
                            } else if (userProv.docente != null) {
                              codigo = userProv.docente!.codigoDocente;
                            } else if (userProv.administrador != null) {
                              codigo = userProv.administrador!.codigoAdmin;
                            }
                            
                            if (codigo != null && codigo.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  codigo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        Text(
                          userRole.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                  
                  PopupMenuItem<String>(
                    value: 'logout',
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 20,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'logout') {
                    _cerrarSesion();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text('Cerrar sesión'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (mounted) {
        Navigator.pop(context);
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }
}