import 'package:eduvial/controllers/auth_controller.dart';
import 'package:eduvial/views/login.dart';
import 'package:flutter/material.dart';
import 'package:eduvial/models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final nameController= TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedLevel; //

  void _onClick() async {
    final name = emailController.text.trim();
    final email = passwordController.text.trim();
    final password = passwordController.text.trim();

    if (selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor selecciona un nivel")),
      );
      return;
    }

    final user = User(
      name: name,
      email: email,
      password: password,
      role: selectedLevel!, // Aseguramos que no es null
    );

    final result = await auth_controller.register(user);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registro exitoso")),
      );

      Navigator.pop(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${result['error']}")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro"),
        backgroundColor: Colors.blue,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 350,
                width: 350,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              /// 🔽 Selector de nivel
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    selectedLevel = value;
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Principiante',
                    child: Text('Principiante'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Avanzado',
                    child: Text('Avanzado'),
                  ),
                ],
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedLevel ?? 'Seleccionar nivel',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

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

