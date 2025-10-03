import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/controllers/global_identifier.dart';
import 'package:eduvial/widgets/lesson_summary.dart'; // helper reutilizable

class SimulationScreen extends StatelessWidget {
  final String rol;

  const SimulationScreen({super.key, required this.rol});

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
        category: 'Simulaciones',
        level: levelForData,
        maxQuestions: 5,
      )..init(),
      child: const _SimulationView(),
    );
  }
}

class _SimulationView extends StatefulWidget {
  const _SimulationView();

  @override
  State<_SimulationView> createState() => _SimulationViewState();
}

class _SimulationViewState extends State<_SimulationView> {
  static const _autoAdvanceDelay = Duration(milliseconds: 2500);

  Future<void> _handleVerifyAndAutoAdvance(QuestionController qc) async {
    final result = qc.verifySelected();
    if (result == null) return; // no había selección

    // Feedback inmediato
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ? '¡Correcto! +5 puntos' : 'Respuesta incorrecta'),
        backgroundColor: result ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 1200),
      ),
    );

    // Espera breve para que el usuario vea el color en la opción + snackbar
    await Future.delayed(_autoAdvanceDelay);

    if (!mounted) return;

    if (qc.isLast) {
      // ✅ Usamos el helper general para mostrar el resumen y manejar puntos/login
      await showLessonSummaryDialog(
        context,
        qc,
        title: 'Simulaciones completado',
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
        appBar: AppBar(title: const Text('Simulaciones')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (qc.error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Simulaciones')),
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
        appBar: AppBar(title: const Text('Simulaciones')),
        body: const Center(child: Text('Sin preguntas')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Simulaciones (${qc.index + 1}/${qc.questions.length})"),
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
        absorbing: qc.busy, // bloquea taps durante transición
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
