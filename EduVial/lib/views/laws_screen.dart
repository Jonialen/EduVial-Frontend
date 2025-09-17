import 'package:flutter/material.dart';

class LawsScreen extends StatelessWidget {
  const LawsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leyes'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(child: Text('Aquí va el contenido de leyes ⚖️')),
    );
  }
}
