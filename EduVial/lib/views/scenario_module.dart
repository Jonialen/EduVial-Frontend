import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/controllers/global_identifier.dart';

class ScenarioModule extends StatelessWidget {
  final String rol; // lo usabas como nivel (“principiante”/“avanzado”)

  const ScenarioModule({super.key, required this.rol});

  String _mapNivelToData(String nivelUI) {
    // Ajusta a tus valores reales en BD
    if (global_identifier.counter == 0) return 'Básico';
    if (global_identifier.counter == 1) return 'Avanzado';
    return nivelUI.toLowerCase().startsWith('p') ? 'Básico' : 'Avanzado';
  }

  @override
  Widget build(BuildContext context) {
    final levelForData = _mapNivelToData(rol);

    return ChangeNotifierProvider(
      create: (_) => QuestionController(
        category: 'Escenarios',
        level: levelForData,
        maxQuestions: 5,
      )..init(),
      child: const _ScenarioModuleView(),
    );
  }
}

class _ScenarioModuleView extends StatefulWidget {
  const _ScenarioModuleView();

  @override
  State<_ScenarioModuleView> createState() => _ScenarioModuleViewState();
}

class _ScenarioModuleViewState extends State<_ScenarioModuleView> {
  @override
  Widget build(BuildContext context) {
    final qc = context.watch<QuestionController>();

    if (qc.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Módulo de Escenarios')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (qc.error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Módulo de Escenarios')),
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
        appBar: AppBar(title: const Text('Módulo de Escenarios')),
        body: const Center(child: Text('Sin preguntas')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Módulo de Escenarios (${qc.index + 1}/${qc.questions.length})"),
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
                if (qc.isLast) {
                  await _showSummary(context, qc);
                } else {
                  await qc.next();
                }
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
    final totalNew = await qc.finishAndSync();

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
              await qc.restart();
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
