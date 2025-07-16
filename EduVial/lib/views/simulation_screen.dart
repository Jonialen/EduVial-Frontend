// Importación de librerías necesarias
import 'dart:convert'; // Para decodificar respuestas JSON
import 'dart:math'; // Para generar números aleatorios
import 'package:flutter/material.dart'; // Para UI en Flutter
import 'package:http/http.dart' as http; // Para hacer peticiones HTTP
import '../models/pregunta.dart'; // Modelo de datos de las preguntas
import 'package:eduvial/controllers/global_identifier.dart'; // Variable global para identificar nivel

// Widget principal de tipo Stateful para mostrar simulaciones según el rol
class SimulationScreen extends StatefulWidget {
  final String rol; // El rol define el nivel de dificultad

  const SimulationScreen({Key? key, required this.rol}) : super(key: key);

  @override
  _SimulationScreenState createState() => _SimulationScreenState();
}

// Estado del widget SimulationScreen
class _SimulationScreenState extends State<SimulationScreen> {
  List<Pregunta> preguntas = []; // Lista de todas las preguntas filtradas
  bool cargando = true; // Estado de carga de los datos
  String error = ''; // Mensaje de error si ocurre
  Pregunta? preguntaActual; // Pregunta actualmente mostrada
  List<OpcionRespuesta> opciones = []; // Opciones para la pregunta actual
  int? opcionSeleccionada; // Índice de opción que el usuario seleccionó
  bool respuestaMostrada = false; // Si ya se mostró la respuesta correcta

  // Se ejecuta al iniciar el widget
  @override
  void initState() {
    super.initState();
    cargarPreguntas(); // Carga las preguntas al iniciar
  }

  // Método que obtiene el nivel según la variable global
  String getNivelDesdeRol(String rol) {
    if (global_identifier.counter==0) return 'Básico';
    if (global_identifier.counter==1) return 'Avanzado';
    return 'Intermedio';
  }

  // Método que obtiene las opciones para una pregunta dada
  Future<void> cargarOpciones(int preguntaId) async {
    try {
      final response = await http.get(
        Uri.parse('https://dev.eduvial.space/api/quest/$preguntaId/options'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> datos = json.decode(response.body);
        setState(() {
          opciones = datos.map((json) => OpcionRespuesta.fromJson(json)).toList();
          opcionSeleccionada = null;
          respuestaMostrada = false;
        });
      }
    } catch (e) {
      print('Error al cargar opciones: $e');
    }
  }

  // Método que carga todas las preguntas y filtra por nivel
  Future<void> cargarPreguntas() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://dev.eduvial.space/api/quest'),
      ).timeout(const Duration(seconds: 15)); // Límite de espera

      if (response.statusCode == 200) {
        final List datos = json.decode(response.body);
        final todasLasPreguntas = datos
            .where((json) => json != null)
            .map((json) => Pregunta.fromJson(json))
            .toList();

        final nivelUsuario = getNivelDesdeRol(widget.rol);
        final preguntasFiltradas = todasLasPreguntas
            .where((p) => p.lvl == nivelUsuario)
            .toList();

        if (preguntasFiltradas.isNotEmpty) {
          final random = Random();
          final pregunta = preguntasFiltradas[random.nextInt(preguntasFiltradas.length)];

          setState(() {
            preguntas = preguntasFiltradas;
            preguntaActual = pregunta;
            cargando = false;
          });

          await cargarOpciones(pregunta.id);
        } else {
          setState(() {
            error = 'No hay preguntas para tu nivel (${widget.rol})';
            cargando = false;
          });
        }
      } else {
        throw Exception('Error al cargar preguntas');
      }
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        cargando = false;
      });
    }
  }

  // Método para seleccionar una opción
  void seleccionarOpcion(int index) {
    if (!respuestaMostrada) {
      setState(() {
        opcionSeleccionada = index;
      });
    }
  }

  // Método para mostrar si la respuesta fue correcta
  void mostrarRespuesta() {
    setState(() {
      respuestaMostrada = true;
    });
  }

  // Muestra una nueva pregunta aleatoria
  void siguientePregunta() {
    if (preguntas.isEmpty) return;

    final random = Random();
    final pregunta = preguntas[random.nextInt(preguntas.length)];

    setState(() {
      preguntaActual = pregunta;
      respuestaMostrada = false;
      opcionSeleccionada = null;
    });

    cargarOpciones(pregunta.id);
  }

  // Interfaz de usuario
  @override
  Widget build(BuildContext context) {
    // Si se está cargando, mostrar indicador de carga
    if (cargando) {
      return Scaffold(
        appBar: AppBar(title: Text("Simulación - ${widget.rol}")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si hubo un error al cargar
    if (error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Simulación - ${widget.rol}")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: cargarPreguntas,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // UI principal cuando hay preguntas
    return Scaffold(
      appBar: AppBar(
        title: Text("Simulación - ${widget.rol}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: siguientePregunta,
            tooltip: 'Siguiente pregunta',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preguntaActual != null) ...[
              // Muestra la tarjeta con la pregunta
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preguntaActual!.txt,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Nivel: ${preguntaActual!.lvl}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Opciones:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Lista de opciones de respuesta
              ...opciones.asMap().entries.map((entry) {
                final index = entry.key;
                final opcion = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: respuestaMostrada && opcion.correct == true
                      ? Colors.green[100] // Si es la correcta
                      : (opcionSeleccionada == index
                          ? (respuestaMostrada
                              ? Colors.red[100] // Si seleccionó mal
                              : Colors.blue[100]) // Aún no muestra resultado
                          : null),
                  child: ListTile(
                    title: Text(opcion.txt),
                    onTap: () => seleccionarOpcion(index),
                  ),
                );
              }),
              const SizedBox(height: 20),
              // Botón para verificar respuesta
              if (opcionSeleccionada != null && !respuestaMostrada)
                Center(
                  child: ElevatedButton(
                    onPressed: mostrarRespuesta,
                    child: const Text('Verificar respuesta'),
                  ),
                ),
              // Botón para continuar a siguiente pregunta
              if (respuestaMostrada)
                Center(
                  child: ElevatedButton(
                    onPressed: siguientePregunta,
                    child: const Text('Siguiente Pregunta'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
