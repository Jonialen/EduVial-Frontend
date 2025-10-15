// lib/guards/profile_guard.dart
import 'package:flutter/material.dart';


import 'package:eduvial/services/guest_helper.dart';

class ProfileGuard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onGoLogin; // 👈 agrega el campo

  const ProfileGuard({
    super.key,
    required this.child,
    this.onGoLogin, // 👈 agrégalo también en el constructor
  });

  @override
  State<ProfileGuard> createState() => _ProfileGuardState();
}

class _ProfileGuardState extends State<ProfileGuard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final res = await requireAuthOrAlert(
        context,
        featureName: 'Perfil',
        onGoLogin: widget.onGoLogin ?? () => Navigator.of(context).pushNamed('/login'),
      );

      // Si no procede (invitado/canceló o tocó "Iniciar sesión"), cerramos esta ruta
      if (res != AuthPromptResult.proceed && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
