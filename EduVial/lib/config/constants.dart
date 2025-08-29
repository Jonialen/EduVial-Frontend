class ApiConstants{

  static const String apiBaseUrl = 'https://dev.eduvial.space';  // Android emulator

  //auth
  static const String loginEndpoint = '$apiBaseUrl/api/auth/login';
  static const String registerEndpoint = '$apiBaseUrl/api/auth/register';
  static const String meBasicEndpoint = '$apiBaseUrl/api/user/me/basic';

  //puntos
  static const String pointsEndpoint = '$apiBaseUrl/api/user/me/score';

}


