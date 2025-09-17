import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Ranking'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(child: Text('Aquí va el ranking de usuarios 🏆')),
    );
  }
}
