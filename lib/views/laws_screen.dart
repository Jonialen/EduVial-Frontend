import 'package:flutter/material.dart';
import 'package:eduvial/services/laws_api.dart';

class LawsScreen extends StatefulWidget {
  const LawsScreen({super.key});

  @override
  State<LawsScreen> createState() => _LawsScreenState();
}

class _LawsScreenState extends State<LawsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  String? _selectedCat;
  List<Map<String, dynamic>> _laws = [];

  // Solo una categoría disponible
  final List<String> _categories = const [
    'Normas generales',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedCat = null;
    });

    try {
      final data = await LawsApi.getAll();
      if (!mounted) return;
      setState(() {
        _laws = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las leyes. ($e)';
        _loading = false;
      });
    }
  }

  Future<void> _filterByCategory(String cat) async {
    setState(() {
      _selectedCat = cat;
      _loading = true;
      _error = null;
      _searchCtrl.clear();
    });

    try {
      final res = await LawsApi.getByCategory(cat);
      if (!mounted) return;
      setState(() {
        _laws = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar leyes de "$cat". ($e)';
        _loading = false;
      });
    }
  }

  Future<void> _filterByArticle() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      if (_selectedCat != null) {
        return _filterByCategory(_selectedCat!);
      }
      return _loadAll();
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await LawsApi.filterByArticle(q);
      if (!mounted) return;
      setState(() {
        _laws = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo buscar el artículo $q. ($e)';
        _loading = false;
      });
    }
  }

  // -------- Helpers --------
  String _getFirst(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      final lo = m[k.toLowerCase()];
      if (lo != null && lo.toString().trim().isNotEmpty) return lo.toString().trim();
      final up = m[k.toUpperCase()];
      if (up != null && up.toString().trim().isNotEmpty) return up.toString().trim();
    }
    return '';
  }

  String _article(Map m) => _getFirst(m, ['article', 'articulo', 'numero', 'num', 'n']);
  String _title(Map m) {
    final t = _getFirst(m, ['title', 'titulo', 'name', 'ley', 'heading']);
    if (t.isNotEmpty) return t;
    final a = _article(m);
    return a.isNotEmpty ? 'Artículo $a' : 'Ley / artículo';
  }
  String _category(Map m) => _getFirst(m, ['category', 'categoria', 'type', 'tipo']);
  String _body(Map m) =>
      _getFirst(m, ['description', 'descripcion', 'summary', 'text', 'content', 'body', 'detalle']);

  // ----------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leyes de Tránsito'),
        backgroundColor: themeBlue,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Recargar todo',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadAll, child: const Text('Reintentar')),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Buscador por artículo ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Buscar por artículo (p. ej. 145)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (_) => _filterByArticle(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _filterByArticle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Buscar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Categorías ---
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1, // + "Todas"
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isAll = i == 0;
                  final label = isAll ? 'Todas' : _categories[i - 1];
                  final selected =
                  isAll ? _selectedCat == null : _selectedCat == label;

                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (val) {
                      if (!val) return;
                      if (isAll) {
                        _loadAll();
                      } else {
                        _filterByCategory(label);
                      }
                    },
                    selectedColor: const Color(0xFFE3F2FD),
                    side: const BorderSide(color: Color(0xFF90CAF9)),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // --- Lista de leyes ---
            ..._laws.map((law) {
              final art = _article(law);
              final tit = _title(law);
              final cat = _category(law);
              final txt = _body(law);

              return _LawExpandableCard(
                title: tit,
                article: art,
                category: cat,
                text: txt.isNotEmpty ? txt : '(sin resumen)',
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

// -------- Tarjeta expandible --------
class _LawExpandableCard extends StatefulWidget {
  final String title;
  final String article;
  final String category;
  final String text;

  const _LawExpandableCard({
    required this.title,
    required this.article,
    required this.category,
    required this.text,
  });

  @override
  State<_LawExpandableCard> createState() => _LawExpandableCardState();
}

class _LawExpandableCardState extends State<_LawExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.article.isNotEmpty)
                  Chip(
                    label: Text('Art. ${widget.article}'),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    visualDensity: VisualDensity.compact,
                  ),
                if (widget.category.isNotEmpty)
                  Chip(
                    label: Text(widget.category),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Text(
                widget.text.length > 280
                    ? '${widget.text.substring(0, 280)}…'
                    : widget.text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.35),
              ),
              secondChild: Text(
                widget.text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.35),
              ),
            ),
            if (widget.text.length > 280)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Ver menos ▲' : 'Ver más ▼'),
              ),
          ],
        ),
      ),
    );
  }
}
