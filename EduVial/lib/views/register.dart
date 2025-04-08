import 'package:eduvial/views/login.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _onClick() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    print("Registro exitoso ");

    Navigator.pop(
      context,
        MaterialPageRoute(builder: (context) => LoginScreen())
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("Registro"),
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
                height: 350, // Ajusta el tamaño de la imagen
                width: 350,
              ),
              const SizedBox(height: 32), // Espacio entre la imagen y los campos de texto
              // Campos de texto para el correo y la contraseña
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electronico ',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña ',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Botones debajo de los campos de texto
              ElevatedButton(
                onPressed: _onClick,
                child: const Text('Registrarme'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
