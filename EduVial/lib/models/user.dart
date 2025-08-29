// lib/models/user.dart
import 'dart:convert';

class User {
  final String name;
  final String email;
  final String password; // ⚠️ usualmente no se devuelve del backend, pero lo dejamos si lo usas en register/login
  final String role;     // Ej: "principiante", "user"
  final int? points;     // Nuevo, puede ser null si no lo manda el backend

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.points,
  });

  // Convierte el objeto a JSON (para enviar al backend)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (points != null) 'points': points, // solo incluir si existe
    };
  }

  // Crea un User desde JSON recibido del backend
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      points: json['points'] != null ? json['points'] as int : null,
    );
  }

  /// Helpers para serializar/deserializar en string
  static User? fromRawJson(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return User.fromJson(map);
    } catch (_) {}
    return null;
  }

  String toRawJson() => jsonEncode(toJson());
}
