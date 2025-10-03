import 'package:flutter/material.dart';
import 'views/login.dart';
import 'views/main_shell.dart';

// 👇 importa el guard y la pantalla de perfil
import 'services/profile_guard.dart';
import 'views/UserProfile.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,

    // Puedes dejar `home:` o usar `initialRoute:`; define SIEMPRE la ruta '/login'
    // home: const LoginScreen(),
    initialRoute: '/login',

    routes: {
      '/login': (_) => const LoginScreen(), // <-- necesaria para el helper
      '/main':  (_) => const MainShell(),   // <-- tu shell con bottom bar
    },

    // 👇 Rutas que necesitan lógica adicional (guards)
    onGenerateRoute: (settings) {
      switch (settings.name) {
        case '/perfil':
          return MaterialPageRoute(
            builder: (_) => ProfileGuard(child: const ProfileScreen()),
          );



        default:
          return null;
      }
    },
  ));
}
