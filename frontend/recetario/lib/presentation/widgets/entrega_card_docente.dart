import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/entrega.dart';

class EntregaCardDocente extends StatelessWidget {
  final Entrega entrega;
  final VoidCallback onCalificar;

  const EntregaCardDocente({
    Key? key,
    required this.entrega,
    required this.onCalificar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fechaFormateada =
        DateFormat('dd/MM/yyyy HH:mm').format(entrega.fechaEntrega);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entrega.estaCalificada
              ? Colors.green
              : Colors.orange,
          child: Text(
            entrega.estudiante?.nombreCompleto[0] ?? 'E',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          entrega.estudiante?.nombreCompleto ?? 'Estudiante',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entrega.titulo),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  fechaFormateada,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (entrega.entregaTardia) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${entrega.diasRetraso}d tarde',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ],
            ),
            if (entrega.estaCalificada) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Calificado: ${entrega.calificacion}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onCalificar,
          style: ElevatedButton.styleFrom(
            backgroundColor: entrega.estaCalificada ? Colors.blue : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            entrega.estaCalificada ? 'Ver' : 'Calificar',
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}