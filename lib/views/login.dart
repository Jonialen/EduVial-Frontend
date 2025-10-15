import 'package:flutter/material.dart';
import 'package:eduvial/views/register.dart';
import 'package:eduvial/controllers/auth_controller.dart';
import 'package:eduvial/utils/page_transitions.dart';
import 'package:eduvial/views/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscure = true; // Solo UI: mostrar/ocultar contraseña

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
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1220) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: isDark
                    ? []
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo + título
                  Image.asset(
                    'assets/images/Logo-refac.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenida a EduVial',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF22313F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'tucorreo@ejemplo.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFF8FAFC),
                      border: _roundedBorder(),
                      enabledBorder: _roundedBorder(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      focusedBorder: _roundedBorder(
                        color: const Color(0xFF1E88E5),
                        width: 1.6,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: '',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F1A2E) : const Color(0xFFF8FAFC),
                      border: _roundedBorder(),
                      enabledBorder: _roundedBorder(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      focusedBorder: _roundedBorder(
                        color: const Color(0xFF1E88E5),
                        width: 1.6,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Forgot password (enlace sutil)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                      ),
                      child: const Text(''),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Botón Login
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Iniciar sesión'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Invitado (secundario)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(fadeRoute(const MainShell()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: isDark ? const Color(0xFF1E88E5) : const Color(0xFF1E88E5)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Ingresar como invitado'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Separador
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '¿No tienes cuenta?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Registro
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: _onRegisterPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Crear cuenta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _roundedBorder({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color ?? Colors.transparent, width: width),
    );
  }
}
