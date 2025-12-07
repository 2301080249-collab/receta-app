import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/usuario.dart';
import '../data/models/docente.dart';
import '../data/models/estudiante.dart';
import '../data/models/administrador.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/token_service.dart';
import '../data/services/fcm_service.dart';
import 'user_provider.dart';

/// Provider para manejo de autenticación global
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Estado
  Usuario? _currentUser;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Usuario? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(email, password);

      // ✅ Parsear el Map a objeto Usuario
      _currentUser = Usuario.fromJson(result['user']);
      _token = result['token'];
      _isAuthenticated = true;

      // ✅ GUARDAR TOKEN Y DATOS EN SHARED PREFERENCES
      await TokenService.saveToken(_token!);
      await TokenService.saveUserData(result['user']);

      // ✅ NUEVO: Registrar token FCM después del login (solo móvil)
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          await FCMService().registrarTokenDespuesDeLogin();
          if (kDebugMode) {
            debugPrint('✅ Token FCM registrado después del login');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error registrando token FCM: $e');
          }
        }
      }

      _isLoading = false;
      notifyListeners();

      // Retornar el resultado completo incluyendo primera_vez
      return {
        'user': _currentUser,
        'token': _token,
        'primera_vez': result['primera_vez'],
      };
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ==================== ✅ CARGAR DATOS EXTENDIDOS POR ROL ====================

  /// Cargar datos extendidos del usuario según su rol (requiere BuildContext)
  Future<void> cargarDatosUsuarioConContext(BuildContext context) async {
    if (_currentUser == null || _token == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No se puede cargar datos: usuario o token nulo');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔵 Cargando datos para rol: ${_currentUser!.rol}');
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      switch (_currentUser!.rol) {
        case 'docente':
          if (kDebugMode) {
            debugPrint('📘 Obteniendo datos de docente...');
          }
          final docenteData = await _authRepository.getDocenteData(_token!);
          final docente = Docente.fromJson(docenteData);
          userProvider.setDocente(docente);
          if (kDebugMode) {
            debugPrint('✅ Docente cargado: ${docente.codigoDocente}');
          }
          break;

        case 'estudiante':
          if (kDebugMode) {
            debugPrint('📗 Obteniendo datos de estudiante...');
          }
          final estudianteData = await _authRepository.getEstudianteData(_token!);
          final estudiante = Estudiante.fromJson(estudianteData);
          userProvider.setEstudiante(estudiante);
          if (kDebugMode) {
            debugPrint('✅ Estudiante cargado: ${estudiante.codigoEstudiante}');
          }
          break;

        case 'administrador':
          if (kDebugMode) {
            debugPrint('📕 Obteniendo datos de administrador...');
          }
          final adminData = await _authRepository.getAdministradorData(_token!);
          final admin = Administrador.fromJson(adminData);
          userProvider.setAdministrador(admin);
          if (kDebugMode) {
            debugPrint('✅ Administrador cargado: ${admin.codigoAdmin}');
          }
          break;

        default:
          if (kDebugMode) {
            debugPrint('⚠️ Rol desconocido: ${_currentUser!.rol}');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando datos de usuario: $e');
      }
    }
  }

  // CAMBIAR CONTRASEÑA
  Future<void> changePassword(String userId, String newPassword) async {
    if (_token == null) {
      throw Exception('No hay token de autenticación');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.changePassword(
        userId: userId,
        token: _token!,
        newPassword: newPassword,
      );

      // ✅ Actualizar el estado de primera_vez del usuario
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(primeraVez: false);
        
        // ✅ ACTUALIZAR EN SHARED PREFERENCES
        await TokenService.saveUserData(_currentUser!.toJson());
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ✅ NUEVO: Omitir cambio de contraseña (actualizar primera_vez = false)
  Future<void> skipPasswordChange() async {
    if (_currentUser == null || _token == null) {
      throw Exception('Usuario o token no disponible');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.skipPasswordChange(
        userId: _currentUser!.id,
        token: _token!,
      );

      // ✅ Actualizar el estado local
      _currentUser = _currentUser!.copyWith(primeraVez: false);
      
      // ✅ ACTUALIZAR EN SHARED PREFERENCES
      await TokenService.saveUserData(_currentUser!.toJson());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    if (_token != null) {
      await _authRepository.logout(_token!);
    }

    _currentUser = null;
    _token = null;
    _isAuthenticated = false;
    _errorMessage = null;

    // ✅ LIMPIAR TOKEN Y DATOS DE SHARED PREFERENCES
    await TokenService.clearAll();

    notifyListeners();
  }

  // ✅ RESTAURAR SESIÓN AL INICIAR LA APP (SIN DEPENDENCIA DE CONTEXT)
  Future<void> restoreSession() async {
    _isLoading = true;
    
    try {
      final token = await TokenService.getToken();
      final userData = await TokenService.getUserData();

      if (token != null && userData != null) {
        _token = token;
        _currentUser = Usuario.fromJson(userData);
        _isAuthenticated = true;

        // ✅ Registrar token FCM al restaurar sesión (solo móvil)
        if (!kIsWeb) {
          try {
            await FCMService().registrarTokenDespuesDeLogin();
            if (kDebugMode) {
              debugPrint('✅ Token FCM registrado después de restaurar sesión');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error registrando token FCM: $e');
            }
          }
        }

        if (kDebugMode) {
          debugPrint('✅ Sesión restaurada correctamente para: ${_currentUser!.nombreCompleto}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('ℹ️ No hay sesión guardada');
        }
      }

      _isLoading = false;
      Future.microtask(() => notifyListeners());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error restaurando sesión: $e');
      }
      _isLoading = false;
      await TokenService.clearAll();
      Future.microtask(() => notifyListeners());
    }
  }

  // VERIFICAR SESIÓN
  Future<bool> checkSession() async {
    if (_token == null) return false;

    try {
      final isValid = await _authRepository.verifyToken(_token!);

      if (!isValid) {
        await logout();
        return false;
      }

      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  // LIMPIAR ERROR
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ACTUALIZAR USUARIO (después de editar perfil)
  void updateUser(Usuario user) {
    _currentUser = user;
    notifyListeners();
  }

  // ✅ Método útil para obtener el rol del usuario actual
  String? get userRole => _currentUser?.rol;

  // ✅ Verificar si necesita cambiar contraseña
  bool get needsPasswordChange => _currentUser?.primeraVez ?? false;
}