import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eduvial/views/SignalModule.dart';
import 'package:eduvial/views/simulation_screen.dart';
import 'package:eduvial/views/UserProfile.dart';
import 'package:eduvial/controllers/global_identifier.dart';
import 'package:eduvial/views/scenario_module.dart';
import 'package:eduvial/controllers/auth_controller.dart'; // <-- puntos

import '../widgets/coin_button.dart'; //  CoinButton
import 'package:eduvial/utils/page_transitions.dart';
import 'package:eduvial/services/guest_helper.dart'; // requireAuthOrAlert
import 'package:eduvial/widgets/mascot/traffic_cone_mascot.dart' hide MascotState;
import 'package:eduvial/widgets/mascot/traffic_mascot.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  bool _showPrincipianteSubmodulos = false;
  bool _showAvanzadoSubmodulos = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Mascota
  MascotState _mascotState = MascotState.idle;
  late Timer _mascotTimer;
  final List<MascotState> _animatedStates = [
    MascotState.waving,
    MascotState.pointing,
    MascotState.celebrating,
    MascotState.alert,
  ];

  // --- Puntos / loading ---
  int? _points;          // null = aún no cargados
  bool _loadingPoints = false;

  // --- NUEVO: índice expandido por grupo para mostrar 5/10/15 ---
  int? _expandedIdxPrincipiante;
  int? _expandedIdxAvanzado;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Animaciones automáticas cada 5 s
    _mascotTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _mascotState = (_animatedStates.toList()..shuffle()).first;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _mascotState = MascotState.idle);
          }
        });
      }
    });

    // cargar puntos
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() => _loadingPoints = true);

    try {
      // 1) Cache rápido
      final raw = await auth_controller.loadCachedUserJson();
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['points'] is int && mounted) {
            _points = map['points'] as int;
            setState(() {}); // pinta provisional
          }
        } catch (_) {}
      }

      // 2) Refrescar desde backend
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

  @override
  void dispose() {
    _animationController.dispose();
    _mascotTimer.cancel();
    super.dispose();
  }

  void _togglePrincipianteSubmodulos() {
    setState(() {
      _showPrincipianteSubmodulos = !_showPrincipianteSubmodulos;
      _showAvanzadoSubmodulos = false;
      _expandedIdxPrincipiante = null; // reset mini-señales
      _mascotState = MascotState.pointing;

      if (_showPrincipianteSubmodulos) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _mascotState = MascotState.idle;
      }
    });
  }

  Future<void> _tryToggleAvanzadoSubmodulos() async {
    if (_points == null && !_loadingPoints) {
      await _loadPoints();
    }

    final pts = _points ?? 0;
    if (pts < 75) {
      setState(() => _mascotState = MascotState.alert);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 75 puntos para acceder a los módulos avanzados.'),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _mascotState = MascotState.idle);
      });
      return;
    }

    setState(() {
      _showAvanzadoSubmodulos = !_showAvanzadoSubmodulos;
      _showPrincipianteSubmodulos = false;
      _expandedIdxAvanzado = null; // reset mini-señales
      _mascotState = MascotState.pointing;

      if (_showAvanzadoSubmodulos) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _mascotState = MascotState.idle;
      }
    });
  }

  // --- NUEVO: manejar tap sobre un submódulo para desplegar 5/10/15 ---
  void _onTapSubmodulo({
    required bool isAvanzado,
    required int index,
  }) {
    setState(() {
      if (isAvanzado) {
        _expandedIdxAvanzado = (_expandedIdxAvanzado == index) ? null : index;
        _expandedIdxPrincipiante = null;
      } else {
        _expandedIdxPrincipiante = (_expandedIdxPrincipiante == index) ? null : index;
        _expandedIdxAvanzado = null;
      }
    });
  }

  // --- NUEVO: navegar con el número de preguntas seleccionado ---
  void _startModulo({
    required String nombre,
    required String nivelUI, // 'Principiante' | 'Avanzado'
    required int preguntas,  // 5 | 10 | 15
  }) {
    final nivelLower = nivelUI.toLowerCase();
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
      // fallback: no debería pasar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abrir $nombre ($preguntas preguntas) — $nivelLower')),
        );
    }
  }

  // Construye el bloque de submódulos manteniendo TUS CoinButton
  Widget _buildSubmodulos(String nivel) {
    final bool isAvanzado = (nivel == 'Avanzado');

    final List<Map<String, dynamic>> submodulos = [
      {
        'nombre': 'Simulaciones',
        'icono': Icons.videogame_asset,
        'rimDark': const Color(0xFFB23A2E),
        'rimLight': const Color(0xFFFF9E80),
        'faceDark': const Color(0xFFE53935),
        'faceLight': const Color(0xFFFF8A80),
        'depth': 6.0,
      },
      {
        'nombre': 'Señales',
        'icono': Icons.traffic,
        'rimDark': const Color(0xFFCC7A00),
        'rimLight': const Color(0xFFFFD180),
        'faceDark': const Color(0xFFFF9800),
        'faceLight': const Color(0xFFFFE0B2),
        'depth': 6.0,
      },
      {
        'nombre': 'Escenarios',
        'icono': Icons.landscape,
        'rimDark': const Color(0xFF2E7D32),
        'rimLight': const Color(0xFFA5D6A7),
        'faceDark': const Color(0xFF2DBD3A),
        'faceLight': const Color(0xFF6CD93B),
        'depth': 6.0,
      },
    ];

    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: submodulos.asMap().entries.map((entry) {
            final int idx = entry.key;
            final m = entry.value;
            final bool expanded = isAvanzado
                ? (_expandedIdxAvanzado == idx)
                : (_expandedIdxPrincipiante == idx);

            return Column(
              children: [
                // TUS CoinButton: no cambia, solo su onTap
                CoinButton(
                  icon: m['icono'],
                  size: 78,
                  rimDark: m['rimDark'],
                  rimLight: m['rimLight'],
                  faceDark: m['faceDark'],
                  faceLight: m['faceLight'],
                  depth: m['depth'],
                  onTap: () => _onTapSubmodulo(isAvanzado: isAvanzado, index: idx),
                ),
                const SizedBox(height: 8),
                Text(
                  m['nombre'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // --- NUEVO: señales 5 / 10 / 15 debajo del botón al tocarlo ---
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: expanded
                      ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [5, 10, 15].map((q) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _TrafficCircleSign(
                            text: '$q',
                            onTap: () => _startModulo(
                              nombre: m['nombre'] as String,
                              nivelUI: nivel,
                              preguntas: q,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pointsText = (_points == null) ? '—' : _points.toString();
    final canEnterAdvanced = (_points ?? 0) >= 75;

    return Scaffold(
      body: Stack(
        children: [
          // CONTENIDO PRINCIPAL
          Column(
            children: [
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
                          'Modulos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // --- chip de puntos + refresh + perfil ---
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.person, color: Colors.white),
                                onPressed: () async {
                                  final res = await requireAuthOrAlert(
                                    context,
                                    featureName: 'Perfil',
                                    onGoLogin: () => Navigator.of(context).pushNamed('/login'),
                                  );
                                  if (res != AuthPromptResult.proceed) return;
                                  Navigator.of(context).push(
                                    fadeRoute(const ProfileScreen()),
                                  );
                                },
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
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // PRINCIPIANTES
                        Column(
                          children: [
                            const Text(
                              'PRINCIPIANTES',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            CoinButton(
                              icon: Icons.star,
                              size: 86,
                              rimDark: const Color(0xFF0D47A1),
                              rimLight: const Color(0xFF90CAF9),
                              faceDark: const Color(0xFF1976D2),
                              faceLight: const Color(0xFF64B5F6),
                              depth: 8.0,
                              onTap: () {
                                global_identifier.counter = 0;
                                _togglePrincipianteSubmodulos();
                              },
                            ),
                            if (_showPrincipianteSubmodulos)
                              _buildSubmodulos('Principiante'),
                          ],
                        ),

                        const SizedBox(height: 50),

                        // AVANZADOS
                        Column(
                          children: [
                            Text(
                              'AVANZADOS',
                              style: TextStyle(
                                color: canEnterAdvanced
                                    ? const Color(0xFF1976D2)  // Azul normal si tiene puntos
                                    : Colors.grey,              // Gris si no tiene 75 puntos
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 10),
                            CoinButton(
                              icon: Icons.menu_book,
                              size: 86,
                              // 👇 Cambia el color según si tiene suficientes puntos
                              rimDark: canEnterAdvanced ? const Color(0xFFB57A00) : Colors.grey.shade600,
                              rimLight: canEnterAdvanced ? const Color(0xFFFFE082) : Colors.grey.shade400,
                              faceDark: canEnterAdvanced ? const Color(0xFFF4C23A) : Colors.grey.shade500,
                              faceLight: canEnterAdvanced ? const Color(0xFFFFF3A0) : Colors.grey.shade300,
                              depth: 8.0,
                              onTap: () async {
                                global_identifier.counter = 1;
                                await _tryToggleAvanzadoSubmodulos(); // mantiene tu validación actual
                              },
                            ),

                            if (_showAvanzadoSubmodulos)
                              _buildSubmodulos('Avanzado'),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          //  MASCOTA FLOTANTE
          Positioned(
            bottom: 20,
            right: 20,
            child: TrafficMascot(
              state: _mascotState,
              size: 200,
              onTap: () {
                setState(() {
                  _mascotState = MascotState.celebrating;
                });
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _mascotState = MascotState.idle;
                    });
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Señal de tránsito circular (borde rojo y fondo blanco) para 5/10/15
class _TrafficCircleSign extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _TrafficCircleSign({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD32F2F), width: 5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }
}
