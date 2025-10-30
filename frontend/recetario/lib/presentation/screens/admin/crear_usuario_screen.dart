import 'package:flutter/material.dart';

// Core
import '../../../core/theme/app_theme.dart';
import '../../../core/mixins/loading_state_mixin.dart';
import '../../../core/mixins/snackbar_mixin.dart';
import '../../../core/mixins/auth_token_mixin.dart';
import '../../../core/utils/ciclo_converter.dart';

// Repositories
import '../../../data/repositories/admin_repository.dart';

// Widgets
import '../../widgets/custom_textfield.dart';
import '../../widgets/forms/form_section.dart';

/// Pantalla de creación / edición de usuarios - RESPONSIVA PARA MÓVIL
class CrearUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final bool esEdicion;

  const CrearUsuarioScreen({
    Key? key,
    this.usuario,
    this.esEdicion = false,
  }) : super(key: key);

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen>
    with LoadingStateMixin, SnackBarMixin, AuthTokenMixin {
  
  final AdminRepository _adminRepository = AdminRepository();
  final _formKey = GlobalKey<FormState>();

  // Estado
  String _tipoUsuario = 'estudiante';
  String _ciclo = 'I';

  // Controllers
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _seccionController = TextEditingController();
  final _especialidadController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _gradoAcademicoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosEdicion();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _codigoController.dispose();
    _telefonoController.dispose();
    _seccionController.dispose();
    _especialidadController.dispose();
    _departamentoController.dispose();
    _gradoAcademicoController.dispose();
    super.dispose();
  }

  void _cargarDatosEdicion() {
    if (!widget.esEdicion || widget.usuario == null) return;

    final u = widget.usuario!;
    _tipoUsuario = u['rol'] ?? 'estudiante';

    _nombreController.text = u['nombre_completo'] ?? '';
    _emailController.text = u['email'] ?? '';
    _codigoController.text = u['codigo'] ?? '';

    if (_tipoUsuario == 'estudiante' &&
        u['estudiantes'] is List &&
        (u['estudiantes'] as List).isNotEmpty) {
      final estudiante = u['estudiantes'][0];
      _ciclo = CicloConverter.toRoman(estudiante['ciclo_actual']);
      _telefonoController.text = estudiante['telefono'] ?? '';
      _seccionController.text = estudiante['seccion'] ?? '';
    } else if (_tipoUsuario == 'docente' &&
        u['docentes'] is List &&
        (u['docentes'] as List).isNotEmpty) {
      final docente = u['docentes'][0];
      _telefonoController.text = docente['telefono'] ?? '';
      _especialidadController.text = docente['especialidad'] ?? '';
      _gradoAcademicoController.text = docente['grado_academico'] ?? '';
      _departamentoController.text = docente['departamento'] ?? '';
    }
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await executeWithLoading(() async {
        final token = getToken();
        await _adminRepository.crearUsuario(
          nombreCompleto: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          codigo: _codigoController.text.trim(),
          rol: _tipoUsuario,
          token: token,
          telefono: _telefonoController.text.trim(),
          ciclo: _tipoUsuario == 'estudiante' ? _ciclo : null,
          seccion: _tipoUsuario == 'estudiante'
              ? _seccionController.text.trim()
              : null,
          especialidad: _tipoUsuario == 'docente'
              ? _especialidadController.text.trim()
              : null,
          gradoAcademico: _tipoUsuario == 'docente'
              ? _gradoAcademicoController.text.trim()
              : null,
          departamento: _tipoUsuario == 'docente'
              ? _departamentoController.text.trim()
              : null,
        );
      });

      showSuccess('Usuario creado exitosamente');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showError(e.toString());
    }
  }

  Future<void> _actualizarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final usuario = widget.usuario;
      if (usuario == null) throw Exception('No se encontró el usuario');

      await executeWithLoading(() async {
        final token = getToken();
        await _adminRepository.actualizarUsuario(
          id: usuario['id'],
          nombreCompleto: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          codigo: _codigoController.text.trim(),
          telefono: _telefonoController.text.trim(),
          rol: _tipoUsuario,
          ciclo: _tipoUsuario == 'estudiante' ? _ciclo : null,
          seccion: _tipoUsuario == 'estudiante'
              ? _seccionController.text.trim()
              : null,
          especialidad: _tipoUsuario == 'docente'
              ? _especialidadController.text.trim()
              : null,
          gradoAcademico: _tipoUsuario == 'docente'
              ? _gradoAcademicoController.text.trim()
              : null,
          departamento: _tipoUsuario == 'docente'
              ? _departamentoController.text.trim()
              : null,
          token: token,
        );
      });

      showSuccess('Usuario actualizado correctamente');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showError(e.toString());
    }
  }

  // ================== UI RESPONSIVO ==================
  @override
  Widget build(BuildContext context) {
    // ✅ Detectar tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.esEdicion ? 'Editar Usuario' : 'Crear Nuevo Usuario',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 700,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              boxShadow: isMobile
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : AppTheme.cardShadow,
            ),
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  _buildTipoUsuarioSection(isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  _buildDatosGeneralesSection(isMobile),
                  SizedBox(height: isMobile ? 20 : 24),
                  _buildPasswordInfo(isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  if (_tipoUsuario == 'estudiante')
                    _buildEstudianteSection(isMobile),
                  if (_tipoUsuario == 'docente')
                    _buildDocenteSection(isMobile),
                  SizedBox(height: isMobile ? 32 : 40),
                  _buildActionButtons(isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: AppTheme.formColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.formColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: isMobile ? 24 : 28,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.esEdicion ? 'Editar Usuario' : 'Crear Usuario',
                style: AppTheme.heading2.copyWith(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isMobile ? 3 : 4),
              Text(
                'Complete los datos para registrar un nuevo usuario',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipoUsuarioSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: AppTheme.formColor,
              size: isMobile ? 18 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Tipo de Usuario',
              style: AppTheme.heading3.copyWith(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 16),
        // ✅ En móvil: botones verticales, en desktop: horizontales
        isMobile
            ? Column(
                children: [
                  _buildRoleButton(
                    label: 'Estudiante',
                    icon: Icons.school_rounded,
                    value: 'estudiante',
                    color: AppTheme.formColor,
                    isMobile: true,
                  ),
                  const SizedBox(height: 10),
                  _buildRoleButton(
                    label: 'Docente',
                    icon: Icons.psychology_rounded,
                    value: 'docente',
                    color: AppTheme.formColor,
                    isMobile: true,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildRoleButton(
                      label: 'Estudiante',
                      icon: Icons.school_rounded,
                      value: 'estudiante',
                      color: AppTheme.formColor,
                      isMobile: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleButton(
                      label: 'Docente',
                      icon: Icons.psychology_rounded,
                      value: 'docente',
                      color: AppTheme.formColor,
                      isMobile: false,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildRoleButton({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    final isSelected = _tipoUsuario == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.esEdicion
            ? null
            : () => setState(() => _tipoUsuario = value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isMobile ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 14 : 12,
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: isMobile ? 22 : 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontSize: isMobile ? 15 : 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: isMobile ? 18 : 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatosGeneralesSection(bool isMobile) {
    return FormSection(
      icon: Icons.info_outline_rounded,
      title: 'Datos Generales',
      iconColor: AppTheme.formColor,
      children: [
        CustomTextField(
          controller: _nombreController,
          label: 'Nombre Completo *',
          hint: 'Ej: Juan Pérez García',
          prefixIcon: Icons.person_outline_rounded,
          validator: (value) =>
              value?.isEmpty ?? true ? 'El nombre es requerido' : null,
        ),
        SizedBox(height: isMobile ? 14 : 16),
        EmailTextField(
          controller: _emailController,
          hint: _tipoUsuario == 'estudiante'
              ? '2301080249@cenfotec.edu.pe'
              : '2301080249@cenfotec.edu.pe',
        ),
        SizedBox(height: isMobile ? 14 : 16),
        CustomTextField(
          controller: _codigoController,
          label: 'Código Institucional *',
          hint: _tipoUsuario == 'estudiante' ? '2301080249' : '2301080249',
          prefixIcon: Icons.badge_outlined,
          validator: (value) =>
              value?.isEmpty ?? true ? 'El código es requerido' : null,
        ),
      ],
    );
  }

  Widget _buildPasswordInfo(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        gradient: AppTheme.formGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.formColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppTheme.formColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.security_rounded,
              color: AppTheme.formColor,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contraseña Temporal',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.formColor,
                    fontSize: isMobile ? 13 : 14,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'El código institucional será la contraseña temporal - El usuario deberá cambiarla en el primer acceso',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: isMobile ? 11 : 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstudianteSection(bool isMobile) {
    return FormSection(
      icon: Icons.school_rounded,
      title: 'Información Académica',
      iconColor: AppTheme.formColor,
      children: [
        // ✅ En móvil: campos verticales, en desktop: horizontales
        isMobile
            ? Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _ciclo,
                    decoration: InputDecoration(
                      labelText: 'Ciclo *',
                      helperText: 'Ciclo académico actual',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(Icons.school_outlined, size: 20),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.accentColor,
                          width: 2,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'I', child: Text('Ciclo I')),
                      DropdownMenuItem(value: 'II', child: Text('Ciclo II')),
                      DropdownMenuItem(value: 'III', child: Text('Ciclo III')),
                      DropdownMenuItem(value: 'IV', child: Text('Ciclo IV')),
                      DropdownMenuItem(value: 'V', child: Text('Ciclo V')),
                      DropdownMenuItem(value: 'VI', child: Text('Ciclo VI')),
                      DropdownMenuItem(value: 'VII', child: Text('Ciclo VII')),
                      DropdownMenuItem(value: 'VIII', child: Text('Ciclo VIII')),
                      DropdownMenuItem(value: 'IX', child: Text('Ciclo IX')),
                      DropdownMenuItem(value: 'X', child: Text('Ciclo X')),
                    ],
                    onChanged: (value) => setState(() => _ciclo = value!),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    hint: '999999999',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ciclo,
                      decoration: InputDecoration(
                        labelText: 'Ciclo *',
                        helperText: 'Ciclo académico actual',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        prefixIcon:
                            const Icon(Icons.school_outlined, size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.accentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'I', child: Text('Ciclo I')),
                        DropdownMenuItem(value: 'II', child: Text('Ciclo II')),
                        DropdownMenuItem(value: 'III', child: Text('Ciclo III')),
                        DropdownMenuItem(value: 'IV', child: Text('Ciclo IV')),
                        DropdownMenuItem(value: 'V', child: Text('Ciclo V')),
                        DropdownMenuItem(value: 'VI', child: Text('Ciclo VI')),
                        DropdownMenuItem(value: 'VII', child: Text('Ciclo VII')),
                        DropdownMenuItem(value: 'VIII', child: Text('Ciclo VIII')),
                        DropdownMenuItem(value: 'IX', child: Text('Ciclo IX')),
                        DropdownMenuItem(value: 'X', child: Text('Ciclo X')),
                      ],
                      onChanged: (value) => setState(() => _ciclo = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _telefonoController,
                      label: 'Teléfono',
                      hint: '999999999',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _seccionController,
          label: 'Sección (Opcional)',
          hint: 'A, B, C...',
          prefixIcon: Icons.group_outlined,
        ),
      ],
    );
  }

  Widget _buildDocenteSection(bool isMobile) {
    return FormSection(
      icon: Icons.work_outline_rounded,
      title: 'Información Profesional',
      iconColor: AppTheme.formColor,
      children: [
        // ✅ En móvil: campos verticales, en desktop: horizontales
        isMobile
            ? Column(
                children: [
                  CustomTextField(
                    controller: _especialidadController,
                    label: 'Especialidad *',
                    hint: 'Repostería, Cocina Internacional, etc.',
                    prefixIcon: Icons.restaurant_rounded,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'La especialidad es requerida'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    hint: '999999999',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _especialidadController,
                      label: 'Especialidad *',
                      hint: 'Repostería, Cocina Internacional, etc.',
                      prefixIcon: Icons.restaurant_rounded,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'La especialidad es requerida'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _telefonoController,
                      label: 'Teléfono',
                      hint: '999999999',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _gradoAcademicoController,
          label: 'Grado Académico (Opcional)',
          hint: 'Técnico, Licenciado, Magíster...',
          prefixIcon: Icons.school_rounded,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _departamentoController,
          label: 'Departamento (Opcional)',
          hint: 'Cocina, Repostería...',
          prefixIcon: Icons.business_outlined,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : (widget.esEdicion
                          ? _actualizarUsuario
                          : _crearUsuario),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          widget.esEdicion
                              ? Icons.check_rounded
                              : Icons.person_add_rounded,
                          size: 20,
                        ),
                  label: Text(
                    widget.esEdicion ? 'Actualizar' : 'Crear Usuario',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.formColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppTheme.formColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : (widget.esEdicion
                            ? _actualizarUsuario
                            : _crearUsuario),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            widget.esEdicion
                                ? Icons.check_rounded
                                : Icons.person_add_rounded,
                            size: 18,
                          ),
                    label: Text(
                      widget.esEdicion ? 'Actualizar' : 'Crear Usuario',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.formColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppTheme.formColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}