import 'package:flutter/foundation.dart';
import '../data/models/estudiante.dart';
import '../data/models/docente.dart';
import '../data/models/administrador.dart';

/// Provider para datos extendidos del usuario según su rol
class UserProvider with ChangeNotifier {
  // Datos específicos por rol
  Estudiante? _estudiante;
  Docente? _docente;
  Administrador? _administrador;

  // Configuraciones de usuario
  bool _notificacionesActivas = true;

  // Getters
  Estudiante? get estudiante => _estudiante;
  Docente? get docente => _docente;
  Administrador? get administrador => _administrador;
  bool get notificacionesActivas => _notificacionesActivas;

  // ==================== CARGAR DATOS POR ROL ====================

  /// Cargar datos de estudiante
  void setEstudiante(Estudiante estudiante) {
    _estudiante = estudiante;
    _docente = null;
    _administrador = null;
    notifyListeners();
  }

  /// Cargar datos de docente
  void setDocente(Docente docente) {
    _docente = docente;
    _estudiante = null;
    _administrador = null;
    notifyListeners();
  }

  /// Cargar datos de administrador
  void setAdministrador(Administrador admin) {
    _administrador = admin;
    _estudiante = null;
    _docente = null;
    notifyListeners();
  }

  // ==================== INFORMACIÓN PARA UI ====================

  /// Obtener información adicional para mostrar en el perfil
  String getInfoAdicional() {
    if (_estudiante != null) {
      final seccion = _estudiante!.seccion?.isNotEmpty == true
          ? ' - ${_estudiante!.seccion}'
          : '';
      return 'Nivel ${_estudiante!.cicloActual}$seccion';
    }

    if (_docente != null) {
      return _docente!.especialidad;
    }

    if (_administrador != null) {
      return _administrador!.departamento ?? 'Administrador';
    }

    return '';
  }

  /// Obtener código institucional
  String? getCodigo() {
    if (_estudiante != null) return _estudiante!.codigoEstudiante;
    if (_docente != null) return _docente!.codigoDocente;
    if (_administrador != null) return _administrador!.codigoAdmin;
    return null;
  }

  /// Obtener tipo de rol actual
  String? getRolActual() {
    if (_estudiante != null) return 'estudiante';
    if (_docente != null) return 'docente';
    if (_administrador != null) return 'administrador';
    return null;
  }

  // ==================== CONFIGURACIONES ====================

  /// Activar/desactivar notificaciones
  void toggleNotificaciones() {
    _notificacionesActivas = !_notificacionesActivas;
    notifyListeners();
    // TODO: Guardar en SharedPreferences
  }

  /// Establecer estado de notificaciones
  void setNotificaciones(bool activas) {
    _notificacionesActivas = activas;
    notifyListeners();
  }

  // ==================== UTILIDADES ====================

  /// Verificar si hay datos de usuario cargados
  bool get hasUserData =>
      _estudiante != null || _docente != null || _administrador != null;

  /// Limpiar todos los datos al cerrar sesión
  void clear() {
    _estudiante = null;
    _docente = null;
    _administrador = null;
    _notificacionesActivas = true;
    notifyListeners();
  }
}
