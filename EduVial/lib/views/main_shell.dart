import 'package:flutter/material.dart';
import 'package:eduvial/views/menu.dart';
import 'package:eduvial/views/ranking_screen.dart';
import 'package:eduvial/views/laws_screen.dart';

import 'package:eduvial/models/user.dart';
import 'package:eduvial/controllers/auth_controller.dart';
import 'package:eduvial/widgets/welcome_overlay.dart'; // 👈 overlay de bienvenida

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  String? _token;
  User? _me;

  // 👉 Recordar estado básico/scroll entre tabs
  final PageStorageBucket _bucket = PageStorageBucket();

  // 👉 Mantener instancias para NO perder estado al cambiar de tab
  late final List<Widget> _tabs;

  // Bienvenida
  bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await auth_controller.loadToken();
    User? me = await auth_controller.loadCachedUser();
    me ??= await auth_controller.refreshMeAndCache();

    if (!mounted) return;

    // Pre-instanciar páginas con PageStorageKey para conservar estado de scroll, etc.
    _tabs = [
      const Menu(key: PageStorageKey('tab_menu')),
      RankingScreen(
        key: const PageStorageKey('tab_ranking'),
        token: token ?? '',
        me: me ?? User(name: '', email: '', password: '', role: '', points: 0),
      ),
      const LawsScreen(key: PageStorageKey('tab_laws')),
    ];

    setState(() {
      _token = token;
      _me = me;
    });

    // Mostrar overlay de bienvenida UNA sola vez después del primer frame
    if (!_welcomeShown) {
      _welcomeShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showWelcomeDialog(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null || _me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // 🔹 Fade suave entre tabs + preserva estado porque reusamos instancias en _tabs
      body: PageStorage(
        bucket: _bucket,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          // 👇 Asegura que AnimatedSwitcher detecte cambio de "pantalla" (clave por índice)
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _tabs[_index],
          ),
        ),
      ),

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
