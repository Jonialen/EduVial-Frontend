import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pregunta.dart';
import 'package:eduvial/controllers/global_identifier.dart';

class SignalModule extends StatefulWidget {
  final String nivel;

  const SignalModule({Key? key, required this.nivel}) : super(key: key);

  @override
  State<SignalModule> createState() => _SignalModuleState();
}

class _SignalModuleState extends State<SignalModule> {
  List<Pregunta> preguntas = [];
  bool cargando = true;
  String error = '';
  Pregunta? preguntaActual;
  List<OpcionRespuesta> opciones = [];
  int? opcionSeleccionada;
  bool respuestaMostrada = false;

  int indicePregunta = 0;
  int puntaje = 0;
  final int maxPreguntas = 10;

  @override
  void initState() {
    super.initState();
    cargarPreguntas();
  }

  String getNivelDesdeGlobal() {
    if (global_identifier.counter == 0) return 'Básico';
    if (global_identifier.counter == 1) return 'Avanzado';
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

        final nivelUsuario = getNivelDesdeGlobal();
        final preguntasFiltradas = todasLasPreguntas
            .where((p) => p.lvl == nivelUsuario)
            .toList();

        if (preguntasFiltradas.isNotEmpty) {
          preguntasFiltradas.shuffle();
          final preguntasLimitadas = preguntasFiltradas.take(maxPreguntas).toList();

          setState(() {
            preguntas = preguntasLimitadas;
            preguntaActual = preguntas.first;
            cargando = false;
            indicePregunta = 0;
            puntaje = 0;
          });

          await cargarOpciones(preguntaActual!.id);
        } else {
          setState(() {
            error = 'No hay señales para el nivel ${nivelUsuario}';
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
    if (opcionSeleccionada != null &&
        opcionSeleccionada! >= 0 &&
        opcionSeleccionada! < opciones.length) {
      setState(() {
        respuestaMostrada = true;

        if (opciones[opcionSeleccionada!].correct ?? false) {
          puntaje++;
        }
      });
    }
  }

  void siguientePregunta() {
    if (indicePregunta + 1 >= preguntas.length) {
      mostrarResumenFinal();
      return;
    }

    setState(() {
      indicePregunta++;
      preguntaActual = preguntas[indicePregunta];
      respuestaMostrada = false;
      opcionSeleccionada = null;
    });

    cargarOpciones(preguntaActual!.id);
  }

  void mostrarResumenFinal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Módulo completado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Respondiste $puntaje de ${preguntas.length} correctamente.'),
            const SizedBox(height: 12),
            Text(
              puntaje >= (preguntas.length / 2)
                  ? 'Buen trabajo'
                  : 'Puedes mejorar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: puntaje >= (preguntas.length / 2) ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              cargarPreguntas();
            },
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Volver al menú'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text("Módulo de Señales")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Módulo de Señales")),
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
        title: const Text("Módulo de Señales"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: siguientePregunta,
            tooltip: 'Siguiente señal',
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
                      ? (respuestaMostrada ? Colors.red[100] : Colors.blue[100])
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
                    child: Text(
                      indicePregunta + 1 >= preguntas.length
                          ? 'Ver resultados'
                          : 'Siguiente Señal',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
