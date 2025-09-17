import 'package:flutter/material.dart';
import 'views/login.dart';
import 'views/main_shell.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const LoginScreen(),
    routes: {
      '/main': (_) => const MainShell(),  // <- ruta al shell
    },
  ));
}
