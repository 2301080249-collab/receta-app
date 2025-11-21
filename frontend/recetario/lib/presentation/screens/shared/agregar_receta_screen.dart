import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/token_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/portafolio_provider.dart';
import '../../../data/models/portafolio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../../../config/env.dart';

/// Pantalla para agregar o editar recetas propias
class AgregarRecetaScreen extends StatefulWidget {
  final Portafolio? recetaParaEditar;
  
  const AgregarRecetaScreen({
    Key? key,
    this.recetaParaEditar,
  }) : super(key: key);

  @override
  State<AgregarRecetaScreen> createState() => _AgregarRecetaScreenState();
}

class _AgregarRecetaScreenState extends State<AgregarRecetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ingredientesController = TextEditingController();
  final _preparacionController = TextEditingController();
  final _videoController = TextEditingController();

  String? _categoriaSeleccionada;
  String _visibilidad = 'publica';

  File? _imagenSeleccionadaMovil;
  Uint8List? _imagenSeleccionadaWeb;
  String? _nombreArchivo;

  bool get _esEdicion => widget.recetaParaEditar != null;
  String? _imagenActualUrl;
  bool _cambioImagen = false;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    
    if (_esEdicion) {
      _cargarDatosReceta(widget.recetaParaEditar!);
    }
    
    _ingredientesController.addListener(_onIngredientesChanged);
    _preparacionController.addListener(_onPreparacionChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCategorias();
    });
  }

  void _cargarDatosReceta(Portafolio receta) {
    _tituloController.text = receta.titulo;
    _descripcionController.text = receta.descripcion ?? '';
    _ingredientesController.text = receta.ingredientes;
    _preparacionController.text = receta.preparacion;
    _videoController.text = receta.videoUrl ?? '';
    _categoriaSeleccionada = receta.categoriaId;
    _visibilidad = receta.visibilidad;
    
    if (receta.fotos.isNotEmpty) {
      _imagenActualUrl = receta.fotos.first;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _ingredientesController.dispose();
    _preparacionController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    if (!mounted) return;
    
    final provider = context.read<PortafolioProvider>();
    provider.limpiarCategorias();
    
    try {
      await provider.cargarCategorias();
      if (provider.categorias.isEmpty) {
        throw Exception('No se cargaron categorías');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error cargando categorías: $e');
      }
    }
  }

  void _onIngredientesChanged() {
    final text = _ingredientesController.text;
    if (text.endsWith('\n')) {
      final newText = text + '• ';
      
      _ingredientesController.removeListener(_onIngredientesChanged);
      _ingredientesController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      _ingredientesController.addListener(_onIngredientesChanged);
    }
  }

  void _onPreparacionChanged() {
    final text = _preparacionController.text;
    if (text.endsWith('\n')) {
      final lines = text.split('\n');
      int nextNumber = 1;
      
      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          final match = RegExp(r'^(\d+)\.').firstMatch(trimmed);
          if (match != null) {
            final num = int.tryParse(match.group(1) ?? '0') ?? 0;
            if (num >= nextNumber) {
              nextNumber = num + 1;
            }
          }
        }
      }
      
      final newText = text + '$nextNumber. ';
      
      _preparacionController.removeListener(_onPreparacionChanged);
      _preparacionController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      _preparacionController.addListener(_onPreparacionChanged);
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _nombreArchivo = pickedFile.name;

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imagenSeleccionadaWeb = bytes;
            _imagenSeleccionadaMovil = null;
            _cambioImagen = true;
          });
        } else {
          setState(() {
            _imagenSeleccionadaMovil = File(pickedFile.path);
            _imagenSeleccionadaWeb = null;
            _cambioImagen = true;
          });
        }
      }
    } catch (e) {
      _mostrarError('Error al seleccionar la imagen');
    }
  }
