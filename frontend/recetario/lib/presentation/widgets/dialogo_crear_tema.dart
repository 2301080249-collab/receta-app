import 'package:flutter/material.dart';
import '../../data/models/tema.dart';
import '../../data/repositories/tema_repository.dart';

/// Diálogo minimalista para crear o editar un tema
/// 
/// USO:
/// - CREAR: DialogoCrearTema(cursoId: 'curso-123')
/// - EDITAR: DialogoCrearTema(cursoId: 'curso-123', temaExistente: tema)
class DialogoCrearTema extends StatefulWidget {
  final String cursoId;
  final Tema? temaExistente; // ✅ Si viene lleno, es EDITAR

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

  // ✅ Detectar si es modo CREAR o EDITAR
  bool get _esEdicion => widget.temaExistente != null;

  @override
  void initState() {
    super.initState();
    
    // ✅ Si estamos editando, pre-llenar el campo
    if (_esEdicion) {
      _tituloController.text = widget.temaExistente!.titulo;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  /// Guarda el tema (crear o actualizar según el modo)
  Future<void> _guardarTema() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = TemaRepository();

      if (_esEdicion) {
        // ✅ MODO EDITAR: Actualizar tema existente
        final nuevoTitulo = _tituloController.text.trim();
        
        // 🔍 DEBUG: Ver qué se está enviando
        print('🔍 EDITANDO TEMA:');
        print('   ID: ${widget.temaExistente!.id}');
        print('   Título nuevo: $nuevoTitulo');
        print('   Título anterior: ${widget.temaExistente!.titulo}');
        
        try {
          await repository.actualizarTema(
            widget.temaExistente!.id,
            {'titulo': nuevoTitulo},
          );
          
          print('✅ Tema actualizado en backend');
        } catch (e) {
          print('❌ ERROR al actualizar: $e');
          rethrow;
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Tema actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // ✅ MODO CREAR: Crear nuevo tema
        // Calcular orden automáticamente (puedes ajustar esta lógica)
        final tema = Tema(
          id: '',
          cursoId: widget.cursoId,
          titulo: _tituloController.text.trim(),
          descripcion: null,
          orden: widget.temaExistente?.orden ?? 1, // Usar orden del placeholder si existe
          activo: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.crearTema(tema);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Tema creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
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
    return AlertDialog(
      // ✅ Título dinámico según el modo
      title: Text(_esEdicion ? '✏️ Editar Tema' : '📝 Crear Tema'),
      
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Campo único: Nombre del tema
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Nombre del tema *',
                hintText: 'Ej: Técnicas de cocción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
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
            
            const SizedBox(height: 8),
            
            // ✅ Texto informativo
            Text(
              _esEdicion 
                  ? 'Cambia el nombre del tema y guarda los cambios.'
                  : 'El tema se agregará al curso automáticamente.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      
      actions: [
        // ✅ Botón Cancelar
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        
        // ✅ Botón Guardar/Crear (dinámico)
        ElevatedButton(
          onPressed: _isSubmitting ? null : _guardarTema,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}