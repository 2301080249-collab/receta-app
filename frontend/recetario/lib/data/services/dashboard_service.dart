import '../models/dashboard_stats.dart';
import '../models/ciclo.dart'; // ✅ AGREGAR ESTA LÍNEA
import '../repositories/dashboard_repository.dart';

class DashboardService {
  final DashboardRepository _repository = DashboardRepository();

  /// Obtener estadísticas completas del dashboard con filtros opcionales
  Future<DashboardStats> obtenerEstadisticas({
    required String token,
    String? cicloId,
    String? seccion,
    String? estado,
  }) async {
    return await _repository.obtenerEstadisticas(
      token: token,
      cicloId: cicloId,
      seccion: seccion,
      estado: estado ?? 'todos',
    );
  }

  // ✅ AGREGAR ESTE MÉTODO
  /// Obtener todos los ciclos académicos
  Future<List<Ciclo>> obtenerTodosCiclos({required String token}) async {
    return await _repository.obtenerTodosCiclos(token: token);
  }
}