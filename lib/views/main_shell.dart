// lib/views/main_shell.dart
import 'package:flutter/material.dart';
import 'package:eduvial/views/menu.dart';
import 'package:eduvial/views/ranking_screen.dart';
import 'package:eduvial/views/laws_screen.dart';

import 'package:eduvial/models/user.dart';
import 'package:eduvial/controllers/auth_controller.dart';
import 'package:eduvial/widgets/welcome_overlay.dart';
import 'package:eduvial/services/guest_helper.dart'; // AuthPromptResult + requireAuthOrAlert

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Tabs visibles desde el primer frame (aunque seas invitado)
  late List<Widget> _tabs;

  // (opcional) Bienvenida
  bool _welcomeShown = false;

  // 0=Home, 1=Ranking, 2=Leyes -> protegidas para invitados
  final Map<int, String> _restricted = const {
    1: 'Ranking',
    2: 'Leyes',
  };

  @override
  void initState() {
    super.initState();

    // 1) Render inmediato con placeholders para que se vea la Bottom Bar
    _tabs = [
      const Menu(key: PageStorageKey('tab_menu')),
      RankingScreen(
        key: const PageStorageKey('tab_ranking'),
        token: '', // invitado
        me: User(name: '', email: '', password: '', role: '', points: 0),
      ),
      const LawsScreen(key: PageStorageKey('tab_laws')),
    ];

    // 2) Cargar sesión sin bloquear UI y reinyectar Ranking con datos reales si los hay
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await auth_controller.loadToken();
    User? me = await auth_controller.loadCachedUser();
    me ??= await auth_controller.refreshMeAndCache();
    if (!mounted) return;

    setState(() {
      _tabs[1] = RankingScreen(
        key: const PageStorageKey('tab_ranking'),
        token: token ?? '',
        me: me ?? User(name: '', email: '', password: '', role: '', points: 0),
      );
    });

    if (!_welcomeShown) {
      _welcomeShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showWelcomeDialog(context);
      });
    }
  }

  void _goLogin() => Navigator.of(context).pushNamed('/login');

  Future<void> _onTap(int newIndex) async {
    if (_restricted.containsKey(newIndex)) {
      final res = await requireAuthOrAlert(
        context,
        featureName: _restricted[newIndex]!,
        onGoLogin: _goLogin,
      );
      if (res != AuthPromptResult.proceed) return; // invitado: pop-up y no navega
    }
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Nada de spinners por token/usuario: siempre mostramos la Bottom Bar
    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey(_index),
        child: _tabs[_index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
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
