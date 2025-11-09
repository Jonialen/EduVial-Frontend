// lib/views/Menu.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:eduvial/views/SignalModule.dart';
import 'package:eduvial/views/simulation_screen.dart';
import 'package:eduvial/views/UserProfile.dart';
import 'package:eduvial/controllers/global_identifier.dart';
import 'package:eduvial/views/scenario_module.dart';
import 'package:eduvial/controllers/auth_controller.dart'; // puntos + token
import 'package:eduvial/config/constants.dart';           // endpoints avatar

import 'package:eduvial/utils/page_transitions.dart';
import 'package:eduvial/services/guest_helper.dart'; // requireAuthOrAlert
import 'package:eduvial/widgets/mascot/traffic_cone_mascot.dart' hide MascotState;
import 'package:eduvial/widgets/mascot/traffic_mascot.dart';
import 'package:eduvial/widgets/road_module_path_view.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});
  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  MascotState _mascotState = MascotState.idle;
  late Timer _mascotTimer;

  int? _points;
  bool _loadingPoints = false;

  String? _avatarUrl;
  bool _loadingAvatar = false;

  @override
  void initState() {
    super.initState();

    _mascotTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _mascotState = MascotState.values[
        (MascotState.values.indexOf(_mascotState) + 1) % MascotState.values.length
        ];
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _mascotState = MascotState.idle);
      });
    });

    _loadPoints();
    _loadAvatar();
  }

  @override
  void dispose() {
    _mascotTimer.cancel();
    super.dispose();
  }

  // ---------- Helpers ----------
  String _proxify(String url) {
    final withoutScheme = url.replaceFirst(RegExp(r'^https?://'), '');
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(withoutScheme)}';
  }

  Future<Map<String, String>> _hdr({bool json = false}) async {
    final token = await auth_controller.loadToken();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ---------- Avatar ----------
  Future<void> _loadAvatar() async {
    setState(() => _loadingAvatar = true);
    try {
      final r = await http.get(
        Uri.parse(ApiConstants.myAvatarEndpoint),
        headers: await _hdr(),
      );

      if (r.statusCode == 404) {
        if (mounted) setState(() => _avatarUrl = null);
      } else if (r.statusCode >= 200 && r.statusCode < 300) {
        final body = jsonDecode(r.body);
        String? raw;
        if (body is Map && body['avatarUrl'] is String) raw = body['avatarUrl'];
        if (raw == null && body is Map && body['url'] is String) raw = body['url'];
        if (raw == null &&
            body is Map &&
            body['data'] is Map &&
            body['data']['url'] is String) {
          raw = body['data']['url'];
        }

        if (mounted) {
          setState(() {
            _avatarUrl = (raw == null)
                ? null
                : (raw.startsWith('http') ? raw : '${ApiConstants.apiBaseUrl}$raw');
          });
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingAvatar = false);
    }
  }

  // ---------- Puntos ----------
  Future<void> _loadPoints() async {
    setState(() => _loadingPoints = true);

    try {
      // cache rápida
      final raw = await auth_controller.loadCachedUserJson();
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['points'] is int && mounted) {
            setState(() => _points = map['points'] as int);
          }
        } catch (_) {}
      }

      // refresh backend
      final me = await auth_controller.getMeBasic();
      if (me['success'] == true && me['user'] != null) {
        final u = me['user'] as Map<String, dynamic>;
        await auth_controller.saveCachedUserJson(jsonEncode(u));
        if (mounted && u['points'] is int) {
          setState(() => _points = u['points'] as int);
        }
      } else {
        final p = await auth_controller.getUserPoints();
        if (mounted && p != null) setState(() => _points = p);
      }
    } finally {
      if (mounted) setState(() => _loadingPoints = false);
    }
  }

  // ---------- Alerta para avanzados bloqueados ----------
  Future<void> _denyAdvanced() async {
    final pts = _points ?? 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.lock_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Módulo avanzado bloqueado'),
          ],
        ),
        content: Text(
          'Necesitas al menos 75 puntos para acceder a los módulos avanzados.\n'
              'Puntos actuales: $pts',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ---------- Navegación por módulo ----------
  void _startModulo({
    required String nombre,
    required String nivelUI, // 'Principiante' | 'Avanzado'
    required int preguntas,  // 5 | 10 | 15
  }) {
    global_identifier.counter = (nivelUI == 'Principiante') ? 0 : 1;

    switch (nombre) {
      case 'Simulaciones':
        Navigator.of(context).push(
          slideUpRoute(SimulationScreen(rol: nivelUI, totalPreguntas: preguntas)),
        );
        break;
      case 'Señales':
        Navigator.of(context).push(
          slideUpRoute(SignalModule(nivel: nivelUI, totalPreguntas: preguntas)),
        );
        break;
      case 'Escenarios':
        Navigator.of(context).push(
          slideUpRoute(ScenarioModule(rol: nivelUI, totalPreguntas: preguntas)),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abrir $nombre ($preguntas preguntas) — ${nivelUI.toLowerCase()}')),
        );
    }
  }

  Future<void> _pickQuestionsAndStart({
    required String nombre,
    required String nivelUI,
    required RoadModuleStyle style, // para colorear 5/10/15 según módulo
  }) async {
    final preguntas = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Elige cuántas preguntas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1976D2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [5, 10, 15].map((q) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _TrafficCircleSign(
                      text: '$q',
                      borderColor: style.ring,
                      onTap: () => Navigator.pop(context, q),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                )
              ],
            ),
          ),
        );
      },
    );

    if (preguntas != null) {
      _startModulo(nombre: nombre, nivelUI: nivelUI, preguntas: preguntas);
    }
  }

  // ---------- Estilos originales de módulos ----------
  static const _simRimDark = Color(0xFFB23A2E);
  static const _simFaceDark = Color(0xFFE53935);
  static const _simFaceLight = Color(0xFFFF8A80);

  static const _senRimDark = Color(0xFFCC7A00);
  static const _senFaceDark = Color(0xFFFF9800);
  static const _senFaceLight = Color(0xFFFFE0B2);

  static const _escRimDark = Color(0xFF2E7D32);
  static const _escFaceDark = Color(0xFF2DBD3A);
  static const _escFaceLight = Color(0xFF6CD93B);

  RoadModuleStyle _styleSim() => const RoadModuleStyle(
    ring: _simRimDark,
    gradient: [_simFaceDark, _simFaceLight],
  );
  RoadModuleStyle _styleSen() => const RoadModuleStyle(
    ring: _senRimDark,
    gradient: [_senFaceDark, _senFaceLight],
  );
  RoadModuleStyle _styleEsc() => const RoadModuleStyle(
    ring: _escRimDark,
    gradient: [_escFaceDark, _escFaceLight],
  );

  // ---------- Nodos del camino ----------
  List<RoadModuleNode> _buildRoadNodes() {
    final canEnterAdvanced = (_points ?? 0) >= 75;

    return [
      const RoadModuleNode(
        id: 'intro',
        title: 'Principiantes',
        icon: Icons.star,
        status: ModuleStatus.completed,
      ),

      // Principiante
      RoadModuleNode(
        id: 'senales_p',
        title: 'Señales',
        icon: Icons.traffic,
        status: ModuleStatus.available,
        style: _styleSen(),
        onTap: () => _pickQuestionsAndStart(
          nombre: 'Señales',
          nivelUI: 'Principiante',
          style: _styleSen(),
        ),
      ),
      RoadModuleNode(
        id: 'sim_p',
        title: 'Simulaciones',
        icon: Icons.videogame_asset,
        status: ModuleStatus.available,
        style: _styleSim(),
        onTap: () => _pickQuestionsAndStart(
          nombre: 'Simulaciones',
          nivelUI: 'Principiante',
          style: _styleSim(),
        ),
      ),
      RoadModuleNode(
        id: 'esc_p',
        title: 'Escenarios',
        icon: Icons.landscape,
        status: ModuleStatus.available,
        style: _styleEsc(),
        onTap: () => _pickQuestionsAndStart(
          nombre: 'Escenarios',
          nivelUI: 'Principiante',
          style: _styleEsc(),
        ),
      ),

      // Gate Avanzados (muestra alerta si no alcanza)
      RoadModuleNode(
        id: 'gate_adv',
        title: canEnterAdvanced ? 'Avanzados' : 'Avanzados (75 pts)',
        icon: Icons.menu_book,
        status: canEnterAdvanced ? ModuleStatus.available : ModuleStatus.locked,
        onTap: canEnterAdvanced ? null : _denyAdvanced,
      ),

      // Avanzado (si no alcanza, también dispara alerta)
      RoadModuleNode(
        id: 'senales_a',
        title: 'Señales',
        icon: Icons.traffic_outlined,
        status: canEnterAdvanced ? ModuleStatus.available : ModuleStatus.locked,
        style: _styleSen(),
        onTap: canEnterAdvanced
            ? () => _pickQuestionsAndStart(
          nombre: 'Señales',
          nivelUI: 'Avanzado',
          style: _styleSen(),
        )
            : _denyAdvanced,
      ),
      RoadModuleNode(
        id: 'sim_a',
        title: 'Simulaciones',
        icon: Icons.videogame_asset_outlined,
        status: canEnterAdvanced ? ModuleStatus.available : ModuleStatus.locked,
        style: _styleSim(),
        onTap: canEnterAdvanced
            ? () => _pickQuestionsAndStart(
          nombre: 'Simulaciones',
          nivelUI: 'Avanzado',
          style: _styleSim(),
        )
            : _denyAdvanced,
      ),
      RoadModuleNode(
        id: 'esc_a',
        title: 'Escenarios',
        icon: Icons.landscape_outlined,
        status: canEnterAdvanced ? ModuleStatus.available : ModuleStatus.locked,
        style: _styleEsc(),
        onTap: canEnterAdvanced
            ? () => _pickQuestionsAndStart(
          nombre: 'Escenarios',
          nivelUI: 'Avanzado',
          style: _styleEsc(),
        )
            : _denyAdvanced,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pointsText = (_points == null) ? '—' : _points.toString();
    final canEnterAdvanced = (_points ?? 0) >= 75;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                color: const Color(0xFF1976D2),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Módulos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: canEnterAdvanced ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.workspace_premium, size: 18, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    pointsText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Refrescar puntos',
                              icon: _loadingPoints
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.refresh, color: Colors.white),
                              onPressed: _loadingPoints ? null : _loadPoints,
                            ),
                            const SizedBox(width: 4),

                            // PERFIL — tap
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () async {
                                  final res = await requireAuthOrAlert(
                                    context,
                                    featureName: 'Perfil',
                                    onGoLogin: () => Navigator.of(context).pushNamed('/login'),
                                  );
                                  if (res != AuthPromptResult.proceed) return;

                                  await Navigator.of(context).push(
                                    fadeRoute(const ProfileScreen()),
                                  );
                                  if (mounted) _loadAvatar();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: _loadingAvatar
                                      ? const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    backgroundImage: (_avatarUrl != null)
                                        ? NetworkImage(_proxify(_avatarUrl!))
                                        : null,
                                    child: (_avatarUrl == null)
                                        ? const Icon(Icons.person, size: 18, color: Color(0xFF1976D2))
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Selecciona un modulo ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Camino
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RoadModulePathView(
                    nodes: _buildRoadNodes(),
                    spacing: 140,
                    nodeSize: 76,
                  ),
                ),
              ),
            ],
          ),

          // Mascota
          Positioned(
            bottom: 20,
            right: 20,
            child: TrafficMascot(
              state: _mascotState,
              size: 200,
              onTap: () {
                setState(() => _mascotState = MascotState.celebrating);
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _mascotState = MascotState.idle);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Señal circular para 5/10/15 — usa color del módulo
class _TrafficCircleSign extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color borderColor;
  const _TrafficCircleSign({
    required this.text,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: borderColor, width: 5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
