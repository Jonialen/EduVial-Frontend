// lib/config/constants.dart
class ApiConstants {
  // ===== BASE =====
  static const String apiBaseUrl = 'https://dev.eduvial.space';

  // ===== AUTH =====
  static const String _loginPath     = '/api/auth/login';
  static const String _registerPath  = '/api/auth/register';
  static const String _meBasicPath   = '/api/user/me/basic';

  // ===== PERFIL / PUNTOS =====
  static const String _pointsPath    = '/api/score/me/score';

  // ===== PREGUNTAS =====
  static const String _questPath     = '/api/quest';

  // ===== RANKING GENERAL =====
  static const String _rankingTopPath = '/api/ranking/top';
  static const String _meRankingPath  = '/api/ranking/me/ranking';

  // ===== LEYES =====
  static const String _lawsPath          = '/api/laws';
  static const String _lawsCatsPath      = '/api/laws/categories';
  static const String _lawsByCatPath     = '/api/laws/category';
  static const String _lawsFilterPath    = '/api/laws/filter';
  static const String _lawsFiltersInfo   = '/api/laws/filters/info';

  // ===== AVATAR =====
  static const String _avatarListPath = '/api/avatar';
  static const String _myAvatarPath   = '/api/avatar/me';

  // ===== RACHA (STREAK) =====
  static const String _streakPath       = '/api/streak';
  static const String _streakBumpPath   = '/api/streak/bump';
  static const String _streakRankingPath = '/api/streak/ranking';

  // ===== ENDPOINTS COMPLETOS =====
  static const String loginEndpoint       = '$apiBaseUrl$_loginPath';
  static const String registerEndpoint    = '$apiBaseUrl$_registerPath';
  static const String meBasicEndpoint     = '$apiBaseUrl$_meBasicPath';
  static const String pointsEndpoint      = '$apiBaseUrl$_pointsPath';
  static const String questEndpoint       = '$apiBaseUrl$_questPath';
  static const String rankingTopEndpoint  = '$apiBaseUrl$_rankingTopPath';
  static const String rankingMeEndpoint   = '$apiBaseUrl$_meRankingPath';

  // Avatar
  static const String avatarListEndpoint  = '$apiBaseUrl$_avatarListPath';
  static const String myAvatarEndpoint    = '$apiBaseUrl$_myAvatarPath';

  // Leyes
  static const String lawsEndpoint        = '$apiBaseUrl$_lawsPath';
  static const String lawsCategoriesEndpoint = '$apiBaseUrl$_lawsCatsPath';
  static Uri lawsByCategory(String category) =>
      Uri.parse('$apiBaseUrl$_lawsByCatPath/${Uri.encodeComponent(category)}');
  static Uri lawsFilterByArticle({required String article}) =>
      Uri.parse('$apiBaseUrl$_lawsFilterPath')
          .replace(queryParameters: {'article': article});
  static const String lawsFiltersInfoEndpoint = '$apiBaseUrl$_lawsFiltersInfo';

  // Racha (Streak)
  static const String streakBase      = '$apiBaseUrl$_streakPath';
  static const String streakMe        = '$apiBaseUrl$_streakPath';
  static const String streakBump      = '$apiBaseUrl$_streakBumpPath';
  static const String streakRanking   = '$apiBaseUrl$_streakRankingPath';

  // ===== HELPERS =====
  static Uri rankingTop({int? limit}) {
    final uri = Uri.parse('$apiBaseUrl$_rankingTopPath');
    return uri.replace(queryParameters: {if (limit != null) 'limit': '$limit'});
  }

  static Uri meRanking() => Uri.parse('$apiBaseUrl$_meRankingPath');

  static Map<String, String> authHeader([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
