class StreakMe {
  final int currentStreak;
  final int maxStreak;
  final DateTime? lastBump;

  StreakMe({
    required this.currentStreak,
    required this.maxStreak,
    required this.lastBump,
  });

  factory StreakMe.fromJson(Map<String, dynamic> j) {
    int c = (j['current_streak'] ?? 0) as int;
    int m = (j['max_streak'] ?? 0) as int;

    // 🔧 Normaliza: nunca negativos y nunca current > max
    if (c < 0) c = 0;
    if (m < 0) m = 0;
    if (c > m) m = c;

    return StreakMe(
      currentStreak: c,
      maxStreak: m,
      lastBump: j['last_bump'] != null ? DateTime.tryParse(j['last_bump']) : null,
    );
  }
}

class StreakRankItem {
  final int position;
  final String name;
  final int currentStreak;
  final bool isExpert;

  // 👇 Por si tu backend en el futuro devuelve también el máximo por usuario en ranking
  final int? maxStreak;

  StreakRankItem({
    required this.position,
    required this.name,
    required this.currentStreak,
    required this.isExpert,
    this.maxStreak,
  });

  factory StreakRankItem.fromJson(Map<String, dynamic> j) {
    int c = (j['current_streak'] ?? 0) as int;
    int? m = j['max_streak'] is int ? j['max_streak'] as int : null;

    // 🔧 Normaliza
    if (c < 0) c = 0;
    if (m != null && m < 0) m = 0;
    if (m != null && c > m) c = m;

    return StreakRankItem(
      position: (j['position'] ?? 0) as int,
      name: (j['name'] ?? '') as String,
      currentStreak: c,
      isExpert: (j['isExpert'] ?? false) as bool,
      maxStreak: m,
    );
  }
}
