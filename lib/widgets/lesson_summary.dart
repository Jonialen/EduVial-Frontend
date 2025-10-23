import 'package:flutter/material.dart';
import 'package:eduvial/controllers/question_controller.dart';

/// Muestra el resumen de la lección al finalizar.
/// - Refleja el nuevo sistema: progreso = ACERTOS / TOTAL (5/10/15)
/// - Mensaje según desempeño
/// - Sincroniza puntos con el backend antes de cerrar
///
/// Uso típico:
/// await showLessonSummaryDialog(
///   context,
///   qc,
///   title: 'Módulo de Señales completado',
///   onExit: () async {
///     if (Navigator.of(context).canPop()) Navigator.of(context).pop();
///   },
/// );
Future<void> showLessonSummaryDialog(
    BuildContext context,
    QuestionController qc, {
      required String title,
      Future<void> Function()? onExit,
    }) async {
  final correctas = qc.scoreLesson;     // aciertos
  final total = qc.total;               // 5 / 10 / 15
  final puntos = qc.scoreLessonPoints;  // aciertos * 5
  final porcentaje = (total == 0) ? 0 : ((correctas / total) * 100).round();

  String mensaje;
  IconData icono;
  Color colorIcono;

  if (porcentaje == 100) {
    mensaje = '¡Excelente! Respondiste correctamente las $total preguntas 🎉';
    icono = Icons.emoji_events;
    colorIcono = Colors.amber;
  } else if (porcentaje >= 70) {
    mensaje = '¡Buen trabajo! Aciertos: $correctas de $total ($porcentaje%) 💪';
    icono = Icons.thumb_up;
    colorIcono = Colors.green;
  } else {
    mensaje =
    'Lección completada.\nAciertos: $correctas de $total ($porcentaje%).\n¡Sigue practicando!';
    icono = Icons.lightbulb;
    colorIcono = Colors.orange;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Icon(icono, color: colorIcono, size: 64),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Puntos obtenidos: $puntos',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // cerrar diálogo
                  // No sincroniza puntos: solo cerrar si quieres depurar
                },
                child: const Text('Cerrar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  // Sincroniza puntos (si el usuario está autenticado)
                  await qc.finishAndSyncGuarded(
                    context,
                    onGoLogin: () => Navigator.of(context).pushNamed('/login'),
                  );

                  if (ctx.mounted) Navigator.of(ctx).pop(); // cerrar diálogo
                  if (onExit != null) await onExit();       // volver a la pantalla anterior
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Finalizar'),
              ),
            ],
          ),
        ],
      );
    },
  );
}
