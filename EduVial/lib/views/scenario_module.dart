import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/controllers/global_identifier.dart';
import 'package:eduvial/widgets/lesson_summary.dart';

// Mascotas (evitar choque del enum)
import 'package:eduvial/widgets/mascot/traffic_mascot.dart';
import 'package:eduvial/widgets/mascot/traffic_cone_mascot.dart' hide MascotState;

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
      await showLessonSummaryDialog(
        context,
        qc,
        title: 'Módulo de Escenarios completado',
        onExit: () async {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // tamaño responsivo de la mascota
            final w = MediaQuery.of(context).size.width;
            final double mascotSize =
            w >= 1200 ? 160 : (w >= 900 ? 140 : (w >= 600 ? 120 : 96));

            return Container(
              color: const Color(0xFFF2F5F9),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Header: Mascota (izq, alternada) + Pregunta (der) ─────────
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Builder(
                            builder: (context) {
                              // par = señal, impar = cono (igual que Simulation)
                              final bool showCone = (qc.index % 2 == 1);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mascota
                                  SizedBox(
                                    width: mascotSize,
                                    height: mascotSize,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: showCone
                                          ? const TrafficConeMascot(
                                        key: ValueKey('cone'),
                                        size: 300,
                                        autoAnimate: true,
                                      )
                                          : const TrafficMascot(
                                        key: ValueKey('stop'),
                                        state: MascotState.idle,
                                        size: 300,
                                        autoAnimate: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Pregunta + chips
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          current.txt,
                                          softWrap: true,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Chip(
                                              label: Text('Nivel: ${current.lvl}'),
                                              backgroundColor: const Color(0xFFEFF6FF),
                                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                                            ),
                                            Chip(
                                              label: Text('Categoría: ${current.cat}'),
                                              backgroundColor: const Color(0xFFF1F5F9),
                                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Opciones estilizadas ────────────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      itemCount: qc.options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final opcion = qc.options[index];
                        final isSelected = qc.selectedIndex == index;
                        final isCorrect = opcion.correct == true;

                        Color bg;
                        Color border;
                        if (qc.answerShown) {
                          if (isCorrect) {
                            bg = const Color(0xFFE6F4EA); // correcto (verde claro)
                            border = const Color(0xFF34A853);
                          } else if (isSelected) {
                            bg = const Color(0xFFFDE7E9); // seleccionado pero incorrecto
                            border = const Color(0xFFEA4335);
                          } else {
                            bg = Colors.white;
                            border = const Color(0xFFE2E8F0);
                          }
                        } else {
                          bg = isSelected ? const Color(0xFFE3F2FD) : Colors.white; // selección
                          border = isSelected ? const Color(0xFF1E88E5) : const Color(0xFFE2E8F0);
                        }

                        return InkWell(
                          onTap: () => qc.selectOption(index),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? const Color(0xFF1E88E5) : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    opcion.txt,
                                    style: const TextStyle(fontSize: 16, height: 1.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Botón Verificar ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (qc.selectedIndex != null && !qc.answerShown)
                          ? () => _handleVerifyAndAutoAdvance(qc)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Verificar respuesta'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
