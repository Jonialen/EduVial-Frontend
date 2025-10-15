import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eduvial/controllers/auth_controller.dart';
import 'package:eduvial/widgets/mascot/traffic_mascot.dart'; // usa tu mascota

/// Llama a esta función para mostrar la bienvenida.
/// Se auto-cierra en ~2.6 s o cuando se presiona "Empezar".
Future<void> showWelcomeDialog(BuildContext context) async {
  // Evita múltiples diálogos en la misma frame
  if (!context.mounted) return;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Bienvenida',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (ctx, anim, secAnim) {
      return const _WelcomeContent();
    },
    transitionBuilder: (ctx, anim, secAnim, child) {
      return Transform.scale(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        ).value,
        child: Opacity(
          opacity: anim.value,
          child: child,
        ),
      );
    },
  );
}

class _WelcomeContent extends StatefulWidget {
  const _WelcomeContent();

  @override
  State<_WelcomeContent> createState() => _WelcomeContentState();
}

class _WelcomeContentState extends State<_WelcomeContent> with SingleTickerProviderStateMixin {
  String _name = '¡Hola!';
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();

    // Cargar nombre desde el cache del usuario
    _loadName();

    // Animación sutil tipo "bounce" para la mascota
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: -6, end: 6)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ctrl);

    // Autocierre
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  Future<void> _loadName() async {
    final raw = await auth_controller.loadCachedUserJson();
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final n = (map['name'] as String?)?.trim();
        if (mounted && n != null && n.isNotEmpty) {
          setState(() => _name = '¡Hola, $n!');
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeBlue = const Color(0xFF1976D2);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(blurRadius: 24, color: Colors.black26, offset: Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mascota con bounce suave
              AnimatedBuilder(
                animation: _bounce,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _bounce.value),
                  child: child,
                ),
                child: const TrafficMascot(state: MascotState.waving, size: 92),
              ),
              const SizedBox(height: 12),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '¡Listo para aprender y sumar puntos hoy?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              //SizedBox(
                //width: double.infinity,
                //child: ElevatedButton.icon(
                  //style: ElevatedButton.styleFrom(
                    //backgroundColor: themeBlue,
                    //foregroundColor: Colors.white,
                    //minimumSize: const Size.fromHeight(44),
                    //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //),
                  //icon: const Icon(Icons.play_arrow),
                  //label: const Text('Empezar'),
                  //onPressed: () {
                    //if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  //},
                //),
              //),
            ],
          ),
        ),
      ),
    );
  }
}
