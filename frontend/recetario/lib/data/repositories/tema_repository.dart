import '../models/tema.dart';
import '../services/tema_service.dart';

class TemaRepository {
  // Obtener temas de un curso
  Future<List<Tema>> getTemasByCursoId(String cursoId) async {
    return await TemaService.getTemasByCursoId(cursoId);
  }

  // Obtener tema por ID (con materiales y tareas)
  Future<Tema> getTemaById(String temaId) async {
    // TODO: Implementar en TemaService si lo necesitas
    throw UnimplementedError('getTemaById no implementado aún');
  }

  // Crear tema
  Future<Tema> crearTema(Tema tema) async {
    return await TemaService.crearTema(tema);
  }

  // Actualizar tema
  Future<void> actualizarTema(String temaId, Map<String, dynamic> data) async {
    return await TemaService.actualizarTema(temaId, data);
  }

  // Eliminar tema
  Future<void> eliminarTema(String temaId) async {
    return await TemaService.eliminarTema(temaId);
  }
}