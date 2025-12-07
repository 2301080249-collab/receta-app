import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import 'package:provider/provider.dart';
import 'notification_bell.dart';
// ✅ NECESITAS IMPORTAR ESTOS LAYOUTS
import '../../presentation/layouts/estudiante_main_layout.dart';
import '../../presentation/layouts/docente_main_layout.dart';

class CustomAppHeader extends StatelessWidget {
  final String? selectedMenu;
  final bool fromCursoDetalle; // ✅ NUEVO: indica si viene desde detalle de curso

  const CustomAppHeader({
    Key? key,
    this.selectedMenu,
    this.fromCursoDetalle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // ✅ FIX: Usar authProvider.currentUser.rol directamente
    final userRole = authProvider.currentUser?.rol ?? 'estudiante';
    print('🔍 CustomAppHeader - Rol detectado: $userRole');
    
    String userInitial = 'U';
    String userName = 'Usuario';
    
    if (authProvider.currentUser != null) {
      userName = authProvider.currentUser!.nombreCompleto;
      userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    }
    
    final isMobile = MediaQuery.of(context).size.width < 768;
    
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 12,
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
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.school,
                        color: Colors.blue,
                        size: isMobile ? 20 : 32,
                      );
                    },
                  ),
                ),
              ),
            ),
            
            SizedBox(width: isMobile ? 8 : 12),
            
            if (!isMobile)
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
            
            if (!isMobile) ...[
              TextButton(
                onPressed: () => _navegarConPopUntil(context, userRole, 0),
                style: TextButton.styleFrom(
                  backgroundColor: selectedMenu == 'portafolio' 
                      ? Colors.blue[50] 
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Portafolio',
                  style: TextStyle(
                    fontSize: 13,
                    color: selectedMenu == 'portafolio' 
                        ? Colors.blue[700] 
                        : Colors.black87,
                    fontWeight: selectedMenu == 'portafolio' 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ),
              
              TextButton(
                onPressed: () => _navegarConPopUntil(context, userRole, 1),
                style: TextButton.styleFrom(
                  backgroundColor: selectedMenu == 'cursos' 
                      ? Colors.blue[50] 
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Cursos',
                  style: TextStyle(
                    color: selectedMenu == 'cursos' 
                        ? Colors.blue[700] 
                        : Colors.black87,
                    fontWeight: selectedMenu == 'cursos' 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              
              TextButton(
                onPressed: () => _navegarConPopUntil(context, userRole, 2),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text(
                  'Horario',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ] else ...[
              IconButton(
                icon: Icon(
                  Icons.folder_outlined,
                  size: 22,
                  color: selectedMenu == 'portafolio' 
                      ? Colors.blue[700] 
                      : Colors.grey[700],
                ),
                onPressed: () => _navegarConPopUntil(context, userRole, 0),
                tooltip: 'Portafolio',
                style: IconButton.styleFrom(
                  backgroundColor: selectedMenu == 'portafolio' 
                      ? Colors.blue[50] 
                      : null,
                ),
              ),
              
              IconButton(
                icon: Icon(
                  Icons.school_outlined,
                  size: 22,
                  color: selectedMenu == 'cursos' 
                      ? Colors.blue[700] 
                      : Colors.grey[700],
                ),
                onPressed: () => _navegarConPopUntil(context, userRole, 1),
                tooltip: 'Cursos',
                style: IconButton.styleFrom(
                  backgroundColor: selectedMenu == 'cursos' 
                      ? Colors.blue[50] 
                      : null,
                ),
              ),
              
              IconButton(
                icon: const Icon(
                  Icons.schedule_outlined,
                  size: 22,
                ),
                onPressed: () => _navegarConPopUntil(context, userRole, 2),
                tooltip: 'Horario',
                color: Colors.grey[700],
              ),
            ],
            
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.purple[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                  _cerrarSesion(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SOLUCIÓN DEFINITIVA: Navegar directamente sin popUntil
  void _navegarConPopUntil(BuildContext context, String userRole, int tabIndex) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 NAVEGACIÓN INICIADA');
    print('🚀 Tab destino: $tabIndex');
    print('🚀 Desde curso detalle: $fromCursoDetalle');
    print('🚀 User role: $userRole');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // ✅ SIMPLEMENTE REEMPLAZAR TODA LA PILA CON EL NUEVO MAINLAYOUT
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          print('🏗️ Construyendo nuevo ${userRole}MainLayout con initialIndex=$tabIndex');
          return userRole == 'docente'
              ? DocenteMainLayout(initialIndex: tabIndex)
              : EstudianteMainLayout(initialIndex: tabIndex);
        },
        settings: RouteSettings(name: '${userRole}MainLayout'),
      ),
      (route) {
        print('🗑️ Removiendo ruta: ${route.settings.name}');
        return false; // ✅ Eliminar TODAS las rutas
      },
    );
    
    print('✅ pushAndRemoveUntil ejecutado');
  }

  void _cerrarSesion(BuildContext context) async {
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

    if (confirmar == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (context.mounted) {
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