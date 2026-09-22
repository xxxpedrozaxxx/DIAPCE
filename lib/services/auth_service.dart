// lib/services/auth_service.dart

import '../core/api_client.dart';

/// Usuario autenticado tal como lo devuelve la API.
class AuthUser {
  final int id;
  final String email;
  const AuthUser({required this.id, required this.email});

  factory AuthUser.fromMap(Map<String, dynamic> map) =>
      AuthUser(id: map['id'] as int, email: map['email'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'email': email};
}

/// Registro e inicio de sesión contra `/api/auth/*`.
/// Reemplaza `DatabaseHelper.insertUser` / `getUserByEmailAndPassword`.
class AuthService {
  final ApiClient _api = ApiClient();

  Future<AuthUser> login(String email, String password) =>
      _authenticate('/api/auth/login', email, password);

  Future<AuthUser> register(String email, String password) =>
      _authenticate('/api/auth/register', email, password);

  Future<AuthUser> _authenticate(String path, String email, String password) async {
    final data = await _api.post(path, body: {'email': email, 'password': password});
    await _api.setToken(data['access_token'] as String);
    return AuthUser.fromMap(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => _api.setToken(null);
}
