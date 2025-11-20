import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/material.dart' as models;
import '../../data/repositories/material_repository.dart';
import '../../data/services/tema_service.dart'; // ✅ AGREGADO

class DialogoCrearMaterial extends StatefulWidget {
  final String temaId;
  final String cursoId; // ✅ AGREGADO
  final models.Material? materialExistente;

  const DialogoCrearMaterial({
    Key? key,
    required this.temaId,
    required this.cursoId, // ✅ AGREGADO
    this.materialExistente,
  }) : super(key: key);

  @override
  State<DialogoCrearMaterial> createState() => _DialogoCrearMaterialState();
}

class _DialogoCrearMaterialState extends State<DialogoCrearMaterial> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late String _tipoSeleccionado;
  PlatformFile? _archivoSeleccionado;
  bool _isSubmitting = false;
  bool _cambiarArchivo = false;

  bool get _esEdicion => widget.materialExistente != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _tituloController = TextEditingController(text: widget.materialExistente!.titulo);
      _descripcionController = TextEditingController(text: widget.materialExistente!.descripcion ?? '');
      _tipoSeleccionado = widget.materialExistente!.tipo;
    } else {
      _tituloController = TextEditingController();
      _descripcionController = TextEditingController();
      _tipoSeleccionado = 'pdf';
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  List<String> _obtenerExtensionesPermitidas() {
    switch (_tipoSeleccionado) {
      case 'pdf':
        return ['pdf'];
      case 'imagen':
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      case 'video':
        return ['mp4', 'mov', 'avi', 'mkv', 'webm'];
      case 'documento':
        return ['doc', 'docx', 'txt', 'odt'];
      case 'link':
        return [];
      default:
        return ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov', 'doc', 'docx'];
    }
  }

  String _obtenerTextoFormatosPermitidos() {
    switch (_tipoSeleccionado) {
      case 'pdf':
        return 'Solo archivos PDF';
      case 'imagen':
        return 'Formatos: JPG, PNG, GIF, WEBP';
      case 'video':
        return 'Formatos: MP4, MOV, AVI, MKV, WEBM';
      case 'documento':
        return 'Formatos: DOC, DOCX, TXT, ODT';
      case 'link':
        return 'No requiere archivo (solo URL)';
      default:
        return 'Formatos permitidos según tipo seleccionado';
    }
  }

  Future<void> _seleccionarArchivo() async {
    if (_tipoSeleccionado == 'link') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los enlaces no requieren archivo. Solo ingresa la URL en descripción.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final extensiones = _obtenerExtensionesPermitidas();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensiones,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _archivoSeleccionado = result.files.first;
          if (_esEdicion) {
            _cambiarArchivo = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  Future<void> _guardarMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar que haya archivo (excepto para tipo "link")
    if (!_esEdicion && _archivoSeleccionado == null && _tipoSeleccionado != 'link') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Debes seleccionar un archivo'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = MaterialRepository();
      String urlArchivo = _esEdicion ? widget.materialExistente!.urlArchivo : '';
      double? tamanoMb = _esEdicion ? widget.materialExistente!.tamanoMb : null;

      if (_archivoSeleccionado != null) {
        Map<String, dynamic> resultadoUpload;

        if (kIsWeb) {
          if (_archivoSeleccionado!.bytes == null) {
            throw Exception('No se pudieron cargar los bytes del archivo');
          }
          
          resultadoUpload = await repository.subirArchivo(
            bytes: _archivoSeleccionado!.bytes,
            nombreArchivo: _archivoSeleccionado!.name,
            temaId: widget.temaId,
          );
        } else {
          if (_archivoSeleccionado!.path == null) {
            throw Exception('No se pudo obtener la ruta del archivo');
          }
          
          resultadoUpload = await repository.subirArchivo(
            archivo: File(_archivoSeleccionado!.path!),
            nombreArchivo: _archivoSeleccionado!.name,
            temaId: widget.temaId,
          );
        }

        urlArchivo = resultadoUpload['url'];
        tamanoMb = resultadoUpload['size_mb'];
      }

      final material = models.Material(
        id: _esEdicion ? widget.materialExistente!.id : '',
        temaId: widget.temaId,
        titulo: _tituloController.text,
        tipo: _tipoSeleccionado,
        urlArchivo: urlArchivo,
        descripcion: _descripcionController.text.isEmpty
            ? null
            : _descripcionController.text,
        tamanoMb: tamanoMb,
        orden: _esEdicion ? widget.materialExistente!.orden : 1,
        activo: true,
        createdAt: _esEdicion ? widget.materialExistente!.createdAt : DateTime.now(),
      );

      if (_esEdicion) {
        await repository.actualizarMaterial(material);
      } else {
        await repository.crearMaterial(material);
      }

      // ✅ AGREGADO: Invalidar cache
      TemaService.invalidarCacheTemas(widget.cursoId);

      if (mounted) {
        Navigator.pop(context, true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _esEdicion ? '¡Material actualizado!' : '¡Material creado!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('El material "${material.titulo}" se ${_esEdicion ? "actualizó" : "creó"} correctamente.'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12.r),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 40 : (isMobile ? 16.w : 40),
        vertical: kIsWeb ? 40 : (isMobile ? 24.h : 40),
      ),
      contentPadding: EdgeInsets.zero,
      
      title: Padding(
        padding: EdgeInsets.fromLTRB(
          kIsWeb ? 24 : (isMobile ? 16.w : 24),
          kIsWeb ? 20 : (isMobile ? 16.h : 20),
          kIsWeb ? 24 : (isMobile ? 16.w : 24),
          kIsWeb ? 12 : (isMobile ? 8.h : 12),
        ),
        child: Text(
          _esEdicion ? 'Editar Material' : 'Agregar Material',
          style: TextStyle(
            fontSize: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      content: Container(
        width: kIsWeb ? 500 : (isMobile ? screenWidth * 0.9 : 500),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 24 : (isMobile ? 16.w : 24),
              vertical: kIsWeb ? 0 : (isMobile ? 8.h : 0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo Título
                TextFormField(
                  controller: _tituloController,
                  style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                  decoration: InputDecoration(
                    labelText: 'Título *',
                    labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    hintText: 'Ej: Técnicas de amasado',
                    hintStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                      vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El título es obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
                
                // Dropdown Tipo
                DropdownButtonFormField<String>(
                  value: _tipoSeleccionado,
                  style: TextStyle(
                    fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16),
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                      vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'pdf',
                      child: Text(
                        '📄 PDF',
                        style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'video',
                      child: Text(
                        '🎥 Video',
                        style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'imagen',
                      child: Text(
                        '🖼️ Imagen',
                        style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'documento',
                      child: Text(
                        '📝 Documento',
                        style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'link',
                      child: Text(
                        '🔗 Enlace',
                        style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoSeleccionado = value!;
                      _archivoSeleccionado = null;
                      _cambiarArchivo = false;
                    });
                  },
                ),
                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
                
                // Campo Descripción
                TextFormField(
                  controller: _descripcionController,
                  style: TextStyle(fontSize: kIsWeb ? 16 : (isMobile ? 14.sp : 16)),
                  decoration: InputDecoration(
                    labelText: 'Descripción (Opcional)',
                    labelStyle: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                      vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
                    ),
                  ),
                  maxLines: kIsWeb ? 3 : (isMobile ? 2 : 3),
                ),
                SizedBox(height: kIsWeb ? 16 : (isMobile ? 12.h : 16)),
                
                // Área de archivo
                Container(
                  padding: EdgeInsets.all(kIsWeb ? 16 : (isMobile ? 12.w : 16)),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
                  ),
                  child: Column(
                    children: [
                      if (_archivoSeleccionado != null) ...[
                        Icon(
                          Icons.insert_drive_file,
                          size: kIsWeb ? 48 : (isMobile ? 40.sp : 48),
                          color: _cambiarArchivo ? Colors.green : Colors.blue,
                        ),
                        SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
                        Text(
                          _cambiarArchivo ? 'Nuevo archivo' : 'Archivo seleccionado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                            color: _cambiarArchivo ? Colors.green : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _archivoSeleccionado!.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: kIsWeb ? 14 : (isMobile ? 12.sp : 14),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${(_archivoSeleccionado!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                          style: TextStyle(
                            fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                            color: Colors.grey,
                          ),
                        ),
                      ]
                      else if (_esEdicion) ...[
                        Icon(
                          Icons.insert_drive_file,
                          size: kIsWeb ? 48 : (isMobile ? 40.sp : 48),
                          color: Colors.blue,
                        ),
                        SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
                        Text(
                          'Archivo actual',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        if (widget.materialExistente!.tamanoMb != null)
                          Text(
                            widget.materialExistente!.tamanoFormateado,
                            style: TextStyle(
                              fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                              color: Colors.grey,
                            ),
                          ),
                      ]
                      else ...[
                        Icon(
                          Icons.cloud_upload,
                          size: kIsWeb ? 48 : (isMobile ? 40.sp : 48),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
                        Text(
                          'Ningún archivo seleccionado',
                          style: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                        ),
                      ],
                      
                      SizedBox(height: kIsWeb ? 12 : (isMobile ? 10.h : 12)),
                      
                      // Botón seleccionar archivo
                      SizedBox(
                        width: isMobile ? double.infinity : null,
                        child: OutlinedButton.icon(
                          onPressed: _seleccionarArchivo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: const BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(
                              horizontal: kIsWeb ? 20 : (isMobile ? 16.w : 20),
                              vertical: kIsWeb ? 12 : (isMobile ? 12.h : 12),
                            ),
                          ),
                          icon: Icon(
                            Icons.attach_file,
                            size: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
                          ),
                          label: Text(
                            _archivoSeleccionado != null
                                ? 'Cambiar archivo'
                                : (_esEdicion ? 'Cambiar archivo' : 'Seleccionar archivo'),
                            style: TextStyle(fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
                Text(
                  _esEdicion && !_cambiarArchivo
                      ? 'Puedes mantener el archivo actual o cambiarlo'
                      : _obtenerTextoFormatosPermitidos(),
                  style: TextStyle(
                    fontSize: kIsWeb ? 11 : (isMobile ? 10.sp : 11),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: kIsWeb ? 0 : (isMobile ? 8.h : 0)),
              ],
            ),
          ),
        ),
      ),
      
      // Botones de acción
      actions: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            kIsWeb ? 24 : (isMobile ? 16.w : 24),
            kIsWeb ? 8 : (isMobile ? 0 : 8),
            kIsWeb ? 24 : (isMobile ? 16.w : 24),
            kIsWeb ? 20 : (isMobile ? 16.h : 20),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _guardarMaterial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _esEdicion ? 'Actualizar' : 'Crear Material',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    SizedBox(height: 10.h),
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 14.h,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 15.sp),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _guardarMaterial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_esEdicion ? 'Actualizar' : 'Crear Material'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}