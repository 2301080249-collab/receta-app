import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../../core/mixins/loading_state_mixin.dart';
import '../../core/mixins/snackbar_mixin.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/notification_service.dart';

class CompartirRecetaDialog extends StatefulWidget {
  final String recetaId;
  final String tituloReceta;

  const CompartirRecetaDialog({
    Key? key,
    required this.recetaId,
    required this.tituloReceta,
  }) : super(key: key);

  @override
  State<CompartirRecetaDialog> createState() => _CompartirRecetaDialogState();
}

class _CompartirRecetaDialogState extends State<CompartirRecetaDialog>
    with LoadingStateMixin, SnackBarMixin {
  
  final _notificationService = NotificationService();
  final _searchController = TextEditingController();
  final _mensajeController = TextEditingController();
  
  List<Map<String, dynamic>> _todosLosUsuarios = [];
  List<Map<String, dynamic>> _usuariosFiltrados = [];
  Set<String> _usuariosSeleccionados = {};
  bool _loadingUsuarios = true;

  static const Color primaryBlue = Color(0xFF455A64);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color accentBlue = Color(0xFF455A64);

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _searchController.addListener(_filtrarUsuarios);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    try {
      setState(() => _loadingUsuarios = true);
      final usuarios = await _notificationService.obtenerUsuariosParaCompartir();
      if (!mounted) return;
      setState(() {
        _todosLosUsuarios = usuarios;
        _usuariosFiltrados = usuarios;
        _loadingUsuarios = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingUsuarios = false);
      showError('Error al cargar usuarios: $e');
    }
  }

  void _filtrarUsuarios() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _usuariosFiltrados = _todosLosUsuarios;
      } else {
        _usuariosFiltrados = _todosLosUsuarios.where((usuario) {
          final nombre = (usuario['nombre_completo'] ?? '').toString().toLowerCase();
          final codigo = (usuario['codigo'] ?? '').toString().toLowerCase();
          return nombre.contains(query) || codigo.contains(query);
        }).toList();
      }
    });
  }

  // ⚠️ CONFIRMACIÓN CON AWESOME DIALOG
  void _confirmarCompartir() {
    if (_usuariosSeleccionados.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
        customHeader: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.orange[600],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 60,
          ),
        ),
        title: 'Selección Requerida',
        desc: 'Por favor, selecciona al menos un usuario para compartir la receta.',
        btnOkText: 'Entendido',
        width: MediaQuery.of(context).size.width < 600 ? null : 500,
        btnOkOnPress: () {},
        btnOkColor: Colors.orange[600],
        dismissOnTouchOutside: false,
        headerAnimationLoop: false,
      ).show();
      return;
    }

    // Diálogo de confirmación
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      customHeader: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.share_rounded,
          color: Colors.white,
          size: 60,
        ),
      ),
      title: 'Confirmar Compartir',
      desc: '¿Estás seguro de compartir la receta "${widget.tituloReceta}" con ${_usuariosSeleccionados.length} usuario(s)?',
      btnCancelText: 'Cancelar',
      btnOkText: 'Compartir',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _compartir();
      },
      btnCancelColor: Colors.grey[600],
      btnOkColor: primaryBlue,
      dismissOnTouchOutside: false,
      headerAnimationLoop: false,
    ).show();
  }

  Future<void> _compartir() async {
    try {
      await executeWithLoading(() async {
        await _notificationService.compartirReceta(
          recetaId: widget.recetaId,
          usuariosIds: _usuariosSeleccionados.toList(),
          mensaje: _mensajeController.text.trim().isEmpty 
              ? null 
              : _mensajeController.text.trim(),
        );
      });

      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          customHeader: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          title: '¡Receta Compartida!',
          desc: 'La receta ha sido compartida exitosamente con ${_usuariosSeleccionados.length} usuario(s).',
          btnOkText: 'Aceptar',
          width: MediaQuery.of(context).size.width < 600 ? null : 500,
          btnOkOnPress: () {
            Navigator.of(context).pop(); // Cerrar el diálogo de compartir
          },
          btnOkColor: AppTheme.successColor,
          dismissOnTouchOutside: false,
          headerAnimationLoop: false,
        ).show();
      }
    } catch (e) {
      if (mounted) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.scale,
          customHeader: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.error_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          title: 'Error',
          desc: 'No se pudo compartir la receta: $e',
          btnOkText: 'Cerrar',
          width: MediaQuery.of(context).size.width < 600 ? null : 500,
          btnOkOnPress: () {},
          btnOkColor: AppTheme.errorColor,
          headerAnimationLoop: false,
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? screenWidth : 600,
          maxHeight: screenHeight * (isMobile ? 0.9 : 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con azul oscuro
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.share, color: Colors.white, size: isMobile ? 24 : 28),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Compartir Receta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de receta con azul claro
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentBlue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant, color: primaryBlue, size: isMobile ? 20 : 24),
                          SizedBox(width: isMobile ? 8 : 12),
                          Expanded(
                            child: Text(
                              widget.tituloReceta,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                                fontSize: isMobile ? 14 : 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Campo de mensaje personalizado
                    SizedBox(height: isMobile ? 12 : 16),
                    TextField(
                      controller: _mensajeController,
                      maxLines: isMobile ? 2 : 3,
                      maxLength: 200,
                      style: TextStyle(fontSize: isMobile ? 14 : 15),
                      decoration: InputDecoration(
                        labelText: 'Mensaje (opcional)',
                        labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                        hintText: 'Escribe un mensaje personalizado...',
                        hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                        prefixIcon: Icon(Icons.message_outlined, size: isMobile ? 20 : 24),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        helperText: isMobile ? 'Agrega un mensaje' : 'Agrega un mensaje para acompañar la receta',
                        helperStyle: TextStyle(fontSize: isMobile ? 11 : 12),
                        counterStyle: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 11 : 12),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 10 : 12,
                        ),
                      ),
                    ),
                    
                    // Buscador
                    SizedBox(height: isMobile ? 12 : 16),
                    TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: isMobile ? 14 : 15),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o código...',
                        hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                        prefixIcon: Icon(Icons.search, size: isMobile ? 20 : 24),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 10 : 12,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Contador de seleccionados
                    if (_usuariosSeleccionados.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${_usuariosSeleccionados.length} usuario(s) seleccionado(s)',
                          style: TextStyle(
                            color: accentBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Lista de usuarios
                    if (_loadingUsuarios)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 24 : 32),
                          child: CircularProgressIndicator(color: primaryBlue),
                        ),
                      )
                    else if (_usuariosFiltrados.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 24 : 32),
                          child: Column(
                            children: [
                              Icon(Icons.person_off, size: isMobile ? 40 : 48, color: Colors.grey[400]),
                              SizedBox(height: isMobile ? 6 : 8),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No hay usuarios disponibles'
                                    : 'No se encontraron usuarios',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isMobile ? 13 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: BoxConstraints(maxHeight: isMobile ? 250 : 300),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _usuariosFiltrados.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, index) {
                            final usuario = _usuariosFiltrados[index];
                            final usuarioId = usuario['id'].toString();
                            final nombre = usuario['nombre_completo'] ?? 'Sin nombre';
                            final codigo = usuario['codigo'];
                            final rol = usuario['rol'] ?? 'usuario';
                            final avatar = usuario['avatar_url'];
                            final isSelected = _usuariosSeleccionados.contains(usuarioId);
                            
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 4 : 8,
                              ),
                              leading: CircleAvatar(
                                radius: isMobile ? 18 : 20,
                                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                backgroundColor: Colors.grey[300],
                                child: avatar == null 
                                    ? Icon(Icons.person, color: Colors.grey[600], size: isMobile ? 18 : 20) 
                                    : null,
                              ),
                              title: Text(
                                nombre,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 14 : 15,
                                ),
                              ),
                              subtitle: codigo != null 
                                  ? Text(
                                      '$codigo • $rol',
                                      style: TextStyle(fontSize: isMobile ? 12 : 13),
                                    )
                                  : Text(rol, style: TextStyle(fontSize: isMobile ? 12 : 13)),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _usuariosSeleccionados.add(usuarioId);
                                    } else {
                                      _usuariosSeleccionados.remove(usuarioId);
                                    }
                                  });
                                },
                                activeColor: accentBlue,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _usuariosSeleccionados.remove(usuarioId);
                                  } else {
                                    _usuariosSeleccionados.add(usuarioId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Botón seleccionar/deseleccionar todos
                    if (!_loadingUsuarios && _usuariosFiltrados.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_usuariosSeleccionados.length == _usuariosFiltrados.length) {
                              _usuariosSeleccionados.clear();
                            } else {
                              _usuariosSeleccionados = _usuariosFiltrados.map((u) => u['id'].toString()).toSet();
                            }
                          });
                        },
                        icon: Icon(
                          _usuariosSeleccionados.length == _usuariosFiltrados.length 
                              ? Icons.clear_all 
                              : Icons.select_all,
                          size: isMobile ? 18 : 20,
                        ),
                        label: Text(
                          _usuariosSeleccionados.length == _usuariosFiltrados.length 
                              ? 'Deseleccionar todos' 
                              : 'Seleccionar todos',
                          style: TextStyle(fontSize: isMobile ? 13 : 14),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: accentBlue,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Footer con botones
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(fontSize: isMobile ? 14 : 15),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _confirmarCompartir,
                    icon: isLoading
                        ? SizedBox(
                            width: isMobile ? 14 : 16,
                            height: isMobile ? 14 : 16,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.share, size: isMobile ? 18 : 20),
                    label: Text(
                      isLoading ? 'Compartiendo...' : 'Compartir',
                      style: TextStyle(fontSize: isMobile ? 14 : 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 10 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}