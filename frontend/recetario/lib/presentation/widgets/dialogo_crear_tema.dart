import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/tema.dart';
import '../../data/repositories/tema_repository.dart';
import '../../data/services/tema_service.dart';

/// Diálogo minimalista para crear o editar un tema
class DialogoCrearTema extends StatefulWidget {
  final String cursoId;
  final Tema? temaExistente;

  const DialogoCrearTema({
    Key? key,
    required this.cursoId,
    this.temaExistente,
  }) : super(key: key);

  @override
  State<DialogoCrearTema> createState() => _DialogoCrearTemaState();
}

class _DialogoCrearTemaState extends State<DialogoCrearTema> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  bool _isSubmitting = false;

  bool get _esEdicion => widget.temaExistente != null;

  @override
  void initState() {
    super.initState();
    
    if (_esEdicion) {
      _tituloController.text = widget.temaExistente!.titulo;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _guardarTema() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = TemaRepository();

      if (_esEdicion) {
        final nuevoTitulo = _tituloController.text.trim();
        
        await repository.actualizarTema(
          widget.temaExistente!.id,
          {'titulo': nuevoTitulo},
        );
        
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
                        const Text(
                          '¡Tema actualizado!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('El tema "$nuevoTitulo" se actualizó correctamente.'),
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
      } else {
        final tema = Tema(
          id: '',
          cursoId: widget.cursoId,
          titulo: _tituloController.text.trim(),
          descripcion: null,
          orden: widget.temaExistente?.orden ?? 1,
          activo: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.crearTema(tema);
        
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
                        const Text(
                          '¡Tema creado!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('El tema "${tema.titulo}" se creó exitosamente.'),
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
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
      title: Row(
        children: [
          Text(
            _esEdicion ? '✏️' : '📝',
            style: TextStyle(fontSize: kIsWeb ? 24 : (isMobile ? 20.sp : 24)),
          ),
          SizedBox(width: kIsWeb ? 8 : (isMobile ? 6.w : 8)),
          Text(
            _esEdicion ? 'Editar Tema' : 'Crear Tema',
            style: TextStyle(
              fontSize: kIsWeb ? 20 : (isMobile ? 18.sp : 20),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      
      content: SizedBox(
        width: kIsWeb ? 400 : (isMobile ? double.maxFinite : 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Nombre del tema *',
                  hintText: 'Ej: Técnicas de cocción',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.subject),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
                    vertical: kIsWeb ? 16 : (isMobile ? 12.h : 16),
                  ),
                ),
                style: TextStyle(
                  fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                enabled: !_isSubmitting,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del tema es obligatorio';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _guardarTema(),
              ),
              
              SizedBox(height: kIsWeb ? 8 : (isMobile ? 6.h : 8)),
              
              Text(
                _esEdicion 
                    ? 'Cambia el nombre del tema y guarda los cambios.'
                    : 'El tema se agregará al curso automáticamente.',
                style: TextStyle(
                  fontSize: kIsWeb ? 12 : (isMobile ? 11.sp : 12),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
      
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 16 : (isMobile ? 12.w : 16),
              vertical: kIsWeb ? 12 : (isMobile ? 10.h : 12),
            ),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
              color: Colors.grey[700],
            ),
          ),
        ),
        
        ElevatedButton(
          onPressed: _isSubmitting ? null : _guardarTema,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF455A64),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 24 : (isMobile ? 18.w : 24),
              vertical: kIsWeb ? 12 : (isMobile ? 10.h : 12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kIsWeb ? 8 : 6.r),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: kIsWeb ? 16 : (isMobile ? 14.h : 16),
                  width: kIsWeb ? 16 : (isMobile ? 14.w : 16),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _esEdicion ? 'Guardar' : 'Crear',
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : (isMobile ? 13.sp : 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}