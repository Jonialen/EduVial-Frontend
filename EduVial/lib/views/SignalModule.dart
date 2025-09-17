import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/controllers/global_identifier.dart';

class SignalModule extends StatelessWidget {
  final String nivel; // 'Principiante' | 'Avanzado'

  const SignalModule({super.key, required this.nivel});

  String _mapNivelToData(String nivelUI) {
    // Ajusta esto a cómo vienen tus preguntas: en tu código usabas 'Básico' y 'Avanzado'
    if (global_identifier.counter == 0) return 'Básico';
    if (global_identifier.counter == 1) return 'Avanzado';
    // Fallback
    return nivelUI == 'Principiante' ? 'Básico' : 'Avanzado';
  }

  @override
  Widget build(BuildContext context) {
    final levelForData = _mapNivelToData(nivel);

    return ChangeNotifierProvider(
      create: (_) => QuestionController(
        category: 'Señales',
        level: levelForData,
        maxQuestions: 5,
      )..init(),
      child: const _SignalModuleView(),
    );
  }
}

class _SignalModuleView extends StatefulWidget {
  const _SignalModuleView();

  @override
  State<_SignalModuleView> createState() => _SignalModuleViewState();
}

class _SignalModuleViewState extends State<_SignalModuleView> {
  @override
  Widget build(BuildContext context) {
    final qc = context.watch<QuestionController>();

    if (qc.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Módulo de Señales')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (qc.error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Módulo de Señales')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(qc.error),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: qc.init,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final current = qc.current;
    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Módulo de Señales')),
        body: const Center(child: Text('Sin preguntas')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Módulo de Señales (${qc.index + 1}/${qc.questions.length})"),
        actions: [
          if (qc.userPoints != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('Total: ${qc.userPoints}'),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('Puntaje lección: ${qc.scoreLessonPoints}'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (qc.answerShown) {
                // si ya mostró respuesta, avanzar
                if (qc.isLast) {
                  await _showSummary(context, qc);
                } else {
                  await qc.next();
                }
              } else {
                // si no, solo ignorar
              }
            },
            tooltip: 'Siguiente',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.txt,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text("Nivel: ${current.lvl}"),
                    Text("Categoría: ${current.cat}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Opciones:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...qc.options.asMap().entries.map((entry) {
              final index = entry.key;
              final opcion = entry.value;
              final isSelected = qc.selectedIndex == index;
              final isCorrect = opcion.correct == true;
              final color =
              qc.answerShown && isCorrect ? Colors.green[100] :
              (isSelected ? (qc.answerShown ? Colors.red[100] : Colors.blue[100]) : null);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: color,
                child: ListTile(
                  title: Text(opcion.txt),
                  onTap: () => qc.selectOption(index),
                ),
              );
            }),
            const SizedBox(height: 20),
            if (qc.selectedIndex != null && !qc.answerShown)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final correct = qc.verifySelected();
                    if (correct == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Correcto! +5 puntos')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Respuesta incorrecta')),
                      );
                    }
                  },
                  child: const Text('Verificar respuesta'),
                ),
              ),
            if (qc.answerShown)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (qc.isLast) {
                      await _showSummary(context, qc);
                    } else {
                      await qc.next();
                    }
                  },
                  child: Text(qc.isLast ? 'Ver resultados' : 'Siguiente'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSummary(BuildContext context, QuestionController qc) async {
    final totalNew = await qc.finishAndSync(); // PUT points

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Módulo completado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Respondiste ${qc.scoreLesson} de ${qc.questions.length} correctamente.'),
            const SizedBox(height: 12),
            Text('Puntos añadidos: ${qc.scoreLessonPoints}'),
            if (totalNew != null) Text('Total actual: $totalNew'),
            const SizedBox(height: 12),
            Text(
              qc.scoreLesson >= (qc.questions.length / 2) ? 'Buen trabajo' : 'Puedes mejorar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: qc.scoreLesson >= (qc.questions.length / 2) ? Colors.green : Colors.red,
              ),
            ),
            if (totalNew == null)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'No se pudo sincronizar el puntaje con el servidor.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await qc.restart(); // recarga con nuevas preguntas
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
}
