import 'package:flutter/material.dart';

class SimulationScreen extends StatefulWidget {
  final String nivel; // "principiante" o "avanzado"

  const SimulationScreen({
    Key? key,
    required this.nivel,
  }) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  // En el futuro, estas preguntas vendrán de una API
  // Este es solo un ejemplo de la estructura de datos esperada
  final List<Map<String, dynamic>> preguntasPrincipiante = [
    {
      'imagen': 'assets/images/simulaciones/principiante1.jpg',
      'pregunta': '¿Qué debe hacer en esta intersección?',
      'opciones': [
        'Avanzar sin detenerse',
        'Detenerse completamente y ceder el paso',
        'Acelerar para pasar rápidamente',
        'Tocar el claxon y seguir'
      ],
      'respuestaCorrecta': 1,
      'explicacion': 'En una señal de ALTO, debes detenerte completamente y ceder el paso a los vehículos que tienen la preferencia.'
    },
    {
      'imagen': 'assets/images/simulaciones/principiante2.jpg',
      'pregunta': 'En esta situación con lluvia, ¿qué debe hacer?',
      'opciones': [
        'Mantener la misma velocidad',
        'Aumentar la velocidad',
        'Reducir la velocidad y aumentar la distancia de seguimiento',
        'Encender las luces altas'
      ],
      'respuestaCorrecta': 2,
      'explicacion': 'En condiciones de lluvia, se debe reducir la velocidad y aumentar la distancia de seguimiento para compensar la menor tracción y mayor distancia de frenado.'
    },
    {
      'imagen': 'assets/images/simulaciones/principiante3.jpg',
      'pregunta': '¿Qué significa esta señal de tránsito?',
      'opciones': [
        'Prohibido el paso',
        'Ceda el paso',
        'No estacionar',
        'Zona escolar'
      ],
      'respuestaCorrecta': 1,
      'explicacion': 'La señal triangular invertida indica "Ceda el paso", lo que significa que debe reducir la velocidad y dar prioridad a los vehículos en la vía a la que se incorpora.'
    },
  ];

  // En el futuro, estas preguntas vendrán de una API
  final List<Map<String, dynamic>> preguntasAvanzado = [
    {
      'imagen': 'assets/images/simulaciones/avanzado1.jpg',
      'pregunta': 'En esta glorieta, ¿quién tiene la preferencia de paso?',
      'opciones': [
        'Los vehículos que están dentro de la glorieta',
        'Los vehículos que van a entrar a la glorieta',
        'Los vehículos más grandes',
        'Los vehículos que vienen por la derecha'
      ],
      'respuestaCorrecta': 0,
      'explicacion': 'En una glorieta, los vehículos que ya están circulando dentro tienen preferencia sobre los que pretenden entrar.'
    },
    {
      'imagen': 'assets/images/simulaciones/avanzado2.jpg',
      'pregunta': 'En esta situación de adelantamiento, ¿qué acción es correcta?',
      'opciones': [
        'Adelantar por la derecha aprovechando el espacio',
        'Acelerar para adelantar antes de la curva',
        'Esperar a tener visibilidad completa antes de adelantar',
        'Tocar el claxon para advertir y adelantar'
      ],
      'respuestaCorrecta': 2,
      'explicacion': 'Siempre se debe esperar a tener visibilidad completa antes de realizar un adelantamiento, nunca adelantar en curvas o con visibilidad reducida.'
    },
    {
      'imagen': 'assets/images/simulaciones/avanzado3.jpg',
      'pregunta': 'Con esta señalización en obra, ¿qué debe hacer?',
      'opciones': [
        'Mantener la velocidad para no entorpecer el tráfico',
        'Reducir la velocidad y seguir las indicaciones',
        'Buscar una ruta alternativa',
        'Adelantar a los vehículos que van despacio'
      ],
      'respuestaCorrecta': 1,
      'explicacion': 'En zonas de obras, se debe reducir la velocidad y seguir estrictamente las indicaciones de la señalización temporal y de los operarios.'
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
          title: const Text('Simulación Completada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Has completado la simulación de nivel ${widget.nivel}'),
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
        title: Text('Simulación ${widget.nivel.toUpperCase()}'),
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