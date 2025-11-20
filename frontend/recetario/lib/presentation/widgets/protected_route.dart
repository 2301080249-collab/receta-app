import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final List<String>? allowedRoles;

  const ProtectedRoute({
    Key? key,
    required this.child,
    this.allowedRoles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 1️⃣ Si está cargando, mostrar splash
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2️⃣ Si NO está autenticado, redirigir al login
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          });
          return const SizedBox.shrink();
        }

        // 3️⃣ Si hay roles permitidos, verificar
        if (allowedRoles != null && 
            !allowedRoles!.contains(authProvider.currentUser?.rol)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final route = AppRoutes.getRouteByRole(
              authProvider.currentUser?.rol ?? '',
            );
            Navigator.pushReplacementNamed(context, route);
          });
          return const SizedBox.shrink();
        }

        // 4️⃣ Todo OK, mostrar la pantalla
        return child;
      },
    );
  }
}