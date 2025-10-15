// lib/services/ranking_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint para logs largos
import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/user.dart';
import '../services/me_ranking.dart'; //
class RankingService {
  final String token;
  RankingService(this.token);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  /// Top N (o todos si [limit] == null). Mapea `total_points` -> User.points.
  Future<List<User>> fetchTop({int? limit}) async {
    final uri = ApiConstants.rankingTop(limit: limit);
    print('➡️ GET $uri');
    final resp = await http.get(uri, headers: _headers);

    print('⬅️ /ranking/top Status: ${resp.statusCode}');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      debugPrint('❌ Body: ${resp.body}', wrapWidth: 1024);
      throw Exception('Ranking error ${resp.statusCode}: ${resp.body}');
    }

    final decoded = json.decode(resp.body);

    // La API puede devolver lista directa o { items: [...] }
    final rawList = (decoded is Map && decoded['items'] is List)
        ? List.from(decoded['items'])
        : List.from(decoded as List);

    if (rawList.isNotEmpty && rawList.first is Map) {
      final m = rawList.first as Map;
      print('🔎 TOP first item keys: ${m.keys.toList()}');
      debugPrint('🔎 TOP first item: $m', wrapWidth: 1024);
    }

    // Mapea soportando { position, name, total_points, ... } o { user:{...}, score/xp }
    final users = rawList
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .map((e) => User.fromRankingItem(e))
        .toList();

    // Orden descendente por puntos (null -> 0)
    users.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
    print('✅ TOP mapped count=${users.length}');
    if (users.isNotEmpty) {
      print('   top[0]: name=${users.first.name}, points=${users.first.points}');
    }

    return users;
  }

  /// Mi posición/puntos reales (aunque no estés en el Top N visible).
  Future<MeRanking?> fetchMyRanking() async {
    final uri = Uri.parse(ApiConstants.rankingMeEndpoint);
    print('➡️ GET $uri');
    final resp = await http.get(uri, headers: _headers);

    print('⬅️ /me/ranking Status: ${resp.statusCode}');
    debugPrint('⬅️ /me/ranking Body:\n${resp.body}', wrapWidth: 1024);

    if (resp.statusCode == 404) return null;
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Me ranking error ${resp.statusCode}: ${resp.body}');
    }

    final decoded = json.decode(resp.body);
    final map = Map<String, dynamic>.from(decoded as Map);
    final me = MeRanking.fromJson(map);
    print('✅ MeRanking mapeado → $me');
    return me;
  }
}
