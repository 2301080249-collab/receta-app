import 'package:flutter/material.dart';
import '../../data/models/curso.dart';
import '../../data/models/tema.dart';

class CursoSidebarWidget extends StatelessWidget {
  final Curso curso;
  final List<Tema> temas;
  final bool isLoading;
  final bool isVisible;
  final Map<int, bool> temasExpandidos;
  final int? temaSeleccionado;
  final VoidCallback onClose;
  final Function(int) onTemaToggle;
  final Function(int)? onTemaSeleccionado;

  const CursoSidebarWidget({
    Key? key,
    required this.curso,
    required this.temas,
    required this.isLoading,
    required this.isVisible,
    required this.temasExpandidos,
    this.temaSeleccionado,
    required this.onClose,
    required this.onTemaToggle,
    this.onTemaSeleccionado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Botón cerrar (X)
          Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.black54),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Ocultar índice',
            ),
          ),

          // Lista de temas
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    children: [
                      ...List.generate(10, (index) {
                        final numeroTema = index + 1;
                        final temaReal = temas.firstWhere(
                          (t) => t.orden == numeroTema,
                          orElse: () => Tema(
                            id: '$numeroTema-placeholder',
                            cursoId: curso.id,
                            titulo: 'Tema $numeroTema',
                            descripcion: null,
                            orden: numeroTema,
                            activo: true,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        return _buildTemaItem(
                          orden: numeroTema,
                          tema: temaReal,
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemaItem({
    required int orden,
    required Tema tema,
  }) {
    final isExpanded = temasExpandidos[orden] ?? false;
    final isSelected = temaSeleccionado == orden;
    final tieneContenido = tema.id != '$orden-placeholder' &&
        ((tema.materiales?.isNotEmpty ?? false) ||
            (tema.tareas?.isNotEmpty ?? false));

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Column(
        children: [
          // ✅ Header del tema con fondo AZUL OSCURO cuando está seleccionado
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (tieneContenido) {
                  onTemaToggle(orden);
                }
                onTemaSeleccionado?.call(orden);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF37474F)  // ✅ Azul oscuro como las tabs
                      : Colors.white,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // ✅ Chevron > o v
                    Icon(
                      isExpanded 
                          ? Icons.keyboard_arrow_down 
                          : Icons.keyboard_arrow_right,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (tieneContenido ? Colors.black87 : Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    // ✅ CORREGIDO: Ahora muestra tema.titulo en lugar de hardcodeado
                    Expanded(
                      child: Text(
                        'Tema $orden: ${tema.titulo}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (tieneContenido ? Colors.black87 : Colors.grey[400]),
                        ),
                      ),
                    ),
                    // Badge con cantidad
                    if (tieneContenido)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(tema.materiales?.length ?? 0) + (tema.tareas?.length ?? 0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.blue[800],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido expandido (materiales y tareas)
          if (isExpanded && tieneContenido)
            Container(
              padding: const EdgeInsets.only(left: 32, right: 12, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                  right: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Materiales
                  if (tema.materiales != null && tema.materiales!.isNotEmpty) ...[
                    ...tema.materiales!.map((material) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                material.titulo,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],

                  // Tareas
                  if (tema.tareas != null && tema.tareas!.isNotEmpty) ...[
                    if (tema.materiales != null && tema.materiales!.isNotEmpty)
                      const SizedBox(height: 4),
                    ...tema.tareas!.map((tarea) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              size: 16,
                              color: Colors.pink[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tarea.titulo,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}