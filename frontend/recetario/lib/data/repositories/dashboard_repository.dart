import '../models/dashboard_stats.dart';
import '../models/ciclo.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardRepository {
  /// Obtener estadísticas del dashboard con filtros
  Future<DashboardStats> obtenerEstadisticas({
    required String token,
    String? cicloId,
    String? seccion,
    String? estado,
  }) async {
    // Construir query params
    final queryParams = <String>[];
    if (cicloId != null && cicloId.isNotEmpty) {
      queryParams.add('ciclo_id=$cicloId');
    }
    if (seccion != null && seccion.isNotEmpty) {
      queryParams.add('seccion=$seccion');
    }
    if (estado != null && estado.isNotEmpty) {
      queryParams.add('estado=$estado');
    }

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final endpoint = '${ApiConstants.dashboardStats}$queryString';

    print('🔍 Dashboard Request: $endpoint');

    final response = await ApiService.get(
      endpoint,
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response);
    
    print('✅ Dashboard Response: ${data.toString().substring(0, 200)}...');

    return DashboardStats.fromJson(data);
  }

  // ✅ NUEVO: Obtener todos los ciclos
  Future<List<Ciclo>> obtenerTodosCiclos({required String token}) async {
    final endpoint = ApiConstants.listarCiclos; // 👈 Usa la constante que ya existe

    print('🔍 Ciclos Request: $endpoint');

    final response = await ApiService.get(
      endpoint,
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response);
    
    print('✅ Ciclos Response: ${data.length} ciclos encontrados');

    // El response es una lista de ciclos
    if (data is List) {
      return data.map((json) => Ciclo.fromJson(json)).toList();
    }

    throw Exception('Formato de respuesta inválido para ciclos');
  }
}