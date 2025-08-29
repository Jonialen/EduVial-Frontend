import 'package:eduvial/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:eduvial/models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedLevel; // "Principiante" | "Avanzado" (texto visible)
  bool cargando = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Mapea el texto visible a los valores que espera el backend/reglas
  String _normalizeRole(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.startsWith('avan')) return 'avanzado';
    return 'principiante';
  }

  Future<void> _onClick() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa nombre, correo y contraseña.")),
      );
      return;
    }

    if (selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona un nivel.")),
      );
      return;
    }

    final role = _normalizeRole(selectedLevel!);

    setState(() => cargando = true);
    try {
      final user = User(
        name: name,
        email: email,
        password: password,
        role: role,            // "avanzado" | "principiante"
        // points: opcional/null; el back los setea después según rol
      );

      final result = await auth_controller.register(user);

      if (result['success'] == true) {
        // En este punto el auth_controller ya:
        // - guardó token (si vino)
        // - seteo puntos (PUT /points/me -> 75/0 según rol)
        // - cacheó el user si fue posible
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              role == 'avanzado'
                  ? "Registro exitoso. Se asignaron 75 puntos."
                  : "Registro exitoso.",
            ),
          ),
        );
        Navigator.pop(context); // vuelve al login o pantalla anterior
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result['error'] ?? 'No especificado'}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de registro: $e")),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBlue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro"),
        backgroundColor: themeBlue,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/Logo-refac.png',
                height: 350,
                width: 350,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => !cargando ? _onClick() : null,
              ),
              const SizedBox(height: 24),

              // Selector de nivel
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => selectedLevel = value),
                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'Principiante',
                    child: Text('Principiante'),
                  ),
                  PopupMenuItem<String>(
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

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: cargando ? null : _onClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeBlue,
                    disabledBackgroundColor: themeBlue.withOpacity(0.5),
                  ),
                  child: cargando
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Registrarme'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
