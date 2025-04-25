import 'package:flutter/material.dart';

class Menu extends StatelessWidget {
  const Menu({Key? key}) : super(key: key);

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
                      child: const Icon(
                        Icons.list_alt,
                        color: Colors.white,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón EMPEZAR
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
                        onTap: () {
                          // Acción al presionar el botón EMPEZAR
                          debugPrint('Botón EMPEZAR presionado');
                          // Aquí podrías navegar a la siguiente pantalla
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => NextScreen()));
                        },
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
                    ],
                  ),
                  const SizedBox(height: 50),
                  // Botón adicional (botón 2)
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
                        onTap: () {
                          // Acción al presionar el botón LECCIONES
                          debugPrint('Botón LECCIONES presionado');
                          // Aquí podrías navegar a otra pantalla
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => LessonsScreen()));
                        },
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}