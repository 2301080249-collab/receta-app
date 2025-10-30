import 'package:flutter/material.dart';

/// Modelo para items del menú
class MenuItem {
  final String title;
  final IconData icon;
  final int index;
  final bool enabled;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.index,
    this.enabled = true,
  });
}

/// Menú lateral reutilizable con diseño gastronómico profesional
class SidebarMenu extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userRole;
  final List<MenuItem> menuItems;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const SidebarMenu({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.menuItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Gradiente sutil de gris carbón
        gradient: LinearGradient(
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF34495E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          SizedBox(height: 8),
          ...menuItems.map((item) => _buildMenuItem(context, item)),
          SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1), height: 1, thickness: 1),
          SizedBox(height: 8),
          _buildLogoutItem(context),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    IconData roleIcon;
    Color roleAccentColor;
    
    switch (userRole.toLowerCase()) {
      case 'administrador':
        roleIcon = Icons.admin_panel_settings_rounded;
        roleAccentColor = Color(0xFFE67E22); // Naranja
        break;
      case 'docente':
        roleIcon = Icons.school_rounded;
        roleAccentColor = Color(0xFF27AE60); // Verde
        break;
      case 'estudiante':
        roleIcon = Icons.person_rounded;
        roleAccentColor = Color(0xFF3498DB); // Azul
        break;
      default:
        roleIcon = Icons.person_rounded;
        roleAccentColor = Color(0xFFE67E22);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar con borde de acento
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  roleAccentColor,
                  roleAccentColor.withOpacity(0.6),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(
                roleIcon,
                size: 32,
                color: roleAccentColor,
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Nombre de usuario
          Text(
            userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          
          // Email
          Text(
            userEmail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          
          // Badge de rol
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleAccentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: roleAccentColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              userRole,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    if (!item.enabled) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title} - Próximamente'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF34495E),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: Colors.white.withOpacity(0.4),
                    size: 22,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isSelected = selectedIndex == item.index;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            onItemSelected(item.index);
            // Cerrar drawer en móvil
            if (MediaQuery.of(context).size.width <= 600) {
              Navigator.pop(context);
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Color(0xFFE67E22).withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Color(0xFFF39C12) : Colors.white,
                  size: 22,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Color(0xFFF39C12),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onLogout,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
                SizedBox(width: 16),
                Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Variante compacta del sidebar (solo iconos) - Mejorada
class CompactSidebar extends StatelessWidget {
  final List<MenuItem> menuItems;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CompactSidebar({
    Key? key,
    required this.menuItems,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF34495E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: menuItems.map((item) {
          final isSelected = selectedIndex == item.index;
          return Tooltip(
            message: item.title,
            preferBelow: false,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.enabled ? () => onItemSelected(item.index) : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: 64,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Color(0xFFE67E22).withOpacity(0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? Color(0xFFF39C12)
                        : (item.enabled ? Colors.white : Colors.white54),
                    size: 24,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}