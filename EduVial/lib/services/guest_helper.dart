import 'package:flutter/material.dart';
import 'package:eduvial/controllers/auth_controller.dart' show auth_controller;

/// true si NO hay JWT
Future<bool> isGuest() async {
  final t = await auth_controller.loadToken();
  return t == null || t.isEmpty;
}

/// Muestra alerta si es invitado. Devuelve true si puede continuar.
Future<bool> requireAuthOrAlert(
    BuildContext context, {
      required String featureName,
      VoidCallback? onGoLogin,
    }) async {
  if (await isGuest()) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Función no disponible para invitados'),
        content: Text('Para usar "$featureName", inicia sesión o crea una cuenta.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onGoLogin?.call();
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
    return false;
  }
  return true;
}

/// Azúcar sintáctica: ejecuta [action] solo si pasa el guard. (devuelve true si se ejecutó)
Future<bool> guardedAction(
    BuildContext context, {
      required String featureName,
      required Future<void> Function() action,
      VoidCallback? onGoLogin,
    }) async {
  final ok = await requireAuthOrAlert(context, featureName: featureName, onGoLogin: onGoLogin);
  if (!ok) return false;
  await action();
  return true;
}
