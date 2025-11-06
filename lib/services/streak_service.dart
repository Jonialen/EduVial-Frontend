// lib/services/streak_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/streak.dart';
import '../controllers/auth_controller.dart' as auth;

class StreakService {
  static Map<String, String> _jsonHeaders([Map<String, String>? extra]) => {
    'Content-Type': 'application/json',
    if (extra != null) ...extra,
  };

  static Future<StreakMe> getMyStreak() async {
    final token = await auth.auth_controller.loadToken();
    if (token == null) {
      throw Exception('No hay token');
    }
    final r = await http.get(
      Uri.parse(ApiConstants.streakMe),
      headers: _jsonHeaders({'Authorization': 'Bearer $token'}),
    );
    if (r.statusCode == 200) {
      return StreakMe.fromJson(json.decode(r.body));
    }
    throw Exception('getMyStreak ${r.statusCode}: ${r.body}');
  }

  /// Idempotente por día. Llamar cuando el usuario complete al menos una lección.
  static Future<StreakMe> bump() async {
    final token = await auth.auth_controller.loadToken();
    if (token == null) {
      throw Exception('No hay token');
    }
    final r = await http.post(
      Uri.parse(ApiConstants.streakBump),
      headers: _jsonHeaders({'Authorization': 'Bearer $token'}),
    );
    if (r.statusCode == 200) {
      return StreakMe.fromJson(json.decode(r.body));
    }
    throw Exception('bump ${r.statusCode}: ${r.body}');
  }

  static Future<List<StreakRankItem>> getRanking({int? limit}) async {
    final uri = (limit == null)
        ? Uri.parse(ApiConstants.streakRanking)
        : Uri.parse('${ApiConstants.streakRanking}?limit=$limit');

    final r = await http.get(uri); // público
    if (r.statusCode == 200) {
      final list = (json.decode(r.body) as List)
          .map((e) => StreakRankItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    }
    throw Exception('ranking ${r.statusCode}: ${r.body}');
  }
}
