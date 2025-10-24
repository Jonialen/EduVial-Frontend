import 'package:flutter/material.dart';
import 'package:eduvial/controllers/question_controller.dart';
import 'package:eduvial/controllers/auth_controller.dart' as auth;

/// Muestra el resumen de lección.
/// - Si hay sesión (JWT válido): permite sumar puntos (finishAndSyncGuarded)
/// - Si NO hay sesión: muestra mensaje de invitado y opciones:
///     - Cerrar → vuelve al menú (usa onExit si lo pasas desde la pantalla)
///     - Iniciar sesión → navega a '/login'
Future<void> showLessonSummaryDialog(
    BuildContext context,
    QuestionController qc, {
      String title = 'Lección completada',
      VoidCallback? onExit, // úsalo para volver al menú
    }) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      bool isGuest = false;
      bool checking = true;
      bool syncing = false;
      String? syncMsg;

      Future<void> _checkAuth() async {
        try {
          final me = await auth.auth_controller.getMeBasic(); // tu método ya usado
          final ok = (me['success'] == true && me['user'] != null);
          isGuest = !ok;
        } catch (_) {
          isGuest = true; // si falla, trátalo como invitado
        } finally {
          checking = false;
        }
      }

      // lanzamos la verificación al construir el diálogo
      return FutureBuilder(
        future: _checkAuth(),
        builder: (context, snapshot) {
          if (checking) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 8),
                  LinearProgressIndicator(minHeight: 4),
                  SizedBox(height: 12),
                  Text('Preparando resumen...'),
                ],
              ),
            );
          }

          // --- VISTA DE INVITADO (sin JWT) ---
          if (isGuest) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Respuestas correctas: ${qc.scoreLesson} / ${qc.total}'),
                  const SizedBox(height: 8),
                  Text(
                    'No puedes sumar puntos porque no has iniciado sesión.\n'
                        'Crea una cuenta o inicia sesión para empezar a ganar puntos.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                // Cerrar: cierra el diálogo y vuelve al menú (onExit)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // cierra el diálogo
                    onExit?.call();              // vuelve al menú (pantalla anterior)
                  },
                  child: const Text('Cerrar'),
                ),
                // Iniciar sesión: cierra el diálogo y navega a /login
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();                 // cierra el diálogo
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    // abre login
                  },
                  child: const Text('Iniciar sesión'),
                ),
              ],
            );
          }

          // --- VISTA DE USUARIO LOGUEADO (con JWT) ---
          Future<void> _sync() async {
            if (syncing) return;
            syncing = true;
            syncMsg = null;
            (context as Element).markNeedsBuild();

            final newTotal = await qc.finishAndSyncGuarded(
              context,
              onGoLogin: () => Navigator.of(context).pushNamed('/login'),
            );

            syncing = false;
            if (newTotal != null) {
              syncMsg = '✅ ¡Puntos sumados! Total actual: $newTotal';
            } else {
              syncMsg = 'ℹ️ No se sumaron puntos.';
            }
            (context as Element).markNeedsBuild();
          }

          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Respuestas correctas: ${qc.scoreLesson} / ${qc.total}'),
                    const SizedBox(height: 8),
                    Text('Puntaje obtenido: ${qc.scoreLessonPoints}'),
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
                actions: [
                  TextButton(
                    onPressed: syncing
                        ? null
                        : () async {
                      await _sync(); // suma puntos bajo sesión
                    },
                    child: const Text('Guardar puntos'),
                  ),
                  ElevatedButton(
                    onPressed: syncing
                        ? null
                        : () {
                      Navigator.of(ctx).pop(); // cierra diálogo
                      onExit?.call();          // vuelve al menú si se lo pasaron
                    },
                    child: const Text('Terminar'),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
