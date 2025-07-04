import 'package:eduvial/views/register.dart';
import 'package:flutter/material.dart';
import 'package:eduvial/controllers/auth_controller.dart';
import 'package:eduvial/views/menu.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _onLoginPressed() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final result = await auth_controller.login(email, password);

    if (result['success']) {
      // Login exitoso

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Inicio de sesión exitoso!')),

      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Menu()));


    } else {
      // Mostrar el error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    }
  }


  void _onRegisterPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // 🎨
        elevation: 4, // Sombra debajo
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centra el contenido verticalmente
            children: [
              // Imagen centrada
              Image.asset(
                'assets/images/Logo-refac.png',
                height: 350, // Ajusta el tamaño de la imagen
                width: 350,
              ),
              const SizedBox(height: 32), // Espacio entre la imagen y los campos de texto
              // Campos de texto para el correo y la contraseña
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
              // Botones debajo de los campos de texto
              ElevatedButton(
                onPressed: _onLoginPressed,
                child: const Text('Iniciar sesión'),
              ),
              ElevatedButton(
                onPressed: _onLoginPressed,
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
