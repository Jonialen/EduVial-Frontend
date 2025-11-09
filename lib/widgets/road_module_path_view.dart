import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ModuleStatus { locked, available, completed }

/// Estilo visual por nodo (anillo y degradado)
class RoadModuleStyle {
  final Color ring;
  final List<Color> gradient; // [start, end]
  final Color iconColor;

  const RoadModuleStyle({
    required this.ring,
    required this.gradient,
    this.iconColor = Colors.white,
  });
}

class RoadModuleNode {
  final String id;
  final String title;
  final IconData icon;
  final ModuleStatus status;
  final VoidCallback? onTap;

  /// Estilo específico por nodo (colores originales)
  final RoadModuleStyle? style;

  const RoadModuleNode({
    required this.id,
    required this.title,
    required this.icon,
    required this.status,
    this.onTap,
    this.style,
  });
}

class _NodeCoin extends StatelessWidget {
  final RoadModuleNode node;
  final double size;
  const _NodeCoin({required this.node, this.size = 76, Key? key}) : super(key: key);

  // Defaults azules solo si NO hay style
  static const _blueDark = Color(0xFF1565C0);
  static const _blueMid  = Color(0xFF1976D2);
  static const _blueLt   = Color(0xFF64B5F6);

  Color _ringColor() {
    if (node.status == ModuleStatus.locked && node.style == null) return Colors.grey;
    if (node.style != null) return node.style!.ring;
    return _blueDark;
  }

  List<Color> _gradientColors() {
    if (node.style != null) return node.style!.gradient;
    return const [_blueMid, _blueLt];
  }

  Color _iconColor() {
    if (node.style != null) return node.style!.iconColor;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _ringColor();
    final gradientColors = _gradientColors();
    final iconColor = _iconColor();

    // ✅ Importante: permitimos tap AUNQUE esté locked,
    // para que el caller pueda mostrar una alerta.
    return GestureDetector(
      onTap: node.onTap,
      child: SizedBox(
        width: size,
        child: Column(
          children: [
            Stack(
              children: [
                // Moneda
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: ringColor, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        color: Color(0x33000000),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(node.icon, color: iconColor, size: size * .42),
                  ),
                ),
                // Badge de estado (visual sigue mostrando candado si está locked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: ringColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        node.status == ModuleStatus.completed
                            ? Icons.check_circle
                            : node.status == ModuleStatus.available
                            ? Icons.play_arrow_rounded
                            : Icons.lock_rounded,
                        size: node.status == ModuleStatus.locked ? 18 : 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Nombre en UNA sola línea, con más ancho que la moneda
            SizedBox(
              width: size + 40,
              child: Text(
                node.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final int count;
  final double spacing;
  final double topPad, bottomPad;
  final double leftX, rightX;

  _RoadPainter({
    required this.count,
    required this.spacing,
    required this.topPad,
    required this.bottomPad,
    required this.leftX,
    required this.rightX,
  });

  Path _buildCenter(List<Offset> c) {
    final p = Path()..moveTo(c.first.dx, c.first.dy);
    for (int i = 1; i < c.length; i++) {
      final p0 = c[i - 1], p1 = c[i];
      final midX = (p0.dx + p1.dx) / 2;
      final c1 = Offset(midX, p0.dy + spacing * .35);
      final c2 = Offset(midX, p1.dy - spacing * .35);
      p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
    }
    return p;
  }

  Path _dash(Path src, {double dash = 22, double gap = 18}) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final double n = (d + dash).clamp(0.0, m.length).toDouble();
        out.addPath(m.extractPath(d, n), Offset.zero);
        d = n + gap;
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 1) return;

    final centers = List<Offset>.generate(count, (i) {
      final x = i.isEven ? leftX : rightX;
      final y = topPad + i * spacing;
      return Offset(x, y);
    });

    final center = _buildCenter(centers);

    // Sombra
    final sh = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 42
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(center, sh);

    // Asfalto
    final road = Paint()
      ..color = const Color(0xFF2F2F33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(center, road);

    // Brillo sutil
    final gloss = Paint()
      ..color = Colors.white.withOpacity(.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(center, gloss);

    // Línea central amarilla punteada
    final line = Paint()
      ..color = const Color(0xFFF6C12A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_dash(center), line);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) =>
      old.count != count ||
          old.spacing != spacing ||
          old.leftX != leftX ||
          old.rightX != rightX;
}

class RoadModulePathView extends StatelessWidget {
  final List<RoadModuleNode> nodes;
  final double spacing;
  final double nodeSize;

  const RoadModulePathView({
    super.key,
    required this.nodes,
    this.spacing = 140,
    this.nodeSize = 76,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = 60.0, bottomPad = 120.0;
    final totalH =
        topPad + bottomPad + math.max(0, nodes.length - 1) * spacing;
    final r = nodeSize / 2;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final leftX = w * .25;
        final rightX = w * .75;

        return SingleChildScrollView(
          child: SizedBox(
            height: totalH,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoadPainter(
                      count: nodes.length,
                      spacing: spacing,
                      topPad: topPad,
                      bottomPad: bottomPad,
                      leftX: leftX,
                      rightX: rightX,
                    ),
                  ),
                ),
                ...List.generate(nodes.length, (i) {
                  final x = (i.isEven ? leftX : rightX) - r;
                  final y = topPad + i * spacing - r;
                  return Positioned(
                    left: x,
                    top: y,
                    child: _NodeCoin(node: nodes[i], size: nodeSize),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
