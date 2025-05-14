import 'package:eduvial/views/SignalModule.dart';
import 'package:flutter/material.dart';
import 'package:eduvial/views/simulation_screen.dart';
import 'package:eduvial/views/UserProfile.dart';

class Menu extends StatefulWidget {
  const Menu({Key? key}) : super(key: key);

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  bool _showPrincipianteSubmodulos = false;
  bool _showAvanzadoSubmodulos = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePrincipianteSubmodulos() {
    setState(() {
      _showPrincipianteSubmodulos = !_showPrincipianteSubmodulos;
      _showAvanzadoSubmodulos = false; // Cerrar el otro menú si está abierto

      if (_showPrincipianteSubmodulos) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleAvanzadoSubmodulos() {
    setState(() {
      _showAvanzadoSubmodulos = !_showAvanzadoSubmodulos;
      _showPrincipianteSubmodulos = false; // Cerrar el otro menú si está abierto

      if (_showAvanzadoSubmodulos) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildSubmodulos(String nivel) {
    // Lista de submódulos con sus nombres e iconos
    final List<Map<String, dynamic>> submodulos = [
      {
        'nombre': 'Simulaciones',
        'icono': Icons.videogame_asset,
        'color': Colors.redAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimulationScreen(nivel: nivel.toLowerCase()),
            ),
          );
        },
      },
      {
        'nombre': 'Señales',
        'icono': Icons.traffic,
        'color': Colors.orangeAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Signalmodule(nivel: nivel.toLowerCase()),
            ),
          );
        },
      },
      {
        'nombre': 'Escenarios',
        'icono': Icons.landscape,
        'color': Colors.greenAccent,
        'onTap': () {
          // Navegar a la pantalla de escenarios (aún no implementada)
          debugPrint('Navegando a escenarios de $nivel');
        },
      },
    ];

    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: submodulos.map((submodulo) {
            return Column(
              children: [
                InkWell(
                  onTap: submodulo['onTap'],
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: submodulo['color'],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        submodulo['icono'],
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  submodulo['nombre'],
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
      body: Column(
        children: [
          // Barra superior azul
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
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Botón PRINCIPIANTES con submódulos
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
                        // Círculo con estrella (botón 1)
                        InkWell(
                          onTap: _togglePrincipianteSubmodulos,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1976D2),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Mostrar submódulos si está activado
                        if (_showPrincipianteSubmodulos)
                          _buildSubmodulos('Principiante'),
                      ],
                    ),
                    const SizedBox(height: 50),
                    // Botón AVANZADOS con submódulos
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
                        InkWell(
                          onTap: _toggleAvanzadoSubmodulos,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.book,
                                color: Colors.grey,
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                        // Mostrar submódulos si está activado
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
    );
  }
}