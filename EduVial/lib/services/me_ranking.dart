// lib/models/me_ranking.dart
class MeRanking {
  final int position;   // 1-based
  final int points;     // viene como total_points
  final String? name;
  final bool? isExpert;

  MeRanking({
    required this.position,
    required this.points,
    this.name,
    this.isExpert,
  });

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory MeRanking.fromJson(Map<String, dynamic> j) => MeRanking(
    position: _toInt(j['position']),
    points: _toInt(j['total_points']),  // ← clave exacta de tu API
    name: j['name'] as String?,
    isExpert: j['isExpert'] as bool?,
  );

  @override
  String toString() =>
      'MeRanking(position: $position, points: $points, name: $name, isExpert: $isExpert)';
}
