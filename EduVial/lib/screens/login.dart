import 'package:eduvial/screens/register.dart';
import 'package:flutter/material.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _onLoginPressed() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    print("Intentando iniciar sesión con: $email - $password");
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
        backgroundColor: Colors.blue, // 🎨 Aquí cambias el color
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
                'assets/images/logo.png', // Asegúrate de que la ruta sea correcta
                height: 150, // Ajusta el tamaño de la imagen
                width: 150,
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
