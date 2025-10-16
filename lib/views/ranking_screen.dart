import 'package:flutter/material.dart';
import '../services/ranking_service.dart';
import '../models/user.dart';
import '../services/me_ranking.dart';
import 'package:eduvial/widgets/ranking_welcome.dart'; // ⬅️ Importa el overlay

class RankingScreen extends StatefulWidget {
  final String token;
  final User me;
  const RankingScreen({super.key, required this.token, required this.me});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  static const List<int?> filters = [null, 15, 10, 5, 1];
  static const List<String> labels = ['Todos', 'Top 15', 'Top 10', 'Top 5', 'Top 1'];

  int? selectedLimit = null;
  late final RankingService service = RankingService(widget.token);
  late Future<_RankingData> futureData;

  @override
  void initState() {
    super.initState();
    futureData = _loadData();

    // ⬇️ Mostrar overlay de bienvenida al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showRankingWelcomeDialog(
        context,
        message:
        'Bienvenido a la pantalla de ranking, aquí podrás ver las puntuaciones de más usuarios a nivel global',
      );
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

  void _reload() {
    setState(() => futureData = _loadData());
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
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: FutureBuilder<_RankingData>(
        future: futureData,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data!;
          final users = data.top;

          final listLimit = selectedLimit ?? users.length;

          final String myDisplayName = data.me?.name ?? widget.me.name;
          final int myBackendPos = data.me?.position ?? 0;
          final int myBackendPoints = data.me?.points ?? 0;

          final bool shouldBeInTop = (myBackendPos > 0) && (myBackendPos <= listLimit);
          final int myIndexInList = users.indexWhere((u) => _eqName(u.name, myDisplayName));
          final bool appearsInList = myIndexInList != -1;

          final String mySubtitle = shouldBeInTop && appearsInList
              ? 'Estás en este Top'
              : (shouldBeInTop && !appearsInList)
              ? 'Deberías aparecer en este Top'
              : 'No apareces en este Top';

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(
                  spacing: 8,
                  children: List.generate(filters.length, (i) {
                    final value = filters[i];
                    return ChoiceChip(
                      label: Text(labels[i]),
                      selected: value == selectedLimit,
                      onSelected: (_) => _onSelectLimit(value),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.green.withOpacity(0.08),
                  child: ListTile(
                    leading: _rankBadge(myBackendPos),
                    title: Text(myDisplayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(mySubtitle),
                    trailing: Text('$myBackendPoints XP',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final position = i + 1;
                      final isMe = _eqName(u.name, myDisplayName);
                      return Container(
                        color: isMe ? Colors.lightGreen.withOpacity(0.15) : null,
                        child: ListTile(
                          leading: _rankBadge(position),
                          title: Text(u.name, overflow: TextOverflow.ellipsis),
                          subtitle: isMe ? const Text('Eres tú') : null,
                          trailing: Text('${u.points ?? 0} XP',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rankBadge(int position) {
    if (position == 1) return const Text('🥇', style: TextStyle(fontSize: 20));
    if (position == 2) return const Text('🥈', style: TextStyle(fontSize: 20));
    if (position == 3) return const Text('🥉', style: TextStyle(fontSize: 20));
    if (position <= 0) return const CircleAvatar(radius: 14, child: Text('—'));
    return CircleAvatar(
      radius: 14,
      child: Text('$position', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _RankingData {
  final List<User> top;
  final MeRanking? me;
  _RankingData({required this.top, required this.me});
}
