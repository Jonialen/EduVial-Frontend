import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String name;
  final String email;
  final String password; // ⚠️ DEV ONLY: se persiste temporalmente
  final String role;     // p.ej. "principiante", "invitado", "user"

  const User({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password, // ❗️Quitar en producción
    'role': role,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    password: json['password'] ?? '',
    role: json['role'] ?? '',
  );
}

// -------- Estado global + persistencia local --------

User? currentUser; // Usuario actual en memoria
const _kUserProfileKey = 'user_profile';

Future<void> saveUserLocal(User user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kUserProfileKey, jsonEncode(user.toJson()));
  currentUser = user;
}

Future<User?> loadUserLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kUserProfileKey);
  if (raw == null) {
    currentUser = null;
    return null;
  }
  try {
    currentUser = User.fromJson(jsonDecode(raw));
  } catch (_) {
    currentUser = null;
  }
  return currentUser;
}

Future<void> clearUserLocal() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kUserProfileKey);
  currentUser = null;
}
