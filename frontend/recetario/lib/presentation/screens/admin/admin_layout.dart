import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/snackbar_mixin.dart';

// Providers
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';

// Widgets reutilizables
import '../../widgets/sidebar_menu.dart';

// Screens
import 'dashboard_analytics_screen.dart';
import 'usuarios_screen.dart';
import 'ciclos_screen.dart';
import 'cursos_screen.dart';
import 'matriculas_screen.dart';

/// Layout principal del módulo de administrador
/// Responsabilidad: Estructura de navegación y sidebar para admin
class AdminLayout extends StatefulWidget {
  const AdminLayout({Key? key}) : super(key: key);

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> with SnackBarMixin {
  int _selectedIndex = 0;

  // Pantallas disponibles
  static const List<Widget> _screens = [
    DashboardAnalyticsScreen(),
    UsuariosScreen(),
    CiclosScreen(),
    CursosScreen(),
    MatriculasScreen(),
  ];

  // Items del menú lateral
  static const List<MenuItem> _menuItems = [
    MenuItem(title: 'Dashboard', icon: Icons.dashboard, index: 0),
    MenuItem(title: 'Usuarios', icon: Icons.people, index: 1),
    MenuItem(title: 'Ciclos', icon: Icons.calendar_today, index: 2),
    MenuItem(title: 'Cursos', icon: Icons.school, index: 3, enabled: true),
    MenuItem(
      title: 'Matrículas',
      icon: Icons.assignment_ind,
      index: 4,
      enabled: true,
    ),
  ];

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await authProvider.logout();
    userProvider.clear();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: _buildAppBar(context, user?.nombreCompleto),
      drawer: !isDesktop
          ? _buildDrawer(user?.nombreCompleto, user?.email, user?.rol)
          : null,
      body: isDesktop
          ? Row(
              children: [
                // Sidebar fijo en desktop
                Container(
                  width: 250,
                  color: AppTheme.primaryColor,
                  child: _buildSidebarContent(
                    user?.nombreCompleto,
                    user?.email,
                    user?.rol,
                  ),
                ),
                // Contenido principal
                Expanded(child: _screens[_selectedIndex]),
              ],
            )
          : _screens[_selectedIndex],
    );
  }

  // ==================== UI COMPONENTS ====================

  PreferredSizeWidget _buildAppBar(BuildContext context, String? userName) {
    return AppBar(
      title: const Text('Panel de Administrador'),
      backgroundColor: AppTheme.primaryColor,
      actions: [
        if (userName != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer(String? userName, String? userEmail, String? userRole) {
    return Drawer(
      child: Container(
        color: AppTheme.primaryColor,
        child: _buildSidebarContent(userName, userEmail, userRole),
      ),
    );
  }

  Widget _buildSidebarContent(
    String? userName,
    String? userEmail,
    String? userRole,
  ) {
    return SidebarMenu(
      userName: userName ?? 'Administrador',
      userEmail: userEmail ?? 'admin@sistema.com',
      userRole: userRole ?? 'administrador',
      menuItems: _menuItems,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) {
        if (index < _screens.length) {
          setState(() => _selectedIndex = index);
        }
      },
      onLogout: _handleLogout,
    );
  }
}