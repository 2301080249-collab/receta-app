import 'package:flutter/material.dart';
import '../screens/docente/home_docente_screen.dart';
import '../screens/estudiante/home_estudiante_screen.dart';
import '../screens/shared/portafolio_screen.dart';
import '../../providers/user_provider.dart';
import 'package:provider/provider.dart';

class CustomAppHeader extends StatelessWidget {
  final String? selectedMenu; // 'portafolio', 'cursos'

  const CustomAppHeader({
    Key? key,
    this.selectedMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getRolActual() ?? 'estudiante';
    
    // Obtener inicial según el rol
    String userInitial = 'U';
    if (userProvider.estudiante != null) {
      userInitial = 'E';
    } else if (userProvider.docente != null) {
      userInitial = 'D';
    } else if (userProvider.administrador != null) {
      userInitial = 'A';
    }
    
    // 🎯 Detectar si es móvil
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
            
            // Texto - OCULTO en móvil
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
            
            // Botones de navegación - ADAPTADOS para móvil
            if (!isMobile) ...[
              // Vista WEB - Botones de texto
              TextButton(
                onPressed: () {
                  if (selectedMenu == 'portafolio') return;
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PortafolioScreen(),
                    ),
                    (route) => false,
                  );
                },
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
                onPressed: () {
                  if (selectedMenu == 'cursos') return;
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        if (userRole == 'docente') {
                          return const HomeDocenteScreen();
                        } else {
                          return const HomeEstudianteScreen();
                        }
                      },
                    ),
                    (route) => false,
                  );
                },
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
            ] else ...[
              // Vista MÓVIL - Botones con iconos
              IconButton(
                icon: Icon(
                  Icons.folder_outlined,
                  size: 22,
                  color: selectedMenu == 'portafolio' 
                      ? Colors.blue[700] 
                      : Colors.grey[700],
                ),
                onPressed: () {
                  if (selectedMenu == 'portafolio') return;
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PortafolioScreen(),
                    ),
                    (route) => false,
                  );
                },
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
                onPressed: () {
                  if (selectedMenu == 'cursos') return;
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        if (userRole == 'docente') {
                          return const HomeDocenteScreen();
                        } else {
                          return const HomeEstudianteScreen();
                        }
                      },
                    ),
                    (route) => false,
                  );
                },
                tooltip: 'Cursos',
                style: IconButton.styleFrom(
                  backgroundColor: selectedMenu == 'cursos' 
                      ? Colors.blue[50] 
                      : null,
                ),
              ),
            ],
            
            SizedBox(width: isMobile ? 4 : 16),
            
            // Notificaciones
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: isMobile ? 22 : 20,
              ),
              onPressed: () {
                // TODO: Ir a notificaciones
              },
              tooltip: 'Notificaciones',
              color: Colors.grey[700],
            ),
            
            SizedBox(width: isMobile ? 4 : 8),
            
            // Avatar
            Container(
              width: isMobile ? 32 : 32,
              height: isMobile ? 32 : 32,
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
          ],
        ),
      ),
    );
  }
}