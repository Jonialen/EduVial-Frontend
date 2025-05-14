import 'package:flutter/material.dart';

class Signalmodule extends StatefulWidget {
  final String nivel; // "principiante" o "avanzado"

  const Signalmodule({
    Key? key,
    required this.nivel,
  }) : super(key: key);

  @override
  State<Signalmodule> createState() => _SignalModuleState();
}

class _SignalModuleState extends State<Signalmodule> {
  // En el futuro, estas preguntas vendrán de una API
  // Este es solo un ejemplo de la estructura de datos esperada
  final List<Map<String, dynamic>> preguntasPrincipiante = [
    {
      'imagen': 'assets/images/signalModule/principiante1.jpg',
      'pregunta': '¿Qué representa la siguiente señal de transito?',
      'opciones': [
        'Alto / Stop',
        'Límite de velocidad',
        'Curva peligrosa',
        'Cruce de peatones'
      ],
      'respuestaCorrecta': 3,
      'explicacion': 'Puede haber peatones cruzando.'
    },
    {
      'imagen': 'assets/images/signalModule/principiante2.jpg',
      'pregunta': '¿Qué representa la siguiente señal de transito?',
      'opciones': [
        'Intersección adelante',
        'Reducción de carriles',
        'Puente levadizo',
        'Zona de derrumbes'
      ],
      'respuestaCorrecta': 2,
      'explicacion': 'El puente puede elevarse. Precaución.'
    },
    {
      'imagen': 'assets/images/signalModule/principiante3.jpg',
      'pregunta': '¿Qué representa la siguiente señal de transito?',
      'opciones': [
        'Prohibido el paso',
        'Prohibido girar a la izquierda',
        'Prohibido girar a la derecha',
        'Prohibido peatones'
      ],
      'respuestaCorrecta': 2,
      'explicacion': 'No se permite doblar a la derecha.'

    },
  ];

  // En el futuro, estas preguntas vendrán de una API
  final List<Map<String, dynamic>> preguntasAvanzado = [
    {
      'imagen': 'assets/images/signalModule/principiante1.jpg',
      'pregunta': '¿Qué representa la siguiente señal de transito?',
      'opciones': [
        'Alto / Stop',
        'Límite de velocidad',
        'Curva peligrosa',
        'Cruce de peatones'
      ],
      'respuestaCorrecta': 3,

    },
    {
      'imagen': 'assets/images/signalModule/principiante2.jpg',
      'pregunta': '¿Qué representa la siguiente señal de transito?',
      'opciones': [
        'Intersección adelante',
        'Reducción de carriles',
        'Puente levadizo',
        'Zona de derrumbes'
      ],
      'respuestaCorrecta': 2,

    },
    {
      'imagen': 'assets/images/signalModule/principiante3.jpg',
      'pregunta': '¿Qué representa la siguiente señal de transito?',
      'opciones': [
        'Prohibido el paso',
        'Prohibido girar a la izquierda',
        'Prohibido girar a la derecha',
        'Prohibido peatones'
      ],
      'respuestaCorrecta': 2,

    },
  ];

  int preguntaActual = 0;
  int puntuacion = 0;
  bool respondido = false;
  int? seleccionUsuario;
  bool mostrarExplicacion = false;

  // Obtener la lista de preguntas según el nivel
  List<Map<String, dynamic>> get preguntas {
    return widget.nivel == 'principiante' ? preguntasPrincipiante : preguntasAvanzado;
  }

  void verificarRespuesta(int opcionSeleccionada) {
    if (respondido) return; // Evitar múltiples respuestas

    setState(() {
      respondido = true;
      seleccionUsuario = opcionSeleccionada;
      mostrarExplicacion = true;

      if (opcionSeleccionada == preguntas[preguntaActual]['respuestaCorrecta']) {
        puntuacion++;
      }
    });
  }

  void siguientePregunta() {
    if (preguntaActual < preguntas.length - 1) {
      setState(() {
        preguntaActual++;
        respondido = false;
        seleccionUsuario = null;
        mostrarExplicacion = false;
      });
    } else {
      // Mostrar resultados finales cuando se completan todas las preguntas
      mostrarResultados();
    }
  }

  void mostrarResultados() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cuestionario Completado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Has completado señales de nivel ${widget.nivel}'),
              const SizedBox(height: 16),
              Text(
                'Tu puntuación: $puntuacion de ${preguntas.length}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: puntuacion > (preguntas.length / 2) ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                Navigator.of(context).pop(); // Volver a la pantalla anterior
              },
              child: const Text('Volver al menú'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                // Reiniciar la simulación
                setState(() {
                  preguntaActual = 0;
                  puntuacion = 0;
                  respondido = false;
                  seleccionUsuario = null;
                  mostrarExplicacion = false;
                });
              },
              child: const Text('Intentar de nuevo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preguntaActualData = preguntas[preguntaActual];

    return Scaffold(
      appBar: AppBar(
        title: Text('Señales ${widget.nivel.toUpperCase()}'),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Indicador de progreso
          LinearProgressIndicator(
            value: (preguntaActual + 1) / preguntas.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),

          // Contenedor principal con scroll
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Contador de preguntas
                  Text(
                    'Pregunta ${preguntaActual + 1} de ${preguntas.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Imagen de la situación
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        preguntaActualData['imagen'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pregunta
                  Text(
                    preguntaActualData['pregunta'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Opciones de respuesta
                  ...List.generate(
                    preguntaActualData['opciones'].length,
                        (index) {
                      final bool esCorrecta = index == preguntaActualData['respuestaCorrecta'];
                      final bool seleccionada = seleccionUsuario == index;

                      // Determinar el color del botón según el estado
                      Color? buttonColor;
                      if (respondido) {
                        if (esCorrecta) {
                          buttonColor = Colors.green[100];
                        } else if (seleccionada) {
                          buttonColor = Colors.red[100];
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton(
                          onPressed: respondido ? null : () => verificarRespuesta(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            alignment: Alignment.centerLeft,
                          ),
                          child: Row(
                            children: [
                              // Indicador de opción (A, B, C, D)
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue[800],
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode('A'.codeUnitAt(0) + index),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Texto de la opción
                              Expanded(
                                child: Text(
                                  preguntaActualData['opciones'][index],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),

                              // Icono de correcto/incorrecto si ya respondió
                              if (respondido)
                                Icon(
                                  esCorrecta ? Icons.check_circle : (seleccionada ? Icons.cancel : null),
                                  color: esCorrecta ? Colors.green : (seleccionada ? Colors.red : null),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Explicación de la respuesta correcta
                  if (mostrarExplicacion) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explicación:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            preguntaActualData['explicacion'],
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Botón para continuar
          if (respondido)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: siguientePregunta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  preguntaActual < preguntas.length - 1 ? 'Siguiente Pregunta' : 'Ver Resultados',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}