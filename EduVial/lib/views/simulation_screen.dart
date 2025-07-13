import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pregunta.dart';
import 'package:eduvial/controllers/global_identifier.dart';

// Pantalla principal de simulación que recibe un rol para determinar nivel
class SimulationScreen extends StatefulWidget {
  final String rol;

  const SimulationScreen({Key? key, required this.rol}) : super(key: key);

  @override
  _SimulationScreenState createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  // Lista de preguntas cargadas
  List<Pregunta> preguntas = [];
  // Estado de carga de datos
  bool cargando = true;
  // Mensaje de error en caso de fallo
  String error = '';
  // Pregunta actual que se muestra
  Pregunta? preguntaActual;
  // Opciones de respuesta para la pregunta actual
  List<OpcionRespuesta> opciones = [];
  // Índice de la opción seleccionada
  int? opcionSeleccionada;
  // Indica si ya se mostró la respuesta correcta
  bool respuestaMostrada = false;

  // Método que se llama al crear el widget, inicia la carga de preguntas
  @override
  void initState() {
    super.initState();
    cargarPreguntas();
  }

  // Función para obtener el nivel según el rol y un contador global
  String getNivelDesdeRol(String rol) {
    if (global_identifier.counter == 0) return 'Básico';
    if (global_identifier.counter == 1) return 'Avanzado';
    return 'Intermedio';
  }

  // Carga las opciones de respuesta para una pregunta específica desde la API
  Future<void> cargarOpciones(int preguntaId) async {
    try {
      final response = await http.get(
        Uri.parse('https://dev.eduvial.space/api/quest/$preguntaId/options'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> datos = json.decode(response.body);
        setState(() {
          // Mapea los datos recibidos a objetos OpcionRespuesta
          opciones = datos.map((json) => OpcionRespuesta.fromJson(json)).toList();
          opcionSeleccionada = null; // Reinicia selección
          respuestaMostrada = false;  // Respuesta aún no mostrada
        });
      }
    } catch (e) {
      // En caso de error imprime en consola
      print('Error al cargar opciones: $e');
    }
  }

  // Carga todas las preguntas desde la API y filtra según el nivel del usuario
  Future<void> cargarPreguntas() async {
    setState(() {
      cargando = true; // Activa indicador de carga
      error = '';       // Limpia mensaje de error
    });

    try {
      final response = await http.get(
        Uri.parse('https://dev.eduvial.space/api/quest'),
      ).timeout(const Duration(seconds: 15)); // Timeout para la petición

      if (response.statusCode == 200) {
        final List datos = json.decode(response.body);
        // Filtra preguntas no nulas y las convierte en objetos Pregunta
        final todasLasPreguntas = datos
            .where((json) => json != null)
            .map((json) => Pregunta.fromJson(json))
            .toList();

        // Obtiene el nivel según el rol
        final nivelUsuario = getNivelDesdeRol(widget.rol);
        // Filtra preguntas por nivel
        final preguntasFiltradas = todasLasPreguntas
            .where((p) => p.lvl == nivelUsuario)
            .toList();

        if (preguntasFiltradas.isNotEmpty) {
          final random = Random();
          // Selecciona una pregunta aleatoria del nivel filtrado
          final pregunta = preguntasFiltradas[random.nextInt(preguntasFiltradas.length)];

          setState(() {
            preguntas = preguntasFiltradas;
            preguntaActual = pregunta;
            cargando = false; // Fin de carga
          });

          // Carga las opciones para la pregunta seleccionada
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
      // Muestra error si falla la carga
      setState(() {
        error = 'Error: ${e.toString()}';
        cargando = false;
      });
    }
  }

  // Función para seleccionar una opción, solo si no se ha mostrado la respuesta aún
  void seleccionarOpcion(int index) {
    if (!respuestaMostrada) {
      setState(() {
        opcionSeleccionada = index;
      });
    }
  }

  // Cambia el estado para mostrar la respuesta correcta
  void mostrarRespuesta() {
    setState(() {
      respuestaMostrada = true;
    });
  }

  // Cambia a la siguiente pregunta aleatoria dentro de las cargadas
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

  // Construye la interfaz visual del widget
  @override
  Widget build(BuildContext context) {
    // Si está cargando, muestra indicador de progreso
    if (cargando) {
      return Scaffold(
        appBar: AppBar(title: Text("Simulación - ${widget.rol}")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si hay error, muestra mensaje y botón para reintentar
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

    // Pantalla principal con pregunta, opciones y controles
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
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Texto de la pregunta actual
                      Text(
                        preguntaActual!.txt,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Muestra el nivel de la pregunta
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

              // Lista de opciones con colores que indican selección y corrección
              ...opciones.asMap().entries.map((entry) {
                final index = entry.key;
                final opcion = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: respuestaMostrada && opcion.correct == true
                      ? Colors.green[100] // Verde si es la respuesta correcta mostrada
                      : (opcionSeleccionada == index
                      ? (respuestaMostrada
                          ? Colors.red[100]  // Rojo si es la opción seleccionada pero incorrecta
                          : Colors.blue[100]) // Azul si está seleccionada y aún no se muestra la respuesta
                      : null),
                  child: ListTile(
                    title: Text(opcion.txt),
                    onTap: () => seleccionarOpcion(index), // Permite seleccionar opción
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Botón para verificar respuesta solo si hay una opción seleccionada y no se mostró la respuesta
              if (opcionSeleccionada != null && !respuestaMostrada)
                Center(
                  child: ElevatedButton(
                    onPressed: mostrarRespuesta,
                    child: const Text('Verificar respuesta'),
                  ),
                ),

              // Botón para siguiente pregunta una vez mostrada la respuesta
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
