import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/controllers/global_identifier.dart';
import 'package:eduvial/widgets/lesson_summary.dart'; // ← usamos el helper reutilizable

class ScenarioModule extends StatelessWidget {
  final String rol;

  const ScenarioModule({super.key, required this.rol});

  String _mapNivelToData(String nivelUI) {
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
  static const _autoAdvanceDelay = Duration(milliseconds: 2500);

  Future<void> _handleVerifyAndAutoAdvance(QuestionController qc) async {
    final result = qc.verifySelected();
    if (result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ? '¡Correcto! +5 puntos' : 'Respuesta incorrecta'),
        backgroundColor: result ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 1200),
      ),
    );

    await Future.delayed(_autoAdvanceDelay);
    if (!mounted) return;

    if (qc.isLast) {
      // 👇 Reutilizamos el helper para el resumen
      await showLessonSummaryDialog(
        context,
        qc,
        title: 'Módulo de Escenarios completado',
        onExit: () async {
          // el helper ya cierra el diálogo; aquí solo volvemos al menú
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
    } else {
      await qc.next();
    }
  }

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
                onPressed: qc.busy ? null : qc.init,
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
        ],
      ),
      body: AbsorbPointer(
        absorbing: qc.busy,
        child: SingleChildScrollView(
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
                    onPressed: qc.busy ? null : () => _handleVerifyAndAutoAdvance(qc),
                    child: const Text('Verificar respuesta'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
