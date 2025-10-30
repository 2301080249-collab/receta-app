import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../../../providers/auth_provider.dart';

// Widgets reutilizables
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;
  final String token;

  const ChangePasswordScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.changePassword(
        widget.userId,
        _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Contraseña actualizada exitosamente'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Detectar tamaño de pantalla
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    // ✅ Ajustes responsivos
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 32.0 : 48.0);
    final cardPadding = isMobile ? 24.0 : 32.0;
    final maxWidth = isMobile ? double.infinity : 450.0;
    final iconSize = isMobile ? 50.0 : 60.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cambiar Contraseña',
          style: TextStyle(fontSize: isMobile ? 18 : 20),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 16 : 24,
              ),
              child: Card(
                elevation: isMobile ? 4 : 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                ),
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: EdgeInsets.all(cardPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ícono
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            size: iconSize,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),

                        // Título
                        Text(
                          'Primera vez en el sistema',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 20 : 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Por seguridad, debes crear una nueva contraseña para continuar',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isMobile ? 24 : 32),

                        // Campos de contraseña
                        PasswordTextField(
                          controller: _passwordController,
                          label: 'Nueva Contraseña',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese una contraseña';
                            }
                            if (value.length < 8) {
                              return 'Mínimo 8 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        PasswordTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar Contraseña',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirme su contraseña';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),

                        // Requisitos
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requisitos de contraseña:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 12 : 13,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Mínimo 8 caracteres\n• Combina letras y números (recomendado)',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 24),

                        // Botón
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            return PrimaryButton(
                              text: 'Cambiar Contraseña',
                              isLoading: authProvider.isLoading,
                              onPressed: _handleChangePassword,
                            );
                          },
                        ),
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

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}