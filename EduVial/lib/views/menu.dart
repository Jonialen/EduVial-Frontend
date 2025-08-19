import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eduvial/views/SignalModule.dart';
import 'package:eduvial/views/simulation_screen.dart';
import 'package:eduvial/views/UserProfile.dart';
import 'package:eduvial/controllers/global_identifier.dart';
import 'package:eduvial/views/scenario_module.dart';
import '../widgets/mascot/traffic_mascot.dart';
import '../widgets/coin_button.dart'; //  CoinButton

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

    // Iniciar animaciones automáticas cada 5 segundos
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
      _mascotState = MascotState.pointing;

      if (_showPrincipianteSubmodulos) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _mascotState = MascotState.idle;
      }
    });
  }

  void _toggleAvanzadoSubmodulos() {
    setState(() {
      _showAvanzadoSubmodulos = !_showAvanzadoSubmodulos;
      _showPrincipianteSubmodulos = false;
      _mascotState = MascotState.pointing;

      if (_showAvanzadoSubmodulos) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _mascotState = MascotState.idle;
      }
    });
  }

  Widget _buildSubmodulos(String nivel) {
    final List<Map<String, dynamic>> submodulos = [
      {
        'nombre': 'Simulaciones',
        'icono': Icons.videogame_asset,
        // paleta “moneda” roja
        'rimDark': const Color(0xFFB23A2E),
        'rimLight': const Color(0xFFFF9E80),
        'faceDark': const Color(0xFFE53935),
        'faceLight': const Color(0xFFFF8A80),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimulationScreen(rol: nivel.toLowerCase()),
            ),
          );
        },
      },
      {
        'nombre': 'Señales',
        'icono': Icons.traffic,
        // paleta “moneda” naranja
        'rimDark': const Color(0xFFCC7A00),
        'rimLight': const Color(0xFFFFD180),
        'faceDark': const Color(0xFFFF9800),
        'faceLight': const Color(0xFFFFE0B2),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignalModule(nivel: nivel.toLowerCase()),
            ),
          );
        },
      },
      {
        'nombre': 'Escenarios',
        'icono': Icons.landscape,
        // paleta “moneda” verde
        'rimDark': const Color(0xFF2E7D32),
        'rimLight': const Color(0xFFA5D6A7),
        'faceDark': const Color(0xFF2DBD3A),
        'faceLight': const Color(0xFF6CD93B),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScenarioModule(rol: nivel.toLowerCase()),
            ),
          );
        },
      },
    ];

    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: submodulos.map((m) {
            return Column(
              children: [
                CoinButton(
                  icon: m['icono'],
                  size: 78,
                  rimDark: m['rimDark'],
                  rimLight: m['rimLight'],
                  faceDark: m['faceDark'],
                  faceLight: m['faceLight'],
                  onTap: m['onTap'],
                ),
                const SizedBox(height: 8),
                Text(
                  m['nombre'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(),
                                ),
                              );
                            },
                          ),
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
                              // paleta moneda azul 
                              rimDark: const Color(0xFF0D47A1),
                              rimLight: const Color(0xFF90CAF9),
                              faceDark: const Color(0xFF1976D2),
                              faceLight: const Color(0xFF64B5F6),
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
                            const Text(
                              'AVANZADOS',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            CoinButton(
                              icon: Icons.menu_book, // libro como tu ejemplo
                              size: 86,
                              // paleta “moneda” dorada
                              rimDark: const Color(0xFFB57A00),
                              rimLight: const Color(0xFFFFE082),
                              faceDark: const Color(0xFFF4C23A),
                              faceLight: const Color(0xFFFFF3A0),
                              onTap: () {
                                global_identifier.counter = 1;
                                _toggleAvanzadoSubmodulos();
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
              size: 100,
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
