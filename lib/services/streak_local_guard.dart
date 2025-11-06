// lib/services/streak_local_guard.dart
import 'package:shared_preferences/shared_preferences.dart';

class StreakLocalGuard {
  static const _kLastBumpYMD = 'streak_last_bump_yyyyMMdd';

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static Future<bool> canBumpToday() async {
    final sp = await SharedPreferences.getInstance();
    final today = _ymd(DateTime.now());
    return sp.getString(_kLastBumpYMD) != today;
  }

  static Future<void> markBumpedToday() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastBumpYMD, _ymd(DateTime.now()));
  }
}