Future<String?> _subirImagen() async {
  try {
    print('📤 Subiendo imagen al backend...');
    
    final authToken = await TokenManager.getToken();
    if (authToken == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${Env.backendUrl}/api/portafolio/upload-imagen');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $authToken';

    if (kIsWeb) {
      if (_imagenSeleccionadaWeb == null) {
        throw Exception('No hay imagen seleccionada');
      }
      
      final fileName = _nombreArchivo ?? 'imagen.jpg';
      final ext = path.extension(fileName).toLowerCase();
      final contentType = ext == '.png' ? 'image/png' : 'image/jpeg';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _imagenSeleccionadaWeb!,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ));
    } else {
      if (_imagenSeleccionadaMovil == null) {
        throw Exception('No hay imagen seleccionada');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _imagenSeleccionadaMovil!.path,
        contentType: MediaType.parse(path.extension(_imagenSeleccionadaMovil!.path) == '.png' ? 'image/png' : 'image/jpeg'),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['url'];
    }
    
    throw Exception('Error: ${response.statusCode}');
  } catch (e) {
    print('❌ Error: $e');
    return null;
  }
}
  Future<void> _eliminarImagenAntigua(String urlImagen) async {
    try {
      final userId = await TokenManager.getUserId();
      if (userId == null) return;

      final uri = Uri.parse(urlImagen);
      final pathSegments = uri.pathSegments;
      
      final portafolioIndex = pathSegments.indexOf('portafolio');
      if (portafolioIndex == -1) return;
      
      final path = pathSegments.sublist(portafolioIndex).join('/');
      
      final client = Supabase.instance.client;
      await client.storage.from('archivos').remove([path]);
      
      print('✅ Imagen antigua eliminada del Storage: $path');
    } catch (e) {
      print('⚠️ Error eliminando imagen antigua: $e');
    }
  }

  Future<void> _actualizarReceta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSeleccionada == null) {
      _mostrarAdvertencia('Por favor selecciona una categoría');
      return;
    }

    if (_imagenActualUrl == null && 
        _imagenSeleccionadaWeb == null && 
        _imagenSeleccionadaMovil == null) {
      _mostrarAdvertencia('Por favor agrega una foto de tu receta');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fotoUrl;
      
      if (_cambioImagen) {
        final nuevaFotoUrl = await _subirImagen();
        if (nuevaFotoUrl == null) throw Exception('Error al subir la nueva imagen');
        
        fotoUrl = nuevaFotoUrl;
        
    
      } else {
        fotoUrl = _imagenActualUrl!;
      }

      final provider = context.read<PortafolioProvider>();
      final request = ActualizarPortafolioRequest(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        ingredientes: _ingredientesController.text.trim(),
        preparacion: _preparacionController.text.trim(),
        fotos: [fotoUrl],
        videoUrl: _videoController.text.trim().isEmpty
            ? null
            : _videoController.text.trim(),
        categoriaId: _categoriaSeleccionada!,
        visibilidad: _visibilidad,
      );

      final success = await provider.actualizarReceta(
        widget.recetaParaEditar!.id,
        request,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        
        if (success) {
          _mostrarExito('¡Receta actualizada exitosamente!');
        } else {
          _mostrarError(provider.error ?? 'Error al actualizar la receta');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _mostrarError('Error: $e');
      }
    }
  }

  Future<void> _crearReceta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSeleccionada == null) {
      _mostrarAdvertencia('Por favor selecciona una categoría');
      return;
    }

    if (_imagenSeleccionadaWeb == null && _imagenSeleccionadaMovil == null) {
      _mostrarAdvertencia('Por favor agrega una foto de tu receta');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final fotoUrl = await _subirImagen();
      if (fotoUrl == null) throw Exception('Error al subir la imagen');

      final provider = context.read<PortafolioProvider>();
      final request = CrearPortafolioRequest(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        ingredientes: _ingredientesController.text.trim(),
        preparacion: _preparacionController.text.trim(),
        fotos: [fotoUrl],
        videoUrl: _videoController.text.trim().isEmpty
            ? null
            : _videoController.text.trim(),
        categoriaId: _categoriaSeleccionada!,
        tipoReceta: 'propia',
        visibilidad: _visibilidad,
      );

      final success = await provider.crearReceta(request);

      if (mounted) {
        setState(() => _isUploading = false);
        
        if (success) {
          _mostrarExito('¡Receta creada exitosamente!');
        } else {
          _mostrarError(provider.error ?? 'Error al crear la receta');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _mostrarError('Error: $e');
      }
    }
  }

  Future<void> _guardarReceta() async {
    if (_esEdicion) {
      await _actualizarReceta();
    } else {
      await _crearReceta();
    }
  }

  // ⚠️ ADVERTENCIA CON AWESOME DIALOG
  void _mostrarAdvertencia(String mensaje) {
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
      title: 'Campos Incompletos',
      desc: mensaje,
      btnOkText: 'Entendido',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      btnOkOnPress: () {},
      btnOkColor: Colors.orange[600],
      dismissOnTouchOutside: false,
      headerAnimationLoop: false,
    ).show();
  }

  // ❌ ERROR CON AWESOME DIALOG
  void _mostrarError(String mensaje) {
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
      desc: mensaje,
      btnOkText: 'Cerrar',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      btnOkOnPress: () {},
      btnOkColor: AppTheme.errorColor,
      headerAnimationLoop: false,
    ).show();
  }

  // ✅ ÉXITO CON AWESOME DIALOG
  void _mostrarExito(String mensaje) {
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
      title: _esEdicion ? '¡Receta Actualizada!' : '¡Receta Creada!',
      desc: mensaje,
      btnOkText: 'Aceptar',
      width: MediaQuery.of(context).size.width < 600 ? null : 500,
      btnOkOnPress: () {
        Navigator.of(context).pop(true); // Cerrar pantalla y recargar
      },
      btnOkColor: AppTheme.successColor,
      dismissOnTouchOutside: false,
      headerAnimationLoop: false,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _esEdicion ? 'Editar Receta' : 'Nueva Receta',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWeb ? 32 : 0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 700 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageSelector(isWeb),
                  
                  Padding(
                    padding: EdgeInsets.all(isWeb ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isWeb ? 20 : 16),

                        if (isWeb)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _tituloController,
                                  label: 'Título',
                                  hint: 'Ej: Lomo Saltado Casero',
                                  icon: Icons.restaurant_menu,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Requerido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildCategoriaSelector()),
                            ],
                          )
                        else ...[
                          _buildTextField(
                            controller: _tituloController,
                            label: 'Título',
                            hint: 'Ej: Lomo Saltado Casero',
                            icon: Icons.restaurant_menu,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildCategoriaSelector(),
                        ],
                        
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _descripcionController,
                          label: 'Descripción (opcional)',
                          hint: 'Cuéntanos sobre esta receta...',
                          icon: Icons.description,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _ingredientesController,
                          label: 'Ingredientes',
                          hint: '• 500g de lomo\n• 2 cebollas\n• 3 tomates',
                          icon: Icons.list,
                          maxLines: isWeb ? 6 : 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Los ingredientes son obligatorios';
                            }
                            return null;
                          },
                          helperText: 'Presiona Enter para agregar viñetas automáticamente',
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _preparacionController,
                          label: 'Pasos de Preparación',
                          hint: '1. Cortar la carne\n2. Sazonar\n3. Saltear',
                          icon: Icons.format_list_numbered,
                          maxLines: isWeb ? 6 : 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Los pasos son obligatorios';
                            }
                            return null;
                          },
                          helperText: 'Presiona Enter para numerar automáticamente',
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _videoController,
                          label: 'URL del Video (opcional)',
                          hint: 'https://youtube.com/...',
                          icon: Icons.video_library,
                        ),
                        const SizedBox(height: 16),

                        _buildVisibilidadSelector(),
                        const SizedBox(height: 20),

                        if (_esEdicion)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: const BorderSide(color: Color(0xFF37474F)),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF37474F),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isUploading ? null : _guardarReceta,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9800),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isUploading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Actualizar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: _isUploading ? null : _guardarReceta,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Publicar Receta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector(bool isWeb) {
    final tieneImagen = _imagenSeleccionadaWeb != null || 
                        _imagenSeleccionadaMovil != null || 
                        (_esEdicion && _imagenActualUrl != null);

    return GestureDetector(
      onTap: _seleccionarImagen,
      child: Container(
        height: isWeb ? 250 : 200,
        margin: isWeb ? null : const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: tieneImagen ? Colors.black : Colors.grey[100],
          borderRadius: isWeb ? BorderRadius.circular(16) : BorderRadius.zero,
          border: isWeb
              ? Border.all(
                  color: tieneImagen ? Colors.transparent : Colors.grey[300]!,
                  width: 2,
                )
              : null,
        ),
        child: tieneImagen
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: isWeb ? BorderRadius.circular(14) : BorderRadius.zero,
                    child: _imagenSeleccionadaWeb != null
                        ? Image.memory(
                            _imagenSeleccionadaWeb!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : _imagenSeleccionadaMovil != null
                            ? Image.file(
                                _imagenSeleccionadaMovil!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.network(
                                _imagenActualUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _seleccionarImagen,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Agregar Foto de la Receta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF37474F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recomendado: 1200x800px',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
        prefixIcon: Icon(icon, size: 22),
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
          borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCategoriaSelector() {
    return Consumer<PortafolioProvider>(
      builder: (context, provider, _) {
        if (provider.categorias.isEmpty) {
          return const LinearProgressIndicator();
        }

        return DropdownButtonFormField<String>(
          value: _categoriaSeleccionada,
          decoration: InputDecoration(
            labelText: 'Categoría',
            prefixIcon: const Icon(Icons.category, size: 22),
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
              borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: provider.categorias.map((categoria) {
            return DropdownMenuItem(
              value: categoria.id,
              child: Row(
                children: [
                  if (categoria.icono != null) Text(categoria.icono!, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(categoria.nombre, style: const TextStyle(fontSize: 15)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _categoriaSeleccionada = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Selecciona una categoría';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildVisibilidadSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildVisibilidadChip(
            label: 'Pública',
            icon: Icons.public,
            value: 'publica',
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildVisibilidadChip(
            label: 'Privada',
            icon: Icons.lock,
            value: 'privada',
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilidadChip({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final isSelected = _visibilidad == value;
    
    return GestureDetector(
      onTap: () {
        setState(() => _visibilidad = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActualizarPortafolioRequest {
  final String titulo;
  final String? descripcion;
  final String ingredientes;
  final String preparacion;
  final List<String> fotos;
  final String? videoUrl;
  final String categoriaId;
  final String visibilidad;

  ActualizarPortafolioRequest({
    required this.titulo,
    this.descripcion,
    required this.ingredientes,
    required this.preparacion,
    required this.fotos,
    this.videoUrl,
    required this.categoriaId,
    this.visibilidad = 'publica',
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'ingredientes': ingredientes,
      'preparacion': preparacion,
      'fotos': fotos,
      'video_url': videoUrl,
      'categoria_id': categoriaId,
      'visibilidad': visibilidad,
    };
  }
}