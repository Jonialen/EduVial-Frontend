import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:eduvial/models/pregunta.dart';
import 'package:eduvial/controllers/auth_controller.dart' as auth;
import 'package:eduvial/config/constants.dart';
import 'package:eduvial/services/guest_helper.dart'; //

/// Controlador genérico de cuestionarios.
/// - Carga preguntas filtradas por nivel + categoría (cat)
/// - Carga opciones de la pregunta actual
/// - Maneja selección, verificación y avance
/// - Lleva puntaje de la lección y (si hay JWT) sincroniza puntos del usuario al final
class QuestionController extends ChangeNotifier {
  QuestionController({
    required this.category,     // p.ej. 'Señales', 'Simulaciones', 'Escenarios'
    required this.level,        // p.ej. 'Básico' | 'Avanzado'
    this.maxQuestions = 5,
  });

  final String category;
  final String level;
  final int maxQuestions;

  // Estado
  bool loading = true;
  String error = '';

  List<Pregunta> _questions = [];
  Pregunta? _current;
  List<OpcionRespuesta> _options = [];
  int? _selectedIndex;
  bool _answerShown = false;

  int _index = 0;
  int _scoreLesson = 0;     // correctas * 1 (tu UI lo multiplica x5)
  int? _userPoints;         // puntos del backend (total acumulado)
  bool _guest = true;       // cachea si no hay JWT

  // Getters expuestos a la UI
  List<Pregunta> get questions => _questions;
  Pregunta? get current => _current;
  List<OpcionRespuesta> get options => _options;
  int? get selectedIndex => _selectedIndex;
  bool get answerShown => _answerShown;

  int get index => _index;
  int get scoreLesson => _scoreLesson;
  int get scoreLessonPoints => _scoreLesson * 5;
  int? get userPoints => _userPoints;
  bool get isLast => _index + 1 >= _questions.length;
  bool get isGuestMode => _guest;

  // --------- Carga inicial ---------

  Future<void> init() async {
    loading = true;
    error = '';
    notifyListeners();

    try {
      await _resolveGuestAndPoints();
      await _loadQuestions();
      if (_current != null) {
        await _loadOptions(_current!.id);
      }
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = 'Error: $e';
      notifyListeners();
    }
  }

  /// Resuelve si es invitado (no hay JWT) y trata de leer puntos si aplica.
  Future<void> _resolveGuestAndPoints() async {
    final token = await auth.auth_controller.loadToken();
    _guest = (token == null || token.isEmpty);

    if (_guest) {
      _userPoints = 0;
      return;
    }

    // Si hay token, intentamos leer puntos; si falla por 401 => treat as guest
    final s = await auth.auth_controller.getUserPoints();
    if (s == null) {
      _guest = true;
      _userPoints = 0;
    } else {
      _userPoints = s;
    }
  }

  Future<void> _loadQuestions() async {
    final resp = await http
        .get(Uri.parse(ApiConstants.questEndpoint))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('No se pudieron cargar preguntas');
    }

    final List data = json.decode(resp.body);
    final todas = data
        .where((j) => j != null)
        .map((j) => Pregunta.fromJson(j))
        .toList();

    // Filtrar por nivel + categoría
    final filtradas = todas.where((p) => p.lvl == level && p.cat == category).toList();

    if (filtradas.isEmpty) {
      throw Exception('No hay preguntas para el nivel $level en $category');
    }

    filtradas.shuffle();
    _questions = filtradas.take(maxQuestions).toList();
    _index = 0;
    _scoreLesson = 0;
    _current = _questions.first;
    _answerShown = false;
    _selectedIndex = null;
  }

  Future<void> _loadOptions(int questionId) async {
    final resp = await http
        .get(Uri.parse('${ApiConstants.questEndpoint}/$questionId/options'))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('No se pudieron cargar opciones');
    }

    final List<dynamic> data = json.decode(resp.body);
    _options = data.map((j) => OpcionRespuesta.fromJson(j)).toList();
    _selectedIndex = null;
    _answerShown = false;
  }

  // --------- Interacción ---------

  void selectOption(int i) {
    if (!_answerShown) {
      _selectedIndex = i;
      notifyListeners();
    }
  }

  /// Retorna si fue correcta (true/false) o null si no había selección.
  bool? verifySelected() {
    if (_selectedIndex == null) return null;

    _answerShown = true;
    final correct = _options[_selectedIndex!].correct ?? false;
    if (correct) _scoreLesson++;
    notifyListeners();
    return correct;
  }

  Future<void> next() async {
    if (isLast) return;
    _index++;
    _current = _questions[_index];
    await _loadOptions(_current!.id);
    notifyListeners();
  }

  // --------- Finalizar / sincronizar puntos ---------

  /// Versión "guardada": muestra alerta si es invitado y solo sincroniza si hay JWT.
  /// Devuelve el nuevo total o null si se bloqueó o falló.
  Future<int?> finishAndSyncGuarded(
      BuildContext context, {
        VoidCallback? onGoLogin,
      }) async {
    final ok = await requireAuthOrAlert(
      context,
      featureName: 'Sumar puntos por lección',
      onGoLogin: onGoLogin,
    );
    if (!ok) return null; // Invitado: ya se mostró alerta

    final result = await finishAndSync(); // procede normal
    if (result == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron sincronizar los puntos')),
      );
    }
    return result;
  }

  /// Sincroniza los puntos con el backend sumando (scoreLesson * 5) a los actuales.
  /// Devuelve el nuevo total o null si falló.
  /// Asume que HAY JWT (usa la versión Guarded para flujo de UI).
  Future<int?> finishAndSync() async {
    // Refresca estado de invitado por si cambió durante la lección
    await _resolveGuestAndPoints();
    if (_guest) return null;

    final base = _userPoints ?? 0;
    final total = base + scoreLessonPoints;

    final ok = await auth.auth_controller.setUserPoints(total);
    if (ok) {
      _userPoints = total;
      notifyListeners();
      return total;
    }
    return null;
  }

  /// Reinicia el cuestionario (vuelve a cargar aleatoriamente)
  Future<void> restart() async {
    await init();
  }
}
