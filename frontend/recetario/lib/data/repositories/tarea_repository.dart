import '../models/tarea.dart';
import '../models/entrega.dart';
import '../services/tarea_service.dart';

class TareaRepository {
  // Crear tarea
  Future<Tarea> crearTarea(Tarea tarea) async {
    return await TareaService.crearTarea(tarea);
  }

  // Listar tareas por tema
  Future<List<Tarea>> getTareasByTemaId(String temaId) async {
    return await TareaService.getTareasByTemaId(temaId);
  }

  // Obtener entregas de una tarea (docente)
  Future<List<Entrega>> getEntregasByTareaId(String tareaId) async {
    return await TareaService.getEntregasByTareaId(tareaId);
  }

  // Obtener mi entrega (estudiante)
  Future<Entrega?> getMiEntrega(String tareaId) async {
    return await TareaService.getMiEntrega(tareaId);
  }

  // Calificar entrega
  Future<void> calificarEntrega({
    required String entregaId,
    required double calificacion,
    required String comentario,
  }) async {
    return await TareaService.calificarEntrega(
      entregaId: entregaId,
      calificacion: calificacion,
      comentario: comentario,
    );
  }

  // Actualizar tarea
  Future<void> actualizarTarea(String tareaId, Tarea tarea) async {
    return await TareaService.actualizarTarea(tareaId, tarea);
  }

  // Eliminar tarea
  Future<void> eliminarTarea(String tareaId) async {
    return await TareaService.eliminarTarea(tareaId);
  }
}