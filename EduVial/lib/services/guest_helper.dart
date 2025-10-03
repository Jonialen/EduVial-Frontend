import 'package:flutter/material.dart';
import 'package:eduvial/controllers/auth_controller.dart' show auth_controller;

/// true si NO hay JWT
Future<bool> isGuest() async {
  final t = await auth_controller.loadToken();
  return t == null || t.isEmpty;
}


enum AuthPromptResult { proceed, cancel, goLogin }

Future<AuthPromptResult> requireAuthOrAlert(
    BuildContext context, {
      required String featureName,
      VoidCallback? onGoLogin,
    }) async {
  final t = await auth_controller.loadToken();
  final isGuest = t == null || t.isEmpty;
  if (!isGuest) return AuthPromptResult.proceed;

  final res = await showDialog<AuthPromptResult>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Función no disponible para invitados'),
      content: Text('Para usar "$featureName", inicia sesión o crea una cuenta.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(AuthPromptResult.cancel),
          child: const Text('Cerrar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(AuthPromptResult.goLogin);
          },
          child: const Text('Iniciar sesión'),
        ),
      ],
    ),
  );

  if (res == AuthPromptResult.goLogin) {
    (onGoLogin ?? () => Navigator.of(context).pushNamed('/login'))();
    return AuthPromptResult.goLogin;
  }
  return AuthPromptResult.cancel;
}

///  sintáctica: ejecuta [action] solo si pasa el guard.
/// Devuelve true si se ejecutó la acción; false si el usuario canceló o eligió ir a Login.
Future<bool> guardedAction(
    BuildContext context, {
      required String featureName,
      required Future<void> Function() action,
      VoidCallback? onGoLogin,
    }) async {
  final res = await requireAuthOrAlert(
    context,
    featureName: featureName,
    onGoLogin: onGoLogin,
  );

  if (res != AuthPromptResult.proceed) return false; // cancel o goLogin
  await action();
  return true;
}
