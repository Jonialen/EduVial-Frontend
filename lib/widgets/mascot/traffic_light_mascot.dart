import 'package:flutter/material.dart';


enum MascotState { idle, waving, alert, pointing, celebrating }

/// Semáforo animado con viseras (líneas negras) delgadas SOBRE cada foco.
class TrafficLightMascot extends StatefulWidget {
  final MascotState state;
  final double size; // ancho del widget
  final VoidCallback? onTap;
  final bool autoAnimate;

  const TrafficLightMascot({
    super.key,
    this.state = MascotState.idle,
    this.size = 220,
    this.onTap,
    this.autoAnimate = true,
  });

  @override
  State<TrafficLightMascot> createState() => _TrafficLightMascotState();
}

class _TrafficLightMascotState extends State<TrafficLightMascot>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _idleController;   // bounce/tilt
  late final AnimationController _cycleController;  // ciclo luces
  late final AnimationController _blinkController;  // parpadeos / flecha / waving
  late final AnimationController _shakeController;  // alerta

  // Animaciones
  late final Animation<double> _bounce;
  late final Animation<double> _tilt;
  late final Animation<double> _cycle;
  late final Animation<double> _blink;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _idleController  = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _cycleController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

    _bounce = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_idleController);
    _tilt = Tween<double>(begin: -0.02, end: 0.02)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_idleController);
    _cycle = CurvedAnimation(parent: _cycleController, curve: Curves.linear);
    _blink = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_blinkController);
    _shake = Tween<double>(begin: -6, end: 6)
        .chain(CurveTween(curve: Curves.elasticInOut))
        .animate(_shakeController);

    if (widget.autoAnimate) _startForState(widget.state);
  }

  void _startForState(MascotState s) {
    _stopAll();
    switch (s) {
      case MascotState.idle:
        _idleController.repeat(reverse: true);
        _cycleController.repeat();
        break;
      case MascotState.waving:
        _idleController.repeat(reverse: true);
        _blinkController.repeat(reverse: true);
        break;
      case MascotState.alert:
        _blinkController.repeat(reverse: true);
        _shakeController.repeat(reverse: true);
        break;
      case MascotState.pointing:
        _idleController.repeat(reverse: true);
        _blinkController.repeat(reverse: true);
        break;
      case MascotState.celebrating:
        _idleController.repeat(reverse: true);
        _cycleController.repeat();
        _blinkController.repeat(reverse: true);
        break;
    }
  }

  void _stopAll() {
    _idleController.stop();
    _cycleController.stop();
    _blinkController.stop();
    _shakeController.stop();
  }

  @override
  void didUpdateWidget(covariant TrafficLightMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoAnimate && oldWidget.state != widget.state) {
      _startForState(widget.state);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _cycleController.dispose();
    _blinkController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController, _cycleController, _blinkController, _shakeController
        ]),
        builder: (context, _) {
          final double dx = widget.state == MascotState.alert ? _shake.value : 0;
          return Transform.translate(
            offset: Offset(dx, -_bounce.value),
            child: Transform.rotate(
              angle: _tilt.value,
              child: SizedBox(
                width: size,
                height: size * 1.6,
                child: CustomPaint(
                  painter: _TrafficLightPainter(
                    state: widget.state,
                    cycleT: _cycle.value,
                    blinkT: _blink.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrafficLightPainter extends CustomPainter {
  final MascotState state;
  final double cycleT; // 0..1
  final double blinkT; // 0..1

  _TrafficLightPainter({
    required this.state,
    required this.cycleT,
    required this.blinkT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 2;

    final double w = size.width;
    final double h = size.height;

    // --- Sombra ---
    fill.color = Colors.black.withOpacity(0.18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.97), width: w * 0.7, height: h * 0.06),
      fill,
    );

    // --- Poste (NO cruza el foco verde) ---
    fill.color = const Color(0xFF2C2C2C);
    final double postW = w * 0.10;
    final double postH = h * 0.24;
    final double postTop = h * 0.66; // suficientemente abajo para no cruzar el verde
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - postW) / 2, postTop, postW, postH),
        const Radius.circular(8),
      ),
      fill,
    );

    // Base del poste
    fill.color = const Color(0xFF1E1E1E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.88, w * 0.36, h * 0.08),
        const Radius.circular(10),
      ),
      fill,
    );

    // --- Caja del semáforo ---
    final Rect box = Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.6, h * 0.55);
    // cuerpo
    fill.color = const Color(0xFF3A3A3A);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(18)), fill);
    // borde exterior
    stroke
      ..color = Colors.black
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(18)), stroke);

    // --- Luces (con el ESPACIADO ORIGINAL) ---
    final double r = box.width * 0.22;
    final double cx = box.center.dx;
    final double gap = box.height / 4;
    final Offset redC    = Offset(cx, box.top + gap * 0.95);
    final Offset yellowC = Offset(cx, box.top + gap * 2.00);
    final Offset greenC  = Offset(cx, box.top + gap * 3.05);

    // Intensidades según estado
    double redI = 0.15, yellowI = 0.12, greenI = 0.12;
    if (state == MascotState.idle || state == MascotState.celebrating) {
      final double t = (cycleT * 3) % 3;
      redI = t < 1 ? 1.0 : 0.15;
      yellowI = (t >= 1 && t < 2) ? 1.0 : 0.12;
      greenI = t >= 2 ? 1.0 : 0.12;
    } else if (state == MascotState.waving) {
      greenI = 1.0;
    } else if (state == MascotState.alert) {
      yellowI = 0.4 + 0.6 * blinkT;
      redI = 0.18; greenI = 0.18;
    } else if (state == MascotState.pointing) {
      greenI = 0.4 + 0.6 * blinkT;
    }

    _drawLight(canvas, redC, r, Colors.red, redI);
    _drawLight(canvas, yellowC, r, const Color(0xFFFFC107), yellowI);
    _drawLight(canvas, greenC, r, Colors.green, greenI);

    // --- Viseras/lineas negras DELGADAS por encima de cada foco ---
    _drawThinVisor(canvas, redC, r);
    _drawThinVisor(canvas, yellowC, r);
    _drawThinVisor(canvas, greenC, r);

    // --- Carita simple (igual) ---
    _drawFace(canvas, box, state);

    // --- Bracito lateral (igual) ---
    _drawArm(canvas, size, state, blinkT);

    // Flecha verde en pointing (igual)
    if (state == MascotState.pointing) {
      _drawGreenArrow(canvas, greenC, r * 0.9, alpha: blinkT);
    }
  }

  void _drawLight(Canvas canvas, Offset c, double r, Color color, double intensity) {
    // Halo suave (opcional, no es línea)
    final Paint halo = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.0), color.withOpacity(0.28 * intensity)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 1.55));
    canvas.drawCircle(c, r * 1.55, halo);

    // Bombillo (SIN borde negro)
    final Paint bulb = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        colors: [
          Colors.white.withOpacity(0.55 * intensity),
          color.withOpacity(0.9),
          color.withOpacity(1.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bulb);
  }

  /// Dibuja una línea/visera negra delgada SOBRE el foco (no lo atraviesa).
  void _drawThinVisor(Canvas canvas, Offset c, double r) {
    final double visorW = r * 1.7;      // ancho fino
    final double visorH = r * 0.27;     // MUY delgado
    final double visorY = c.dy - r * 0.85; // claramente por encima del centro del círculo

    final RRect visor = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, visorY), width: visorW, height: visorH),
      const Radius.circular(10),
    );
    final Paint p = Paint()..color = Colors.black.withOpacity(0.85);
    canvas.drawRRect(visor, p);
  }

  void _drawFace(Canvas canvas, Rect box, MascotState state) {
    final Paint fill = Paint()..color = Colors.white;
    final Paint stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Offset l = Offset(box.center.dx - box.width * 0.16, box.top + box.height * 0.18);
    final Offset r = Offset(box.center.dx + box.width * 0.16, box.top + box.height * 0.18);
    canvas.drawCircle(l, 4, fill);
    canvas.drawCircle(r, 4, fill);

    final bool happy = state == MascotState.celebrating;
    final bool warn  = state == MascotState.alert;
    final double k = happy ? 1 : (warn ? -1 : 0);
    final Rect mouth = Rect.fromCenter(
      center: Offset(box.center.dx, box.top + box.height * 0.26),
      width: box.width * 0.22,
      height: 10 + 6 * k,
    );
    canvas.drawArc(mouth, 0, 3.14159, false, stroke);
  }

  void _drawArm(Canvas canvas, Size size, MascotState state, double blinkT) {
    final Paint fill = Paint()..color = const Color(0xFF2C2C2C);
    final double w = size.width;
    final double h = size.height;
    final Offset pivot = Offset(w * 0.8, h * 0.34);

    canvas.save();
    double angle = -0.15;
    if (state == MascotState.waving) {
      angle = -0.15 - 0.5 * (0.5 - blinkT);
    } else if (state == MascotState.pointing) {
      angle = -0.7;
    }
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);

    final Rect arm = Rect.fromLTWH(0, -8, w * 0.28, 16);
    canvas.drawRRect(RRect.fromRectAndRadius(arm, const Radius.circular(12)), fill);

    // Mano
    final Paint hand = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.28, 0), 10, hand);

    canvas.restore();
  }

  void _drawGreenArrow(Canvas canvas, Offset center, double size, {required double alpha}) {
    final Path p = Path();
    final double s = size;
    p.moveTo(center.dx - s * 0.55, center.dy);
    p.lineTo(center.dx + s * 0.15, center.dy);
    p.lineTo(center.dx + s * 0.15, center.dy - s * 0.25);
    p.lineTo(center.dx + s * 0.6, center.dy + 0);
    p.lineTo(center.dx + s * 0.15, center.dy + s * 0.25);
    p.lineTo(center.dx + s * 0.15, center.dy);
    p.close();

    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.85 * (0.4 + 0.6 * alpha));
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _TrafficLightPainter old) {
    return old.state != state || old.cycleT != cycleT || old.blinkT != blinkT;
  }
}
