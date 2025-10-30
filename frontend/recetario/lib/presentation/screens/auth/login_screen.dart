import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../config/routes.dart';

// Providers
import '../../../providers/auth_provider.dart';

// Widgets reutilizables
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/first_time_dialog.dart';

/// Pantalla de inicio de sesión
/// Responsabilidad: Autenticación y redirección según rol
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      final user = authProvider.currentUser!;
      final token = authProvider.token!;
      final primeraVez = result['primera_vez'];

      if (primeraVez == true) {
        // ✅ MOSTRAR DIALOG PARA PREGUNTAR
        await FirstTimeDialog.show(
          context,
          onChangeNow: () async {
            // Usuario eligió cambiar contraseña ahora
            await AppRoutes.navigateToChangePassword(
              context,
              userId: user.id,
              token: token,
            );
          },
          onSkip: () async {
            // Usuario eligió omitir
            try {
              await authProvider.skipPasswordChange();

              if (!mounted) return;

              // Navegar al dashboard según rol
              await AppRoutes.navigateToDashboard(context, user.rol);
            } catch (e) {
              if (!mounted) return;
              _mostrarError('Error al procesar: ${e.toString()}');
            }
          },
        );
      } else {
        // ✅ Usuario ya cambió su contraseña anteriormente
        await AppRoutes.navigateToDashboard(context, user.rol);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error al iniciar sesión: ${e.toString()}');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Detectar tamaño de pantalla
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    // ✅ Padding responsivo
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 32.0 : 48.0);
    final cardPadding = isMobile ? 24.0 : 32.0;
    
    // ✅ Ancho máximo según dispositivo
    final maxWidth = isMobile ? double.infinity : (isTablet ? 500.0 : 450.0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea( // ✅ Respeta notch y barras del sistema
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 16 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Card(
                elevation: isMobile ? 2 : 4, // ✅ Menor sombra en móvil
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, isMobile),
                        SizedBox(height: isMobile ? 24 : 32),
                        _buildForm(),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildLoginButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(BuildContext context, bool isMobile) {
    // ✅ Tamaños responsivos
    final iconSize = isMobile ? 50.0 : 60.0;
    final titleStyle = isMobile 
        ? AppTheme.heading2.copyWith(fontSize: 22) 
        : AppTheme.heading2;
    final subtitleStyle = AppTheme.bodyLarge.copyWith(
      color: Colors.grey[600],
      fontSize: isMobile ? 14 : 16,
    );

    return Column(
      children: [
        // Logo
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant,
            size: iconSize,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),

        // Título
        Text(
          'Sistema de Recetas',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Iniciar Sesión',
          style: subtitleStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================== FORMULARIO ====================

  Widget _buildForm() {
    return Column(
      children: [
        EmailTextField(
          controller: _emailController,
          hint: '2301080249@cenfotec.edu.pe',
        ),
        const SizedBox(height: 16),
        PasswordTextField(
          controller: _passwordController,
          label: 'Contraseña',
        ),
      ],
    );
  }

  // ==================== BOTÓN LOGIN ====================

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return PrimaryButton(
          text: 'Iniciar Sesión',
          isLoading: authProvider.isLoading,
          onPressed: authProvider.isLoading ? null : _handleLogin,
          icon: Icons.login,
          backgroundColor: AppTheme.primaryColor,
        );
      },
    );
  }
}