// lib/config/constants.dart
class ApiConstants {
  // Base (ajústala si cambias de entorno)
  static const String apiBaseUrl = 'https://dev.eduvial.space';

  // ===== Paths =====
  // Auth
  static const String _loginPath     = '/api/auth/login';
  static const String _registerPath  = '/api/auth/register';
  static const String _meBasicPath   = '/api/user/me/basic';

  // Puntos / perfil
  static const String _pointsPath    = '/api/score/me/score';

  // Preguntas
  static const String _questPath     = '/api/quest';

  // Ranking
  static const String _rankingTopPath = '/api/ranking/top';
  static const String _meRankingPath  = '/api/ranking/me/ranking';

  // ===== LEYES =====
  static const String _lawsPath          = '/api/laws';                 // GET todas
  static const String _lawsCatsPath      = '/api/laws/categories';      // GET categorías
  static const String _lawsByCatPath     = '/api/laws/category';        // + /{name}
  static const String _lawsFilterPath    = '/api/laws/filter';          // ?article=145
  static const String _lawsFiltersInfo   = '/api/laws/filters/info';    // info filtros (opcional)

  // ===== Endpoints directos (string) =====
  static const String loginEndpoint       = '$apiBaseUrl$_loginPath';
  static const String registerEndpoint    = '$apiBaseUrl$_registerPath';
  static const String meBasicEndpoint     = '$apiBaseUrl$_meBasicPath';
  static const String pointsEndpoint      = '$apiBaseUrl$_pointsPath';
  static const String questEndpoint       = '$apiBaseUrl$_questPath';
  static const String rankingTopEndpoint  = '$apiBaseUrl$_rankingTopPath';
  static const String rankingMeEndpoint   = '$apiBaseUrl$_meRankingPath';

  // Leyes
  static const String lawsEndpoint        = '$apiBaseUrl$_lawsPath';
  static const String lawsCategoriesEndpoint = '$apiBaseUrl$_lawsCatsPath';
  static Uri lawsByCategory(String category) =>
      Uri.parse('$apiBaseUrl$_lawsByCatPath/${Uri.encodeComponent(category)}');
  static Uri lawsFilterByArticle({required String article}) =>
      Uri.parse('$apiBaseUrl$_lawsFilterPath').replace(queryParameters: {'article': article});
  static const String lawsFiltersInfoEndpoint = '$apiBaseUrl$_lawsFiltersInfo';

  // ===== Helpers Uri =====
  static Uri rankingTop({int? limit}) {
    final uri = Uri.parse('$apiBaseUrl$_rankingTopPath');
    return uri.replace(queryParameters: { if (limit != null) 'limit': '$limit' });
  }

  static Uri meRanking() => Uri.parse('$apiBaseUrl$_meRankingPath');

  // (Opcional) Header con auth si ya tienes un helper de JWT en tu auth_controller.
  // Deja esto como stub o impleméntalo según tu app.
  static Map<String, String> authHeader([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
