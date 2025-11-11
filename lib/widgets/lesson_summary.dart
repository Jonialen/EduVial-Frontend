// lib/widgets/lesson_summary.dart
import 'package:flutter/material.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/controllers/auth_controller.dart' as auth;

Future<void> showLessonSummaryDialog(
    BuildContext context,
    QuestionController qc, {
      String title = 'Lección completada',
      String retryLabel = 'Reintentar',
      Future<void> Function()? onRetry,
      Future<void> Function()? onExit, // ← para volver al menú
    }) async {
  // --- Métricas de la lección ---
  final correctas = qc.scoreLesson;
  final total = qc.total;
  final puntos = qc.scoreLessonPoints;
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
    mensaje = 'Lección completada.\nAciertos: $correctas de $total ($porcentaje%).\n¡Sigue practicando!';
    icono = Icons.lightbulb;
    colorIcono = Colors.orange;
  }

  // --- Chequeo de sesión ---
  bool isGuest = true;
  try {
    final me = await auth.auth_controller.getMeBasic();
    isGuest = !(me['success'] == true && me['user'] != null);
  } catch (_) {
    isGuest = true;
  }
  if (!context.mounted) return;

  // --- Flags anti-doble tap ---
  bool syncing = false;
  bool synced = false;
  String? syncMsg;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> finalizar() async {
            if (syncing || synced) return;

            // 🟡 Invitado: no guarda, muestra mensaje con opciones
            if (isGuest) {
              showDialog(
                context: ctx,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Modo invitado'),
                  content: const Text(
                    'No puedes sumar puntos porque ingresaste como invitado.\n'
                        'Inicia sesión o crea una cuenta para comenzar a ganar puntos.',
                    textAlign: TextAlign.center,
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // cierra este diálogo
                        Navigator.of(context).pop(); // cierra el resumen
                        if (onExit != null) onExit();
                      },
                      child: const Text('Cerrar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); // cierra el mensaje
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                      },
                      child: const Text('Iniciar sesión'),
                    ),
                  ],
                ),
              );
              return;
            }

            // 🟢 Usuario con sesión: sincroniza y va al menú
            syncing = true;
            setState(() {});

            final newTotal = await qc.finishAndSyncGuarded(
              ctx,
              onGoLogin: () => Navigator.of(ctx).pushNamed('/login'),
            );

            syncing = false;
            synced = true;
            syncMsg = (newTotal != null)
                ? '✅ ¡Puntos sumados! Total actual: $newTotal'
                : 'ℹ️ No se sumaron puntos.';
            setState(() {});

            await Future.delayed(const Duration(milliseconds: 150));
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (onExit != null) await onExit();
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Icon(icono, color: colorIcono, size: 64),
                const SizedBox(height: 16),
                Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
                const SizedBox(height: 16),
                Text('Puntos obtenidos: $puntos',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                if (syncing) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 4),
                ],
                if (syncMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(syncMsg!, textAlign: TextAlign.center),
                ],
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              TextButton(
                onPressed: syncing
                    ? null
                    : () async {
                  Navigator.of(ctx).pop();
                  if (onRetry != null) {
                    await onRetry();
                  } else {
                    await qc.restart();
                  }
                },
                child: Text(retryLabel),
              ),
              ElevatedButton(
                onPressed: syncing ? null : finalizar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Finalizar'),
              ),
            ],
          );
        },
      );
    },
  );
}
