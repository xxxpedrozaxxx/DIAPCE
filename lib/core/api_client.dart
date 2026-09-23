import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Error devuelto por la API (o por la red). `message` ya viene listo para
/// mostrarse en un SnackBar.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  /// Cuerpo JSON de la respuesta de error (p. ej. la lista de líneas con
  /// errores de una importación CSV). Null si no hubo respuesta.
  final dynamic body;
  const ApiException(this.statusCode, this.message, [this.body]);

  @override
  String toString() => message;
}

/// Cliente HTTP único hacia el backend Flask.
///
/// - Base URL configurable con `--dart-define=API_URL=http://host:5000`.
///   Por defecto `localhost` (o `10.0.2.2` en el emulador Android, que es
///   como el emulador ve al host).
/// - Guarda el JWT en `shared_preferences` y lo adjunta en cada petición.
///   (flutter_secure_storage necesita ATL de Visual Studio para compilar en
///   Windows; shared_preferences compila en todas las plataformas.)
/// - Convierte respuestas de error en [ApiException] con el `message` de la API.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const _tokenKey = 'diapce_access_token';
  static const _envUrl = String.fromEnvironment('API_URL');

  final _http = http.Client();
  String? _token;

  String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000';
    // 127.0.0.1 y no localhost: en Windows localhost intenta primero IPv6
    // (::1), donde Flask no escucha, y cada petición espera ese intento.
    return 'http://127.0.0.1:5000';
  }

  bool get hasToken => _token != null;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse('$baseUrl$path').replace(queryParameters: q);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  /// Descarga binaria (p. ej. el reporte PDF de un proyecto).
  Future<List<int>> getBytes(String path) async {
    http.Response response;
    try {
      response = await _http.get(_uri(path), headers: _headers).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException(0, 'No se pudo conectar con el servidor ($baseUrl).');
    }
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, 'Error ${response.statusCode} al descargar');
    }
    return response.bodyBytes;
  }

  Future<dynamic> post(String path, {Object? body}) => _send(
        () => _http.post(_uri(path), headers: _headers, body: jsonEncode(body)),
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
        () => _http.put(_uri(path), headers: _headers, body: jsonEncode(body)),
      );

  Future<dynamic> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException(0, 'No se pudo conectar con el servidor ($baseUrl).');
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, 'Error ${response.statusCode}');
      }
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _errorMessage(decoded, response.statusCode), decoded);
    }
    return decoded;
  }

  /// flask-smorest devuelve `{message}` o `{errors: {json: {campo: [msg]}}}`.
  static String _errorMessage(dynamic body, int status) {
    if (body is Map) {
      if (body['message'] is String) return body['message'];
      final errors = body['errors'];
      if (errors is Map) {
        final loc = errors.values.first;
        if (loc is Map && loc.isNotEmpty) {
          final field = loc.keys.first;
          final msgs = loc.values.first;
          return '$field: ${msgs is List ? msgs.join(', ') : msgs}';
        }
      }
    }
    return 'Error $status';
  }
}
