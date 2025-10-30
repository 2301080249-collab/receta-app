import 'api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/ciclo.dart';

/// Servicio para operaciones con ciclos académicos
class CicloService {
  /// Crear ciclo
  static Future<Map<String, dynamic>> crearCiclo({
    required String token,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required int duracionSemanas,
  }) async {
    final response = await ApiService.post(
      ApiConstants.crearCiclo,
      headers: ApiConstants.headersWithAuth(token),
      body: {
        'nombre': nombre,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
        'duracion_semanas': duracionSemanas,
      },
    );

    return ApiService.handleResponse(response);
  }

  /// Listar todos los ciclos
  static Future<List<Ciclo>> listarCiclos(String token) async {
    final response = await ApiService.get(
      ApiConstants.listarCiclos,
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response) as List;
    return data.map((json) => Ciclo.fromJson(json)).toList();
  }

  /// Obtener ciclo por ID
  static Future<Ciclo> obtenerCicloPorId(String token, String cicloId) async {
    final response = await ApiService.get(
      '${ApiConstants.listarCiclos}/$cicloId',
      headers: ApiConstants.headersWithAuth(token),
    );

    final data = ApiService.handleResponse(response);
    return Ciclo.fromJson(data);
  }

  /// Actualizar ciclo
  static Future<void> actualizarCiclo({
    required String token,
    required String cicloId,
    String? nombre,
    String? fechaInicio,
    String? fechaFin,
    int? duracionSemanas,
    bool? activo,
  }) async {
    final body = <String, dynamic>{};

    if (nombre != null) body['nombre'] = nombre;
    if (fechaInicio != null) body['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) body['fecha_fin'] = fechaFin;
    if (duracionSemanas != null) body['duracion_semanas'] = duracionSemanas;
    if (activo != null) body['activo'] = activo;

    final response = await ApiService.patch(
      '${ApiConstants.listarCiclos}/$cicloId',
      headers: ApiConstants.headersWithAuth(token),
      body: body,
    );

    ApiService.handleResponse(response);
  }

  /// Eliminar ciclo
  static Future<void> eliminarCiclo(String token, String cicloId) async {
    final response = await ApiService.delete(
      '${ApiConstants.listarCiclos}/$cicloId',
      headers: ApiConstants.headersWithAuth(token),
    );

    ApiService.handleResponse(response);
  }

  /// Activar ciclo
  static Future<void> activarCiclo(String token, String cicloId) async {
    final response = await ApiService.post(
      '${ApiConstants.listarCiclos}/$cicloId/activar',
      headers: ApiConstants.headersWithAuth(token),
      body: {},
    );

    ApiService.handleResponse(response);
  }

  /// Desactivar ciclo
  static Future<void> desactivarCiclo(String token, String cicloId) async {
    final response = await ApiService.post(
      '${ApiConstants.listarCiclos}/$cicloId/desactivar',
      headers: ApiConstants.headersWithAuth(token),
      body: {},
    );

    ApiService.handleResponse(response);
  }

  /// Obtener ciclo activo
  static Future<Ciclo?> obtenerCicloActivo(String token) async {
    try {
      final response = await ApiService.get(
        '${ApiConstants.listarCiclos}/activo',
        headers: ApiConstants.headersWithAuth(token),
      );

      final data = ApiService.handleResponse(response);
      return Ciclo.fromJson(data);
    } catch (e) {
      return null; // No hay ciclo activo
    }
  }
}
