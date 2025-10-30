import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/material.dart' as models;
import '../../data/repositories/material_repository.dart';

class DialogoCrearMaterial extends StatefulWidget {
  final String temaId;
  final models.Material? materialExistente;

  const DialogoCrearMaterial({
    Key? key,
    required this.temaId,
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

  Future<void> _seleccionarArchivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov', 'doc', 'docx'],
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
    
    if (!_esEdicion && _archivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un archivo')),
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

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion 
              ? 'Material actualizado exitosamente' 
              : 'Material creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
    // ✅ Detectar tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return AlertDialog(
      // ✅ Ancho responsivo
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      contentPadding: EdgeInsets.zero,
      
      title: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 16 : 20,
          isMobile ? 16 : 24,
          isMobile ? 8 : 12,
        ),
        child: Text(
          _esEdicion ? 'Editar Material' : 'Agregar Material',
          style: TextStyle(fontSize: isMobile ? 18 : 20),
        ),
      ),
      
      content: Container(
        // ✅ Ancho máximo adaptativo
        width: isMobile ? screenWidth * 0.9 : 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 8 : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Campo Título
                TextFormField(
                  controller: _tituloController,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Título *',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    hintText: 'Ej: Técnicas de amasado',
                    hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El título es obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isMobile ? 12 : 16),
                
                // ✅ Dropdown Tipo
                DropdownButtonFormField<String>(
                  value: _tipoSeleccionado,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'pdf',
                      child: Text(
                        '📄 PDF',
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'video',
                      child: Text(
                        '🎥 Video',
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'imagen',
                      child: Text(
                        '🖼️ Imagen',
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'documento',
                      child: Text(
                        '📝 Documento',
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'link',
                      child: Text(
                        '🔗 Enlace',
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _tipoSeleccionado = value!);
                  },
                ),
                SizedBox(height: isMobile ? 12 : 16),
                
                // ✅ Campo Descripción
                TextFormField(
                  controller: _descripcionController,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Descripción (Opcional)',
                    labelStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                  maxLines: isMobile ? 2 : 3,
                ),
                SizedBox(height: isMobile ? 12 : 16),
                
                // ✅ Área de archivo
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // NUEVO ARCHIVO SELECCIONADO
                      if (_archivoSeleccionado != null) ...[
                        Icon(
                          Icons.insert_drive_file,
                          size: isMobile ? 40 : 48,
                          color: _cambiarArchivo ? Colors.green : Colors.blue,
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          _cambiarArchivo ? 'Nuevo archivo' : 'Archivo seleccionado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 13 : 14,
                            color: _cambiarArchivo ? Colors.green : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _archivoSeleccionado!.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 12 : 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_archivoSeleccionado!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.grey,
                          ),
                        ),
                      ]
                      // ARCHIVO ACTUAL (MODO EDICIÓN)
                      else if (_esEdicion) ...[
                        Icon(
                          Icons.insert_drive_file,
                          size: isMobile ? 40 : 48,
                          color: Colors.blue,
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          'Archivo actual',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.materialExistente!.tamanoMb != null)
                          Text(
                            widget.materialExistente!.tamanoFormateado,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: Colors.grey,
                            ),
                          ),
                      ]
                      // SIN ARCHIVO (MODO CREAR)
                      else ...[
                        Icon(
                          Icons.cloud_upload,
                          size: isMobile ? 40 : 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          'Ningún archivo seleccionado',
                          style: TextStyle(fontSize: isMobile ? 13 : 14),
                        ),
                      ],
                      
                      SizedBox(height: isMobile ? 10 : 12),
                      
                      // ✅ Botón seleccionar archivo responsivo
                      SizedBox(
                        width: isMobile ? double.infinity : null,
                        child: OutlinedButton.icon(
                          onPressed: _seleccionarArchivo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: const BorderSide(color: Colors.green),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 12 : 12,
                            ),
                          ),
                          icon: Icon(
                            Icons.attach_file,
                            size: isMobile ? 18 : 20,
                          ),
                          label: Text(
                            _archivoSeleccionado != null
                                ? 'Cambiar archivo'
                                : (_esEdicion ? 'Cambiar archivo' : 'Seleccionar archivo'),
                            style: TextStyle(fontSize: isMobile ? 13 : 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  _esEdicion && !_cambiarArchivo
                      ? 'Puedes mantener el archivo actual o cambiarlo'
                      : 'Formatos: PDF, JPG, PNG, MP4, MOV, DOC, DOCX (máx 50MB)',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 8 : 0),
              ],
            ),
          ),
        ),
      ),
      
      // ✅ Botones de acción responsivos
      actions: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 0 : 8,
            isMobile ? 16 : 24,
            isMobile ? 16 : 20,
          ),
          child: isMobile
              // 📱 MÓVIL: Botones verticales
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _guardarMaterial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                          : Text(
                              _esEdicion ? 'Actualizar' : 'Crear Material',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                )
              // 💻 DESKTOP: Botones horizontales
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