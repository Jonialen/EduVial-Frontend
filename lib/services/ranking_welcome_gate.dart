// lib/services/ranking_welcome_gate.dart
import 'package:shared_preferences/shared_preferences.dart';

class RankingWelcomeGate {
  static String _key(String userId) => 'ranking_welcome_seen_$userId';

  static Future<bool> shouldShow(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key(userId)) ?? false);
  }

  static Future<void> markSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId), true);
  }

  // opcional (debug)
  static Future<bool?> debugGet(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId));
  }
}
