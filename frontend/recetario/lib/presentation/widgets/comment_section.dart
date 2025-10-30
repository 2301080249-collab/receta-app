import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/portafolio_item.dart';

/// Widget para la sección de comentarios
class CommentSection extends StatefulWidget {
  final List<Comentario> comentarios;
  final Function(String) onAgregarComentario;
  final String nombreUsuario;

  const CommentSection({
    Key? key,
    required this.comentarios,
    required this.onAgregarComentario,
    required this.nombreUsuario,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enviarComentario() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    widget.onAgregarComentario(texto);
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.comment, size: 20),
              const SizedBox(width: 8),
              Text(
                'Comentarios (${widget.comentarios.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Lista de comentarios
        if (widget.comentarios.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aún no hay comentarios',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '¡Sé el primero en comentar!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.comentarios.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final comentario = widget.comentarios[index];
              return _buildComentarioItem(comentario);
            },
          ),

        const SizedBox(height: 16),

        // Input para nuevo comentario
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  widget.nombreUsuario[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // TextField
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviarComentario(),
                ),
              ),

              const SizedBox(width: 8),

              // Botón enviar
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).primaryColor,
                onPressed: _enviarComentario,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComentarioItem(Comentario comentario) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: Colors.primaries[
                comentario.usuario.hashCode % Colors.primaries.length],
            radius: 18,
            child: Text(
              comentario.usuario[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y fecha
                Row(
                  children: [
                    Text(
                      comentario.usuario,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatearFecha(comentario.fecha),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Texto del comentario
                Text(
                  comentario.texto,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inHours < 1) {
      return 'Hace ${diferencia.inMinutes}m';
    } else if (diferencia.inDays < 1) {
      return 'Hace ${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays}d';
    } else {
      return DateFormat('dd/MM/yyyy').format(fecha);
    }
  }
}