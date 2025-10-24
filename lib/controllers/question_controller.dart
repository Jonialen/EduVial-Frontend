import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:eduvial/models/pregunta.dart';
import 'package:eduvial/controllers/auth_controller.dart' as auth;
import 'package:eduvial/config/constants.dart';
import 'package:eduvial/services/guest_helper.dart';

class QuestionController extends ChangeNotifier {
  QuestionController({
    required this.category,
    required this.level,
    this.maxQuestions = 215,
  });

  final String category;
  final String level;
  final int maxQuestions;

  bool loading = true;
  String error = '';

  List<Pregunta> _questions = [];
  Pregunta? _current;
  List<OpcionRespuesta> _options = [];
  int? _selectedIndex;
  bool _answerShown = false;

  int _index = 0;
  int _scoreLesson = 0;
  int _answeredCount = 0; // 👈 preguntas respondidas (sin importar si son correctas)
  int _wrongCount = 0; // 👈 cantidad de fallos
  int? _userPoints;
  bool _busy = false;

  bool get busy => _busy;
  List<Pregunta> get questions => _questions;
  Pregunta? get current => _current;
  List<OpcionRespuesta> get options => _options;
  int? get selectedIndex => _selectedIndex;
  bool get answerShown => _answerShown;
  int get index => _index;
  int get scoreLesson => _scoreLesson;
  int get scoreLessonPoints => _scoreLesson * 5;
  int? get userPoints => _userPoints;
  int get total => _questions.length;
  int get answered => _answeredCount;
  int get wrongs => _wrongCount;

  /// ✅ La lección termina cuando se han respondido todas las preguntas
  bool get isFinished => _answeredCount >= total;

  /// 🔵 Progreso visual (basado en respondidas, no correctas)
  double get progress => (total == 0) ? 0 : (_answeredCount / total);

  /// 🔵 Color dinámico según los errores
  Color get progressColor {
    if (_wrongCount == 0) return Colors.greenAccent;
    if (_wrongCount == 1) return Colors.yellow.shade600;
    if (_wrongCount == 2) return Colors.orange.shade700;
    return Colors.redAccent;
  }

  Future<void> init() async {
    loading = true;
    error = '';
    notifyListeners();

    try {
      await _loadUserPoints();
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

  Future<void> _loadUserPoints() async {
    final s = await auth.auth_controller.getUserPoints();
    _userPoints = s ?? 0;
  }

  Future<void> _loadQuestions() async {
    debugPrint('🌐 Descargando preguntas desde ${ApiConstants.questEndpoint}...');
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

    // 📊 --- Log de conteos por categoría y nivel ---
    final Map<String, Map<String, int>> conteos = {};
    for (final p in todas) {
      conteos.putIfAbsent(p.cat, () => {});
      conteos[p.cat]!.update(p.lvl, (v) => v + 1, ifAbsent: () => 1);
    }

    debugPrint('📘 Resumen de preguntas cargadas:');
    conteos.forEach((cat, niveles) {
      debugPrint('  📂 Categoría "$cat":');
      niveles.forEach((lvl, count) {
        debugPrint('     - Nivel "$lvl": $count preguntas');
      });
    });

    // 🔍 Filtro actual
    final filtradas = todas
        .where((p) => p.lvl == level && p.cat == category)
        .toList();

    debugPrint(
        '🔎 Coincidencias actuales → cat="$category", lvl="$level": ${filtradas.length} preguntas');

    if (filtradas.isEmpty) {
      throw Exception('No hay preguntas para el nivel $level en $category');
    }

    filtradas.shuffle();
    _questions = filtradas.take(maxQuestions).toList();

    _index = 0;
    _scoreLesson = 0;
    _answeredCount = 0;
    _wrongCount = 0;
    _current = _questions.first;
    _answerShown = false;
    _selectedIndex = null;

    debugPrint(
        '✅ Seleccionadas para la lección: ${_questions.length} (máx. $maxQuestions)\n'
            '🟢 Módulo listo → cat="$category", lvl="$level"');
  }


  Future<void> _loadOptions(int questionId) async {
    _busy = true;
    notifyListeners();
    try {
      final resp = await http
          .get(Uri.parse('${ApiConstants.questEndpoint}/$questionId/options'))
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw Exception('No se pudieron cargar opciones');
      }

      final List<dynamic> data = json.decode(resp.body);
      _options = data.map((j) => OpcionRespuesta.fromJson(j)).toList();

      if (_options.length > 1) {
        _options.shuffle();
      }

      _selectedIndex = null;
      _answerShown = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void selectOption(int i) {
    if (!_answerShown && !_busy) {
      _selectedIndex = i;
      notifyListeners();
    }
  }

  /// Retorna true/false si había selección; null si no había.
  bool? verifySelected() {
    if (_selectedIndex == null || _busy) return null;
    _answerShown = true;
    final correct = _options[_selectedIndex!].correct ?? false;

    _answeredCount++; // 🔵 aumenta aunque falle
    if (correct) {
      _scoreLesson++;
    } else {
      _wrongCount++;
    }

    notifyListeners();
    return correct;
  }

  Future<void> next() async {
    if (isFinished || _busy) return;

    _busy = true;
    notifyListeners();
    try {
      _index++;
      if (_index < _questions.length) {
        _current = _questions[_index];
        await _loadOptions(_current!.id);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<int?> finishAndSync() async {
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

  Future<int?> finishAndSyncGuarded(BuildContext context,
      {VoidCallback? onGoLogin}) async {
    final res = await requireAuthOrAlert(
      context,
      featureName: 'Sumar puntos por lección',
      onGoLogin: onGoLogin,
    );

    if (res != AuthPromptResult.proceed) return null;
    return await finishAndSync();
  }

  Future<void> restart() async {
    await init();
  }
}