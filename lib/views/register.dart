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
  String? selectedLevel;
  bool cargando = false;
  bool _obscure = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
        role: role,
      );

      final result = await auth_controller.register(user);

      if (result['success'] == true) {
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
        Navigator.pop(context); // Regresa al login
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        //  Fondo degradado azul → celeste
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E88E5), // azul intenso
              Color(0xFF42A5F5), // celeste claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/Logo-refac.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Crear cuenta en EduVial',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF22313F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Unite para aprender y ganar puntos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Nombre
                        TextField(
                          controller: nameController,
                          decoration: _inputDecoration(
                            label: 'Nombre completo',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            label: 'Correo electrónico',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        TextField(
                          controller: passwordController,
                          obscureText: _obscure,
                          decoration: _inputDecoration(
                            label: 'Contraseña',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nivel
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) =>
                                setState(() => selectedLevel = value),
                            itemBuilder: (BuildContext context) =>
                            const <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'Principiante',
                                child: Text('Principiante'),
                              ),
                              PopupMenuItem<String>(
                                value: 'Avanzado',
                                child: Text('Avanzado'),
                              ),
                            ],
                            offset: const Offset(0, 50),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedLevel ?? 'Seleccionar nivel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: selectedLevel == null
                                        ? Colors.grey.shade600
                                        : const Color(0xFF22313F),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: Color(0xFF1E88E5)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botón principal
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: cargando ? null : _onClick,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B72C9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            child: cargando
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                                : const Text('Registrarme'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Línea inferior - volver al login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      child: const Text('Iniciar sesión'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: _roundedBorder(),
      enabledBorder: _roundedBorder(color: const Color(0xFFE2E8F0)),
      focusedBorder: _roundedBorder(color: const Color(0xFF1E88E5), width: 1.6),
    );
  }

  OutlineInputBorder _roundedBorder({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color ?? Colors.transparent, width: width),
    );
  }
}
