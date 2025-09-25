// constants.dart
class ApiConstants {
  // Cambia si necesitas prod/test
  static const String apiBaseUrl = 'https://dev.eduvial.space';

  // ===== Paths =====
  // Auth
  static const String _loginPath     = '/api/auth/login';
  static const String _registerPath  = '/api/auth/register';
  static const String _meBasicPath   = '/api/user/me/basic';

  // Puntos / perfil
  static const String _pointsPath    = '/api/user/me/score';

  // Preguntas
  static const String _questPath     = '/api/quest';

  // Ranking
  static const String _rankingTopPath = '/api/ranking/top';
  static const String _meRankingPath  = '/api/ranking/me/ranking';

  // ===== Endpoints directos (si aún quieres strings) =====
  static const String loginEndpoint    = '$apiBaseUrl$_loginPath';
  static const String registerEndpoint = '$apiBaseUrl$_registerPath';
  static const String meBasicEndpoint  = '$apiBaseUrl$_meBasicPath';
  static const String pointsEndpoint   = '$apiBaseUrl$_pointsPath';
  static const String questEndpoint    = '$apiBaseUrl$_questPath';

  // CORREGIDOS:
  // Top ranking (sin/contar params lo maneja el helper)
  static const String rankingTopEndpoint = '$apiBaseUrl$_rankingTopPath';
  // Mi ranking
  static const String rankingMeEndpoint  = '$apiBaseUrl$_meRankingPath';

  // ===== Helpers Uri  =====
  static Uri rankingTop({int? limit}) {
    final uri = Uri.parse('$apiBaseUrl$_rankingTopPath');
    return uri.replace(queryParameters: {
      if (limit != null) 'limit': '$limit',
    });
  }

  static Uri meRanking() => Uri.parse('$apiBaseUrl$_meRankingPath');
}
