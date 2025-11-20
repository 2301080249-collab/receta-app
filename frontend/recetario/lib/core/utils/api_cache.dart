import 'dart:async';

/// Cache simple para evitar llamadas API duplicadas
class ApiCache {
  static final ApiCache _instance = ApiCache._internal();
  factory ApiCache() => _instance;
  ApiCache._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  /// Obtener datos con cache y deduplicación
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    // Si hay una petición pendiente para esta key, esperar a que termine
    if (_pendingRequests.containsKey(key)) {
      print('⏳ ApiCache: Esperando petición pendiente para $key');
      return await _pendingRequests[key]!.future as T;
    }

    // Si está en cache y no expiró, devolver cache
    if (_cache.containsKey(key)) {
      final cached = _cache[key];
      if (cached['expiry'].isAfter(DateTime.now())) {
        print('✅ ApiCache: Devolviendo desde cache para $key');
        return cached['data'] as T;
      } else {
        print('🗑️ ApiCache: Cache expirado para $key');
        _cache.remove(key);
      }
    }

    // Crear completer para esta petición
    final completer = Completer<T>();
    _pendingRequests[key] = completer as Completer;

    print('🌐 ApiCache: Haciendo petición real para $key');

    try {
      final data = await fetcher();
      
      // Guardar en cache
      _cache[key] = {
        'data': data,
        'expiry': DateTime.now().add(cacheDuration),
      };

      // Resolver completer
      completer.complete(data);
      _pendingRequests.remove(key);

      return data;
    } catch (e) {
      completer.completeError(e);
      _pendingRequests.remove(key);
      rethrow;
    }
  }

  /// Invalidar cache de una key específica
  void invalidate(String key) {
    print('🗑️ ApiCache: Invalidando cache para $key');
    _cache.remove(key);
  }

  /// Limpiar todo el cache
  void clear() {
    print('🗑️ ApiCache: Limpiando todo el cache');
    _cache.clear();
  }
}