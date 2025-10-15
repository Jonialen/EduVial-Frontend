// lib/utils/page_transitions.dart
import 'package:flutter/material.dart';

/// Transición: FADE (entrada/salida suave)
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Transición: SLIDE-UP + FADE (levemente desde abajo)
Route<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, __, child) {
      final offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(animation);
      return SlideTransition(position: offset, child: FadeTransition(opacity: animation, child: child));
    },
  );
}
