import 'package:flutter/material.dart';
import 'package:eduvial/views/menu.dart';
import 'package:eduvial/views/ranking_screen.dart';
import 'package:eduvial/views/laws_screen.dart';

import 'package:eduvial/models/user.dart';
import 'package:eduvial/controllers/auth_controller.dart'; // <- usa auth_controller

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  String? _token;
  User? _me;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await auth_controller.loadToken();
    User? me = await auth_controller.loadCachedUser();
    me ??= await auth_controller.refreshMeAndCache();

    setState(() {
      _token = token;
      _me = me;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mientras carga token/usuario
    if (_token == null || _me == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ¡OJO! Ya no es const porque RankingScreen recibe parámetros dinámicos
    final pages = [
      const Menu(),
      RankingScreen(token: _token!, me: _me!),
      const LawsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1976D2),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
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
