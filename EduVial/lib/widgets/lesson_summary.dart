// lib/widgets/lesson_summary.dart
import 'package:flutter/material.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/services/guest_helper.dart';

typedef AsyncVoid = Future<void> Function();

Future<void> showLessonSummaryDialog(
    BuildContext context,
    QuestionController qc, {
      String title = 'Módulo completado',
      String retryLabel = 'Reintentar',
      String exitLabel  = 'Volver al menú',
      AsyncVoid? onRetry,
      AsyncVoid? onExit,
    }) async {
  // 1) Preguntar acceso primero
  final gate = await requireAuthOrAlert(
    context,
    featureName: 'Sumar puntos por lección',
    onGoLogin: () => Navigator.of(context).pushNamed('/login'),
  );

  if (gate == AuthPromptResult.goLogin) {
    // Usuario eligió ir a Login: NO mostramos summary para no bloquear.
    return;
  }

  int? totalNew;
  final wasGuest = gate != AuthPromptResult.proceed; // cancel == invitado
  if (!wasGuest) {
    totalNew = await qc.finishAndSync(); // ya tiene JWT
  }

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Respondiste ${qc.scoreLesson} de ${qc.questions.length} correctamente.'),
          const SizedBox(height: 12),
          Text('Puntos añadidos: ${qc.scoreLessonPoints}'),
          if (!wasGuest && totalNew != null) Text('Total actual: $totalNew'),
          const SizedBox(height: 12),
          Text(
            qc.scoreLesson >= (qc.questions.length / 2) ? 'Buen trabajo' : 'Puedes mejorar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: qc.scoreLesson >= (qc.questions.length / 2) ? Colors.green : Colors.red,
            ),
          ),
          if (!wasGuest && totalNew == null)
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
            await (onRetry ?? qc.restart)();
          },
          child: Text(retryLabel),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            if (onExit != null) {
              await onExit();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Text(exitLabel),
        ),
      ],
    ),
  );
}
