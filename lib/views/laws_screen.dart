import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eduvial/services/laws_api.dart';

import 'package:eduvial/widgets/mascot/traffic_cone_mascot.dart';

enum _FilterType { text, article, sanc }

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
  List<String> _categories = [];
  List<Map<String, dynamic>> _laws = [];

  _FilterType _filterType = _FilterType.text;

  // Estado vacío: tamaño/animación del cono después del pop-up
  double _emptyMascotSize = 100;
  MascotState _emptyMascotState = MascotState.idle;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedCat = null;
      _emptyMascotSize = 100;           // reset al entrar
      _emptyMascotState = MascotState.idle;
    });
    try {
      final cats = await LawsApi.getCategories();
      final all = await LawsApi.getAll();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _laws = all;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los datos. ($e)';
        _loading = false;
      });
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedCat = null;
      _searchCtrl.clear();
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
    });
    try {
      final res = await LawsApi.getByCategory(cat);
      if (!mounted) return;
      setState(() {
        _laws = res;
        _loading = false;
      });
      if (res.isEmpty) {
        await _showNoMatchesDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar leyes de "$cat". ($e)';
        _loading = false;
      });
    }
  }

  Future<void> _showNoMatchesDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFE3F2FD), // azul claro
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            // ⬇️ Cono ANIMADO en modo sorprendido
            TrafficConeMascot(
              state: MascotState.surprised,
              size: 150,
              autoAnimate: true,
              glow: true,
            ),
            SizedBox(height: 14),
            Text(
              'No se encontraron coincidencias.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Intenta con otro término o revisa la categoría seleccionada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // ⬇️ Al cerrar el pop-up: agranda y deja el cono "feliz"
    if (!mounted) return;
    setState(() {
      _emptyMascotSize = 140;                // un poco más grande que 100
      _emptyMascotState = MascotState.happy; // animación de estrellas
    });
  }

  // Búsqueda / filtros solo al presionar ENTER o botón
  Future<void> _applyFilters() async {
    final q = _searchCtrl.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> res;

      if (q.isEmpty && _selectedCat == null) {
        res = await LawsApi.getAll();
      } else if (q.isEmpty && _selectedCat != null) {
        res = await LawsApi.getByCategory(_selectedCat!);
      } else {
        switch (_filterType) {
          case _FilterType.text:
            res = await LawsApi.filter(search: q);
            break;
          case _FilterType.article:
            res = await LawsApi.filter(article: q);
            break;
          case _FilterType.sanc:
            res = await LawsApi.filter(sanc: q);
            break;
        }
        if (_selectedCat != null) {
          final byCat = await LawsApi.getByCategory(_selectedCat!);
          final catIds = {for (final m in byCat) (m['id'] as num).toInt()};
          res = res.where((m) => catIds.contains((m['id'] as num).toInt())).toList();
        }
      }

      if (!mounted) return;
      setState(() {
        _laws = res;
        _loading = false;
      });

      if (res.isEmpty) {
        await _showNoMatchesDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo aplicar el filtro. ($e)';
        _loading = false;
      });
    }
  }

  // -------- Helpers (tu misma lógica) --------
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

  String _article(Map m) =>
      _getFirst(m, ['articleNumber', 'article', 'articulo', 'numero', 'num', 'n']);

  String _title(Map m) {
    final t = _getFirst(m, ['title', 'titulo', 'name', 'ley,', 'heading']);
    if (t.isNotEmpty) return t;
    final a = _article(m);
    return a.isNotEmpty ? 'Artículo $a' : 'Ley / artículo';
  }

  String _category(Map m) {
    final cats = m['categories'];
    if (cats is List && cats.isNotEmpty) return cats.first.toString();
    return _getFirst(m, ['category', 'categoria', 'type', 'tipo']);
  }

  String _body(Map m) => _getFirst(
      m, ['description', 'descripcion', 'summary', 'text', 'content', 'body', 'detalle']);

  // ----------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    const themeBlue = Color(0xFF1976D2);
    final kbType =
    _filterType == _FilterType.article ? TextInputType.number : TextInputType.text;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leyes de Tránsito',
          style: TextStyle(color: Colors.white), // título blanco
        ),
        backgroundColor: themeBlue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white), // íconos blancos
        actions: [
          IconButton(
            tooltip: 'Recargar todo',
            onPressed: _init,
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
              OutlinedButton(
                onPressed: _init,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _init,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Selector de filtro ---
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<_FilterType>(
                    value: _filterType,
                    decoration: InputDecoration(
                      labelText: 'Tipo de filtro',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _FilterType.text,
                        child: Text('Texto libre (título/descr./sanción)'),
                      ),
                      DropdownMenuItem(
                        value: _FilterType.article,
                        child: Text('Artículo exacto'),
                      ),
                      DropdownMenuItem(
                        value: _FilterType.sanc,
                        child: Text('Sanción contiene...'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _filterType = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _searchCtrl.clear();
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- Caja de búsqueda (solo ENTER o botón) ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    keyboardType: kbType,
                    decoration: InputDecoration(
                      hintText: switch (_filterType) {
                        _FilterType.article => 'Buscar por artículo (p. ej. 145)',
                        _FilterType.sanc => 'Buscar por texto de sanción...',
                        _ => 'Buscar en título, descripción o sanción...',
                      },
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (_) => _applyFilters(), // ENTER
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _applyFilters(), // botón Buscar
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Buscar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Categorías ---
            if (_categories.isNotEmpty)
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
                      onSelected: (val) async {
                        if (!val) return;
                        if (isAll) {
                          setState(() => _selectedCat = null);
                          await _applyFilters();
                        } else {
                          await _filterByCategory(label);
                        }
                      },
                      selectedColor: const Color(0xFFE3F2FD),
                      side: const BorderSide(color: Color(0xFF90CAF9)),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // --- Lista de leyes / estado vacío con cono animado ---
            if (_laws.isEmpty)
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: TrafficConeMascot(
                      state: _emptyMascotState, // idle → happy tras pop-up
                      size: _emptyMascotSize,   // 100 → 140 tras pop-up
                      autoAnimate: true,
                      glow: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('No se encontraron coincidencias.'),
                ],
              ),
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
            }),
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
