import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pregunta.dart';
import 'package:eduvial/controllers/global_identifier.dart';

class SimulationScreen extends StatefulWidget {
  final String rol;

  const SimulationScreen({Key? key, required this.rol}) : super(key: key);

  @override
  _SimulationScreenState createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  List<Pregunta> preguntas = [];
  bool cargando = true;
  String error = '';
  Pregunta? preguntaActual;
  List<OpcionRespuesta> opciones = [];
  int? opcionSeleccionada;
  bool respuestaMostrada = false;

  @override
  void initState() {
    super.initState();
    cargarPreguntas();
  }

  String getNivelDesdeRol(String rol) {
    if (global_identifier.counter==0) return 'Básico';
    if (global_identifier.counter==1) return 'Avanzado';
    return 'Intermedio';
  }

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

  Future<void> cargarPreguntas() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://dev.eduvial.space/api/quest'),
      ).timeout(const Duration(seconds: 15));

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

  void seleccionarOpcion(int index) {
    if (!respuestaMostrada) {
      setState(() {
        opcionSeleccionada = index;
      });
    }
  }

  void mostrarRespuesta() {
    setState(() {
      respuestaMostrada = true;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
        appBar: AppBar(title: Text("Simulación - ${widget.rol}")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                      Text(
                        preguntaActual!.txt,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      //gText("Categoría: ${preguntaActual!.cat}"),
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
              ...opciones.asMap().entries.map((entry) {
                final index = entry.key;
                final opcion = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: respuestaMostrada && opcion.correct == true
                      ? Colors.green[100]
                      : (opcionSeleccionada == index
                      ? (respuestaMostrada
                      ? Colors.red[100]
                      : Colors.blue[100])
                      : null),
                  child: ListTile(
                    title: Text(opcion.txt),
                    onTap: () => seleccionarOpcion(index),
                  ),
                );
              }),
              const SizedBox(height: 20),
              if (opcionSeleccionada != null && !respuestaMostrada)
                Center(
                  child: ElevatedButton(
                    onPressed: mostrarRespuesta,
                    child: const Text('Verificar respuesta'),
                  ),
                ),
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