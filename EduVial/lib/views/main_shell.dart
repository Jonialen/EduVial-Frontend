import 'package:flutter/material.dart';
import 'package:eduvial/views/menu.dart';
import 'package:eduvial/views/ranking_screen.dart';
import 'package:eduvial/views/laws_screen.dart';

//Bottom bar

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  //Paginas a las que se puede navegar
  final _pages = const [
    Menu(),
    RankingScreen(),
    LawsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantiene estado de cada tab
      body: IndexedStack(index: _index, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1976D2),
        selectedItemColor: Colors.white,       // activo: blanco
        unselectedItemColor: Colors.white60,   // inactivo: gris/blanco tenue
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),         label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Ranking'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel),        label: 'Leyes'),
        ],
      ),
    );
  }
}
