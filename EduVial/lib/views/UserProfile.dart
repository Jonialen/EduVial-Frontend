import 'package:flutter/material.dart';
import 'package:eduvial/models/user.dart'; // <-- User, currentUser, loadUserLocal

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    if (currentUser == null) {
      await loadUserLocal(); // levanta de SharedPreferences si no está en memoria
    }
    if (mounted) setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    //final nombre = currentUser?.name ?? '—';
    final correo = currentUser?.email ?? '—';
    // Si quieres mostrar el rol:
    // final rol = currentUser?.role ?? '—';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Barra azul arriba con la flecha para regresar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              color: const Color(0xFF1976D2),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flecha para regresar
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);  // Vuelve a la pantalla anterior
                    },
                  ),
                  const SizedBox(height: 10),
                  // Título
                  const Text(
                    'Perfil de Usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Datos personales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Icono grande en la parte superior
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nombre de usuario
                 /* ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Nombre:',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      nombre,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(),*/

                  // Correo electrónico
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Correo:',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      correo,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(),

                  // (Opcional) Rol
                  // ListTile(
                  //   contentPadding: EdgeInsets.zero,
                  //   title: const Text(
                  //     'Rol:',
                  //     style: TextStyle(
                  //       color: Color(0xFF1976D2),
                  //       fontWeight: FontWeight.bold,
                  //       fontSize: 18,
                  //     ),
                  //   ),
                  //   subtitle: Text(
                  //     rol,
                  //     style: const TextStyle(fontSize: 16),
                  //   ),
                  // ),
                  // const Divider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
