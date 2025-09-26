import 'package:flutter/material.dart';
import 'package:eduvial/views/register.dart';
import 'package:eduvial/controllers/auth_controller.dart';
import 'package:eduvial/views/menu.dart';
import 'package:eduvial/utils/page_transitions.dart';
import 'package:eduvial/views/main_shell.dart';
import 'package:eduvial/models/user.dart'; // User + helpers locales

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final result = await auth_controller.login(email, password);

    if (result['success'] == true) {

      final name = (result['user']?['name'] as String?) ?? 'Usuario';
      final role = (result['user']?['role'] as String?) ?? 'principiante';



      if (!mounted) return;
      //ScaffoldMessenger.of(context).showSnackBar(
        //const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
      //);

      Navigator.of(context).pushReplacement(
        fadeRoute(const MainShell()),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Error de login')),
      );
    }
  }





  void _onRegisterPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue, elevation: 4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Logo-refac.png', height: 350, width: 350),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onLoginPressed,
                child: const Text('Iniciar sesión'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Menu()),
                  );
                },
                child: const Text('Ingresar como invitado'),
              ),

              TextButton(
                onPressed: _onRegisterPressed,
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
