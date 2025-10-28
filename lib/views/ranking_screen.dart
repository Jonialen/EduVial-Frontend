// lib/views/ranking_screen.dart
import 'package:flutter/material.dart';
import '../services/ranking_service.dart';
import '../models/user.dart';
import '../services/me_ranking.dart';

// Dialog de bienvenida
import 'package:eduvial/widgets/ranking_welcome.dart';

// Gate persistente por usuario (SharedPreferences)
import 'package:eduvial/services/ranking_welcome_gate.dart';

// Auth para rescatar email si fuera necesario
import 'package:eduvial/controllers/auth_controller.dart' as auth;

// Footer del trofeo brillante (SIN mascota)
import 'package:eduvial/widgets/ranking_trophy_footer.dart';

const Color kAccentBlue = Color(0xFF3C8CE7);
const Color kLightBlue = Color(0xFF89CFF0);
const Color kBlueContainer = Color(0xFFD9ECFF);

class RankingScreen extends StatefulWidget {
  final String token;
  final User me;
  const RankingScreen({super.key, required this.token, required this.me});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  // Filtros: Todos, Top 10, Top 3
  static const List<int?> filters = [null, 10, 3];
  static const List<String> labels = ['Todos', 'Top 10', 'Top 3'];
  static const List<IconData?> icons = [
    Icons.all_inclusive,
    Icons.leaderboard,
    Icons.military_tech
  ];

  int? selectedLimit = null;
  late final RankingService service = RankingService(widget.token);
  late Future<_RankingData> futureData;

