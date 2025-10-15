import 'dart:convert';

class User {
  final String name;
  final String email;
  final String password;
  final String role;
  final int? points; // en UI usa (points ?? 0)

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.points,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'role': role,
    if (points != null) 'points': points,
  };

  // helpers para parseo
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final m = RegExp(r'-?\d+').firstMatch(v);
      if (m != null) return int.tryParse(m.group(0)!);
    }
    return null;
  }

  static int? _extractPoints(dynamic j) {
    if (j is Map) {
      // ⬅️ incluye total_points (snake_case)
      for (final k in [
        'points', 'score', 'xp',
        'total_points', // <---
        'totalPoints', 'total_xp', 'totalXP',
      ]) {
        final n = _toInt(j[k]);
        if (n != null) return n;
      }
      for (final v in j.values) {
        final n = _extractPoints(v);
        if (n != null) return n;
      }
    }
    return null;
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] ?? json['username'] ?? '',
    email: json['email'] ?? '',             // el top no trae email → quedará ''
    password: json['password'] ?? '',
    role: json['role'] ?? '',
    points: _extractPoints(json),
  );

  /// Soporta items tipo { user:{...}, score/xp/total_points: 15 }
  factory User.fromRankingItem(Map<String, dynamic> json) {
    if (json['user'] is Map) {
      final u = Map<String, dynamic>.from(json['user']);
      final merged = {
        ...u,
        'points': u['points'] ??
            json['points'] ??
            json['score'] ??
            json['xp'] ??
            json['total_points'], // <---
      };
      return User.fromJson(merged);
    }
    return User.fromJson(json);
  }

  static User? fromRawJson(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return User.fromJson(map);
    } catch (_) {}
    return null;
  }

  String toRawJson() => jsonEncode(toJson());

  User copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
    int? points,
  }) =>
      User(
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        role: role ?? this.role,
        points: points ?? this.points,
      );
}
