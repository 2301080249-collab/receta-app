import 'package:file_picker/file_picker.dart';
import '../models/entrega.dart';
import '../services/entrega_service.dart';

class EntregaRepository {
  // Crear entrega
  Future<Entrega> crearEntrega({
    required String tareaId,
    required String titulo,
    String? descripcion,
  }) async {
    return await EntregaService.crearEntrega(
      tareaId: tareaId,
      titulo: titulo,
      descripcion: descripcion,
    );
  }

  // Subir archivo (AHORA USA PlatformFile en lugar de File)
  Future<ArchivoEntrega> subirArchivo({
    required String entregaId,
    required PlatformFile archivo,
    void Function(int, int)? onProgress,
  }) async {
    return await EntregaService.subirArchivo(
      entregaId: entregaId,
      archivo: archivo,
      onProgress: onProgress,
    );
  }

  // ✅ NUEVO: Eliminar archivo individual
  Future<void> eliminarArchivoEntrega(String archivoId, String urlArchivo) async {
    return await EntregaService.eliminarArchivoEntrega(archivoId, urlArchivo);
  }

  // Editar entrega
  Future<void> editarEntrega({
    required String entregaId,
    required String titulo,
    String? descripcion,
  }) async {
    return await EntregaService.editarEntrega(
      entregaId: entregaId,
      titulo: titulo,
      descripcion: descripcion,
    );
  }

  // ✅ MEJORADO: Eliminar entrega con archivos
  Future<void> eliminarEntrega(String entregaId, List<ArchivoEntrega>? archivos) async {
    return await EntregaService.eliminarEntrega(entregaId, archivos);
  }

  // Obtener entrega por ID
  Future<Entrega> getEntregaById(String entregaId) async {
    return await EntregaService.getEntregaById(entregaId);
  }
}