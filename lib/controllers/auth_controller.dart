import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../config/constants.dart';
import 'package:flutter/foundation.dart';

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// =====================
/// Storage
/// =====================
abstract class _AuthStore {
  Future<void> saveToken(String token);
  Future<String?> loadToken();
  Future<void> clearToken();

  Future<void> saveUserJson(String userJson);
  Future<String?> loadUserJson();
  Future<void> clearUserJson();
}

class _MemoryAuthStore implements _AuthStore {
  String? _token;
  String? _userJson;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> loadToken() async => _token;

  @override
  Future<void> clearToken() async => _token = null;

  @override
  Future<void> saveUserJson(String userJson) async => _userJson = userJson;

  @override
  Future<String?> loadUserJson() async => _userJson;

  @override
  Future<void> clearUserJson() async => _userJson = null;
}

/// Producción con flutter_secure_storage
// class _SecureAuthStore implements _AuthStore {
//   static const _kTokenKey = 'auth_token';
//   static const _kUserKey  = 'user_json';
//   final FlutterSecureStorage _secure = const FlutterSecureStorage();
//
//   @override
//   Future<void> saveToken(String token) => _secure.write(key: _kTokenKey, value: token);
//   @override
//   Future<String?> loadToken() => _secure.read(key: _kTokenKey);
//   @override
//   Future<void> clearToken() => _secure.delete(key: _kTokenKey);
//
//   @override
//   Future<void> saveUserJson(String userJson) => _secure.write(key: _kUserKey, value: userJson);
//   @override
//   Future<String?> loadUserJson() => _secure.read(key: _kUserKey);
//   @override
//   Future<void> clearUserJson() => _secure.delete(key: _kUserKey);
// }

class auth_controller {
  // Store por defecto: memoria (ideal para tests)
  static _AuthStore _store = _MemoryAuthStore();

  /// En producción se puede activar secure storage:
  /// AuthController.configureStore(_SecureAuthStore());
  static void configureStore(_AuthStore store) {
    _store = store;
  }

  // ===== Helpers HTTP =====
  static Map<String, String> _jsonHeaders([Map<String, String>? extra]) => {
    'Content-Type': 'application/json',
    if (extra != null) ...extra,
  };

  static String _extractError(String body) {
    try {
      final j = jsonDecode(body);
      return (j['message'] ?? j['error'] ?? 'Error desconocido').toString();
    } catch (_) {
      return body.isEmpty ? 'Error desconocido' : body;
    }
  }

  static Future<http.Response> _authedGet(Uri uri) async {
    final token = await _store.loadToken();
    if (token == null) {
      return http.Response(jsonEncode({'error': 'No hay token'}), 401);
    }
    return http
        .get(uri, headers: _jsonHeaders({'Authorization': 'Bearer $token'}))
        .timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> _authedPut(Uri uri, Map<String, dynamic> body) async {
    final token = await _store.loadToken();
    if (token == null) {
      return http.Response(jsonEncode({'error': 'No hay token'}), 401);
    }
    return http
        .put(uri,
        headers: _jsonHeaders({'Authorization': 'Bearer $token'}),
        body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
  }

  // ==============================
  // 1) LOGIN
  // ==============================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final body = jsonEncode({'email': email, 'password': password});

      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // 1) Guardar token
        final token = (data['token'] ?? data['accessToken'])?.toString();
        if (token == null || token.isEmpty) {
          return {'success': false, 'error': 'No vino token en la respuesta'};
        }
        await _store.saveToken(token);
        debugPrint('JWT: $token', wrapWidth: 1024);

        // 2) Cachear perfil
        final me = await getMeBasic();
        if (me['success'] == true && me['user'] != null) {
          await _store.saveUserJson(jsonEncode(me['user']));
        }

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Credenciales incorrectas'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==============================
  // 2) REGISTER
  // ==============================
  static Future<Map<String, dynamic>> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: _jsonHeaders(),
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;

        // Si devuelven token al registrar
        final token = (jsonResp['token'] ?? jsonResp['accessToken']) as String?;
        if (token != null && token.isNotEmpty) {
          await _store.saveToken(token);

          final me = await getMeBasic();
          if (me['success'] == true && me['user'] != null) {
            await _store.saveUserJson(jsonEncode(me['user']));
          }
        }

        // Regla de puntos por rol (ajusta si no aplica)
        final roleLower = user.role.toLowerCase().trim();
        if (roleLower == 'avanzado') {
          await setUserPoints(75);
        } else if (roleLower == 'principiante') {
          await setUserPoints(0);
        }

        return {'success': true, 'data': jsonResp};
      } else {
        return {'success': false, 'error': _extractError(response.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==============================
  // 3) GET /user/me/basic
  // ==============================
  static Future<Map<String, dynamic>> getMeBasic() async {
    try {
      final resp = await _authedGet(Uri.parse(ApiConstants.meBasicEndpoint));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {'success': true, 'user': data};
      } else if (resp.statusCode == 401) {
        await logout();
        return {'success': false, 'error': 'Sesión expirada'};
      } else {
        return {'success': false, 'error': _extractError(resp.body)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==============================
  // 4) PUNTOS (GET/PUT)
  // ==============================
  static Future<int?> getUserPoints() async {
    try {
      final resp = await _authedGet(Uri.parse(ApiConstants.pointsEndpoint));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['points'] is int) return data['points'] as int;
        if (data is Map && data['data'] is Map && data['data']['points'] is int) {
          return data['data']['points'] as int;
        }
        return 0;
      } else if (resp.statusCode == 401) {
        await logout();
        return null;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<bool> setUserPoints(int value) async {
    try {
      final resp = await _authedPut(
        Uri.parse(ApiConstants.pointsEndpoint),
        {'points': value},
      );
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ==============================
  // 5) LOGOUT
  // ==============================
  static Future<void> logout() async {
    await _store.clearToken();
    await _store.clearUserJson();
  }

  // ==============================
  // 6) Helpers públicos para MainShell / UI
  // ==============================
  /// Devuelve el token guardado (o null).
  static Future<String?> loadToken() => _store.loadToken();

  /// Devuelve el User cacheado (o null).
  static Future<User?> loadCachedUser() async {
    final raw = await _store.loadUserJson();
    return User.fromRawJson(raw);
  }

  /// Vuelve a pedir /me al backend, cachea y devuelve el User (o null si falla).
  static Future<User?> refreshMeAndCache() async {
    final res = await getMeBasic();
    if (res['success'] == true && res['user'] != null) {
      await _store.saveUserJson(jsonEncode(res['user']));
      return User.fromJson(Map<String, dynamic>.from(res['user']));
    }
    return null;
  }

  /// (Opcionales) accesos crudos al cache por si los necesitas
  static Future<String?> loadCachedUserJson() => _store.loadUserJson();
  static Future<void> saveCachedUserJson(String raw) => _store.saveUserJson(raw);
}
