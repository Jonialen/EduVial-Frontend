import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  CircleAvatar(
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Nombre:',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text(
                      'Juan Pérez',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(),

                  // Username
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Username:',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text(
                      'juan_perez123',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(),

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
                    subtitle: const Text(
                      'juan.perez@example.com',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const Divider(),

                  // Agregar más campos si es necesario
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

