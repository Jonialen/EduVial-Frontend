import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../config/constants.dart';

class auth_controller {
  // 1. Función para Login ----------------------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body), // Token o datos del usuario
        };
      } else {
        return {
          'success': false,
          'error': 'Credenciales incorrectas', // Mensaje de error del backend
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // 2. Función para Register -------------------------------
  static Future<Map<String, dynamic>> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        body: jsonEncode(user.toJson()), // Convierte el modelo User a JSON
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body), // Datos del usuario registrado
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Error al registrar',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}