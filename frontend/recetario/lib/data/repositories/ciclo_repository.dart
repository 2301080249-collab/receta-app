import '../services/ciclo_service.dart';
import '../models/ciclo.dart';

/// Repository para operaciones de ciclos académicos
/// Responsabilidad: Orquestar llamadas a CicloService y manejar lógica de negocio
class CicloRepository {
  // ==================== CREAR CICLO ====================

  /// Crear nuevo ciclo académico
  Future<Map<String, dynamic>> crearCiclo({
    required String token,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required int duracionSemanas,
  }) async {
    return await CicloService.crearCiclo(
      token: token,
      nombre: nombre,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      duracionSemanas: duracionSemanas,
    );
  }

  // ==================== LISTAR CICLOS ====================

  /// Obtener lista de todos los ciclos
  Future<List<Ciclo>> listarCiclos(String token) async {
    return await CicloService.listarCiclos(token);
  }

  // ==================== OBTENER CICLO POR ID ====================

  /// Obtener ciclo específico por ID
  Future<Ciclo> obtenerCicloPorId(String token, String cicloId) async {
    return await CicloService.obtenerCicloPorId(token, cicloId);
  }

  // ==================== ACTUALIZAR CICLO ====================

  /// Actualizar datos de un ciclo
  Future<void> actualizarCiclo({
    required String token,
    required String cicloId,
    String? nombre,
    String? fechaInicio,
    String? fechaFin,
    int? duracionSemanas,
    bool? activo,
  }) async {
    return await CicloService.actualizarCiclo(
      token: token,
      cicloId: cicloId,
      nombre: nombre,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      duracionSemanas: duracionSemanas,
      activo: activo,
    );
  }

  // ==================== ELIMINAR CICLO ====================

  /// Eliminar un ciclo
  Future<void> eliminarCiclo(String token, String cicloId) async {
    return await CicloService.eliminarCiclo(token, cicloId);
  }

  // ==================== ACTIVAR CICLO ====================

  /// Activar un ciclo (desactiva los demás automáticamente)
  Future<void> activarCiclo(String token, String cicloId) async {
    return await CicloService.activarCiclo(token, cicloId);
  }

  // ==================== DESACTIVAR CICLO ====================

  /// Desactivar un ciclo
  Future<void> desactivarCiclo(String token, String cicloId) async {
    return await CicloService.desactivarCiclo(token, cicloId);
  }

  // ==================== OBTENER CICLO ACTIVO ====================

  /// Obtener el ciclo actualmente activo
  Future<Ciclo?> obtenerCicloActivo(String token) async {
    return await CicloService.obtenerCicloActivo(token);
  }
}