  @override
  void initState() {
    super.initState();
    futureData = _loadData();

    // Bienvenida SOLO la primera vez por usuario (persistente)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Invitado no usa ranking (por si acaso)
      if (widget.me.role.toLowerCase() == 'invitado') return;

      // Usa email como ID persistente
      String userId = widget.me.email.trim().toLowerCase();

      // Si viene vacío, intenta recuperarlo del backend
      if (userId.isEmpty) {
        try {
          final me = await auth.auth_controller.getMeBasic();
          final u = me['user'];
          if (u is Map && u['email'] is String) {
            userId = (u['email'] as String).trim().toLowerCase();
          }
        } catch (_) {}
      }
      if (userId.isEmpty) userId = 'unknown_user';

      if (!mounted) return;
      final shouldShow = await RankingWelcomeGate.shouldShow(userId);
      if (!shouldShow || !mounted) return;

      await showRankingWelcomeDialog(
        context,
        message:
        'Bienvenido a la pantalla de ranking, aquí podrás ver las puntuaciones de más usuarios a nivel global',
      );

      await RankingWelcomeGate.markSeen(userId);
    });
  }

  Future<_RankingData> _loadData() async {
    final topF = service.fetchTop(limit: selectedLimit);
    final meF = service.fetchMyRanking();
    final top = await topF;
    final me = await meF;
    top.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));
    return _RankingData(top: top, me: me);
  }

  void _onSelectLimit(int? limit) {
    setState(() {
      selectedLimit = limit;
      futureData = _loadData();
    });
  }

  bool _eqName(String a, String b) {
    String n(String s) => s.toLowerCase().trim();
    return n(a) == n(b);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RankingData>(
      future: futureData,
      builder: (context, snap) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ranking'),
            backgroundColor: kAccentBlue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body: _buildBody(context, snap),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<_RankingData> snap) {
    if (snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError) {
      return Center(child: Text('Error: ${snap.error}'));
    }

    final data = snap.data!;
    final allUsers = data.top;

    // Lista visible (solo >0 puntos) según filtro
    final ranked = allUsers.where((u) => (u.points ?? 0) > 0).toList();
    final int listLimit = selectedLimit ?? ranked.length;
    final List<User> visible = ranked.take(listLimit).toList();

    final String myDisplayName = data.me?.name ?? widget.me.name;
    final int myBackendPoints = data.me?.points ?? 0;
    final bool meHasPoints = myBackendPoints > 0;

    // Usa SIEMPRE la posición global del backend
    final int myGlobalPos =
    (data.me?.position ?? 0) > 0 && meHasPoints ? (data.me!.position!) : 0;

    // ===== Layout: lista scrollable + footer fijo con trofeo =====
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => futureData = _loadData());
              await futureData;
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ==== Filtros (izquierda) + Mi posición (derecha) ====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(filters.length, (i) {
                          final value = filters[i];
                          final selected = value == selectedLimit;
                          return ChoiceChip(
                            avatar: Icon(
                              icons[i],
                              size: 18,
                              color: selected ? Colors.white : kAccentBlue,
                            ),
                            label: Text(labels[i]),
                            selected: selected,
                            onSelected: (_) => _onSelectLimit(value),
                            selectedColor: kAccentBlue,
                            backgroundColor: kBlueContainer,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MyPositionPill(
                      position: myGlobalPos,
                      enabled: meHasPoints,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==== Mensaje cuando no tiene puntos ====
                if (!meHasPoints)
                  Card(
                    color: kLightBlue.withOpacity(0.2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.info_outline, color: kAccentBlue),
                      title: Text(
                        'Aún no tienes puntos',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kAccentBlue,
                        ),
                      ),
                      subtitle: Text(
                        'Completa tu primera lección para sumar XP y aparecer en el ranking.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),

                // ==== Lista visible (resalta mi fila) ====
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(sizeFactor: anim, child: child),
                  ),
                  child: visible.isEmpty
                      ? Card(
                    key: const ValueKey('empty'),
                    color: kBlueContainer,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Aún no hay usuarios con puntos.\n¡Sé el primero en sumar XP!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                      : Card(
                    key: const ValueKey('list'),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final u = visible[i];
                        final position = i + 1;
                        final isMe = _eqName(u.name, myDisplayName);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          color: isMe
                              ? kAccentBlue.withOpacity(0.1)
                              : Colors.transparent,
                          child: ListTile(
                            leading: _rankBadge(position),
                            title: Text(
                              u.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isMe
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isMe
                                    ? kAccentBlue
                                    : Colors.black87,
                              ),
                            ),
                            trailing: Text(
                              '${u.points ?? 0} XP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMe
                                    ? kAccentBlue
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ===== Footer fijo: TROFEO BRILLANTE (sin superponerse) =====
        const RankingTrophyFooter(),
        // Si quieres mostrarlo solo si hay usuarios con puntos:
        // if (visible.isNotEmpty) const RankingTrophyFooter(),
      ],
    );
  }

  Widget _rankBadge(int position) {
    if (position == 1) return const Text('🥇', style: TextStyle(fontSize: 20));
    if (position == 2) return const Text('🥈', style: TextStyle(fontSize: 20));
    if (position == 3) return const Text('🥉', style: TextStyle(fontSize: 20));
    if (position <= 0) return const CircleAvatar(radius: 14, child: Text('—'));
    return CircleAvatar(
      radius: 14,
      backgroundColor: kAccentBlue.withOpacity(0.15),
      child: Text(
        '$position',
        style:
        const TextStyle(fontWeight: FontWeight.w700, color: kAccentBlue),
      ),
    );
  }
}

class _MyPositionPill extends StatelessWidget {
  final int position;
  final bool enabled;
  const _MyPositionPill({
    required this.position,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPosition = position > 0;
    final String text = hasPosition ? 'Top $position' : 'Sin puntos';
    final IconData icon =
    hasPosition ? Icons.star_rounded : Icons.circle_outlined;

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? kBlueContainer : Colors.black12,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled ? kAccentBlue : Colors.black26,
          width: 1.5,
        ),
        boxShadow: enabled
            ? [
          BoxShadow(
            color: kAccentBlue.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: hasPosition ? kAccentBlue : Colors.black38,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: enabled ? kAccentBlue : Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingData {
  final List<User> top;
  final MeRanking? me;
  _RankingData({required this.top, required this.me});
}
