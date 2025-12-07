import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/horario_item.dart';
import '../../core/constants/api_constants.dart';

class HorarioService {
  /// Obtener horario del docente
  static Future<List<HorarioItem>> getHorarioDocente(
    String token,
    String docenteId,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.horarioDocente(docenteId)}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // ✅ AÑADIDO: Omite página de advertencia
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HorarioItem.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener horario: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getHorarioDocente: $e');
      throw Exception('Error al cargar horario: $e');
    }
  }

  /// Obtener horario del estudiante
  static Future<List<HorarioItem>> getHorarioEstudiante(
    String token,
    String estudianteId,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.horarioEstudiante(estudianteId)}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // ✅ AÑADIDO: Omite página de advertencia
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HorarioItem.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener horario: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getHorarioEstudiante: $e');
      throw Exception('Error al cargar horario: $e');
    }
  }
}