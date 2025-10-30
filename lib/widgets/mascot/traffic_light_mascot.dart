import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

// Estados legacy + nuevos.
// - celebrating -> happy
// - waving -> idle (se conserva waving por compat, solo mueve brazo)
// - pointing -> pointing (flecha verde)
enum MascotState { idle, waving, alert, pointing, celebrating, surprised, happy, caution }

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
  // Controllers base
  late final AnimationController _idleController;    // bounce/tilt
  late final AnimationController _cycleController;   // ciclo luces (idle/happy)
  late final AnimationController _blinkFaceCtrl;     // parpadeo ojos (cada 4s)

  // Estados nuevos
  late final AnimationController _surprisedCtrl;     // pop + "!!"
  late final AnimationController _happyCtrl;         // estrellas lento
  late final AnimationController _cautionCtrl;       // vaivén + pulso amarillo
  late final AnimationController _shakeCtrl;         // shake (alert legacy)

  // Animaciones base
  late final Animation<double> _bounce;
  late final Animation<double> _tilt;
  late final Animation<double> _cycle;       // 0..1 lineal
  late final Animation<double> _eyeBlink;    // 1 -> 0.08 -> 1
  late final Animation<double> _surprisePop; // 0.98 <-> 1.04
  late final Animation<double> _cautionSway; // -6..6
  late final Animation<double> _cautionPulse;// 0.3..1.0
  late final Animation<double> _shake;       // -6..6

  Timer? _blinkTimer;

  MascotState _normalize(MascotState s) {
    if (s == MascotState.celebrating) return MascotState.happy;
    // waving y pointing se conservan como legado
    return s;
  }

  @override
  void initState() {
    super.initState();

    _idleController   = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _cycleController  = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _blinkFaceCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));

    _surprisedCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _happyCtrl        = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _cautionCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _shakeCtrl        = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

    _bounce = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_idleController);

    _tilt = Tween<double>(begin: -0.02, end: 0.02)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_idleController);

    _cycle = CurvedAnimation(parent: _cycleController, curve: Curves.linear);

    _eyeBlink = Tween<double>(begin: 1.0, end: 0.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_blinkFaceCtrl);

    _surprisePop = Tween<double>(begin: 0.98, end: 1.04)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_surprisedCtrl);

    _cautionSway = Tween<double>(begin: -6, end: 6)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_cautionCtrl);

    _cautionPulse = Tween<double>(begin: 0.3, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_cautionCtrl);

    _shake = Tween<double>(begin: -6, end: 6)
        .chain(CurveTween(curve: Curves.elasticInOut))
        .animate(_shakeCtrl);

    if (widget.autoAnimate) _startForState(_normalize(widget.state));
    _startFixedBlink();
  }

  void _startFixedBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_blinkFaceCtrl.isAnimating) {
        _blinkFaceCtrl.forward().then((_) => _blinkFaceCtrl.reverse());
      }
    });
  }

  void _stopAll() {
    // idle/cycle/face blink siguen cuando corresponde
    _surprisedCtrl.stop();
    _happyCtrl.stop();
    _cautionCtrl.stop();
    _shakeCtrl.stop();
  }

  void _startForState(MascotState sRaw) {
    final s = _normalize(sRaw);
    _stopAll();

    // Siempre activamos idle bounce/tilt en todos excepto alert/shake-only? lo dejamos ON para consistencia
    _idleController.repeat(reverse: true);

    switch (s) {
      case MascotState.idle:
        _cycleController.repeat();
        break;

      case MascotState.happy:
        _cycleController.repeat();
        _happyCtrl.repeat(); // estrellas lento
        break;

      case MascotState.surprised:
        _cycleController.stop();
        _surprisedCtrl
          ..reset()
          ..forward();
        break;

      case MascotState.caution:
        _cycleController.stop();
        _cautionCtrl.repeat(reverse: true);
        break;

      case MascotState.alert: // legacy
        _cycleController.stop();
        _shakeCtrl.repeat(reverse: true);
        break;

      case MascotState.pointing: // legacy: flecha verde parpadeante
        _cycleController.stop();
        break;

      case MascotState.waving: // legacy: brazo saluda
        _cycleController.repeat();
        break;

      case MascotState.celebrating: // mapeado a happy (pero por si acaso)
        _cycleController.repeat();
        _happyCtrl.repeat();
        break;
    }
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
    _blinkTimer?.cancel();
    _idleController.dispose();
    _cycleController.dispose();
    _blinkFaceCtrl.dispose();
    _surprisedCtrl.dispose();
    _happyCtrl.dispose();
    _cautionCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final s = _normalize(widget.state);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController, _cycleController, _blinkFaceCtrl,
          _surprisedCtrl, _happyCtrl, _cautionCtrl, _shakeCtrl
        ]),
        builder: (context, _) {
          double dx = 0;
          if (s == MascotState.caution) dx = _cautionSway.value;
          if (s == MascotState.alert)   dx = _shake.value;

          double scaleX = 1.0, scaleY = 1.0;
          if (s == MascotState.surprised) {
            final pop = _surprisePop.value;
            scaleX = pop; scaleY = pop;
          }

          return Transform.translate(
            offset: Offset(dx, -_bounce.value),
            child: Transform.rotate(
              angle: _tilt.value,
              child: Transform.scale(
                scaleX: scaleX, scaleY: scaleY,
                child: SizedBox(
                  width: size,
                  height: size * 1.6,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Estrellas (happy)
                      if (s == MascotState.happy)
                        CustomPaint(
                          size: Size(size, size * 1.6),
                          painter: _StarsAroundBoxPainter(t: _happyCtrl.value),
                        ),

                      // Exclamaciones (!!) (surprised)
                      if (s == MascotState.surprised)
                        CustomPaint(
                          size: Size(size, size * 1.6),
                          painter: _ExclaimAroundPainter(t: _surprisedCtrl.value),
                        ),

                      // Triángulos de advertencia (caution)
                      if (s == MascotState.caution)
                        CustomPaint(
                          size: Size(size, size * 1.6),
                          painter: _CautionTrianglesPainter(t: _cautionCtrl.value),
                        ),

                      // Cuerpo del semáforo
                      CustomPaint(
                        size: Size(size, size * 1.6),
                        painter: _TrafficLightPainter(
                          state: s,
                          cycleT: _cycle.value,
                          eyeScale: _eyeBlink.value,
                          cautionPulse: (s == MascotState.caution) ? _cautionPulse.value : 0,
                        ),
                      ),
                    ],
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

/// ---------------- Painter principal ----------------
class _TrafficLightPainter extends CustomPainter {
  final MascotState state;
  final double cycleT;     // 0..1 para ciclo de luces
  final double eyeScale;   // 1..0.08..1 parpadeo
  final double cautionPulse; // 0..1 pulso amarillo

  _TrafficLightPainter({
    required this.state,
    required this.cycleT,
    required this.eyeScale,
    required this.cautionPulse,
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

    // --- Poste
    fill.color = const Color(0xFF2C2C2C);
    final double postW = w * 0.10;
    final double postH = h * 0.24;
    final double postTop = h * 0.66;
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
    fill.color = const Color(0xFF3A3A3A);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(18)), fill);
    stroke
      ..color = Colors.black
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(18)), stroke);

    // --- Luces ---
    final double r = box.width * 0.22;
    final double cx = box.center.dx;
    final double gap = box.height / 4;
    final Offset redC    = Offset(cx, box.top + gap * 0.95);
    final Offset yellowC = Offset(cx, box.top + gap * 2.00);
    final Offset greenC  = Offset(cx, box.top + gap * 3.05);

    // Intensidades según estado
    double redI = 0.15, yellowI = 0.12, greenI = 0.12;

    if (state == MascotState.idle || state == MascotState.happy) {
      final double t = (cycleT * 3) % 3;
      redI    = t < 1 ? 1.0 : 0.15;
      yellowI = (t >= 1 && t < 2) ? 1.0 : 0.12;
      greenI  = t >= 2 ? 1.0 : 0.12;
    } else if (state == MascotState.caution) {
      // Amarillo pulsante
      yellowI = 0.3 + 0.7 * cautionPulse;
      redI = 0.12; greenI = 0.12;
    } else if (state == MascotState.alert) {
      // Legacy alert: parpadeo rápido en amarillo
      yellowI = 0.5 + 0.5 * math.sin(cycleT * 2 * math.pi * 3);
      redI = 0.12; greenI = 0.12;
    } else if (state == MascotState.pointing) {
      // Flecha verde a continuación
      greenI = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(cycleT * 2 * math.pi * 2));
    } else if (state == MascotState.waving || state == MascotState.surprised) {
      // Mantén ciclo suave de rojo para contraste
      redI = 0.8; yellowI = 0.12; greenI = 0.12;
    }

    _drawLight(canvas, redC, r, Colors.red, redI);
    _drawLight(canvas, yellowC, r, const Color(0xFFFFC107), yellowI);
    _drawLight(canvas, greenC, r, Colors.green, greenI);

    // Viseras delgadas
    _drawThinVisor(canvas, redC, r);
    _drawThinVisor(canvas, yellowC, r);
    _drawThinVisor(canvas, greenC, r);

    // Carita con parpadeo
    _drawFace(canvas, box, state, eyeScale);

    // Bracito lateral (solo legacy)
    _drawArm(canvas, size, state, cycleT);

    // Flecha verde en pointing
    if (state == MascotState.pointing) {
      _drawGreenArrow(canvas, greenC, r * 0.9, alpha: 0.9);
    }
  }

  void _drawLight(Canvas canvas, Offset c, double r, Color color, double intensity) {
    final Paint halo = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.0), color.withOpacity(0.28 * intensity)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 1.55));
    canvas.drawCircle(c, r * 1.55, halo);

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

  void _drawThinVisor(Canvas canvas, Offset c, double r) {
    final double visorW = r * 1.7;
    final double visorH = r * 0.27;
    final double visorY = c.dy - r * 0.85;

    final RRect visor = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, visorY), width: visorW, height: visorH),
      const Radius.circular(10),
    );
    final Paint p = Paint()..color = Colors.black.withOpacity(0.85);
    canvas.drawRRect(visor, p);
  }

  void _drawFace(Canvas canvas, Rect box, MascotState state, double eyeScale) {
    final Paint fill = Paint()..color = Colors.white;
    final Paint stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Ojos con parpadeo (escala vertical simulada)
    final Offset l = Offset(box.center.dx - box.width * 0.16, box.top + box.height * 0.18);
    final Offset r = Offset(box.center.dx + box.width * 0.16, box.top + box.height * 0.18);
    final double eyeR = 4.0;
    // El "parpadeo" simple: si eyeScale < 0.3, dibuja línea; si no, círculo
    if (eyeScale < 0.3) {
      final Paint p = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(l.dx - eyeR, l.dy), Offset(l.dx + eyeR, l.dy), p);
      canvas.drawLine(Offset(r.dx - eyeR, r.dy), Offset(r.dx + eyeR, r.dy), p);
    } else {
      canvas.drawCircle(l, eyeR, fill);
      canvas.drawCircle(r, eyeR, fill);
    }

    // Boca según estado
    final bool happy = state == MascotState.happy || state == MascotState.celebrating;
    final bool warn  = state == MascotState.alert || state == MascotState.caution;
    final bool surprise = state == MascotState.surprised;

    if (surprise) {
      // Bocota O
      final Paint o = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(box.center.dx, box.top + box.height * 0.26), 6.5, o);
    } else {
      final double k = happy ? 1 : (warn ? -1 : 0.2);
      final Rect mouth = Rect.fromCenter(
        center: Offset(box.center.dx, box.top + box.height * 0.26),
        width: box.width * 0.22,
        height: 10 + 6 * k,
      );
      canvas.drawArc(mouth, 0, 3.14159, false, stroke);
    }
  }

  void _drawArm(Canvas canvas, Size size, MascotState state, double t) {
    // Solo para waving/pointing legacy
    if (state != MascotState.waving && state != MascotState.pointing) return;

    final Paint fill = Paint()..color = const Color(0xFF2C2C2C);
    final double w = size.width;
    final double h = size.height;
    final Offset pivot = Offset(w * 0.8, h * 0.34);

    canvas.save();
    double angle = -0.15;
    if (state == MascotState.waving) {
      angle = -0.15 - 0.35 * math.sin(t * 2 * math.pi * 2);
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
      ..color = Colors.white.withOpacity(0.85 * alpha);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _TrafficLightPainter old) {
    return old.state != state ||
        old.cycleT != cycleT ||
        old.eyeScale != eyeScale ||
        old.cautionPulse != cautionPulse;
  }
}

/// -------- Estrellas (happy) ----------
class _StarsAroundBoxPainter extends CustomPainter {
  final double t; // 0..1
  _StarsAroundBoxPainter({required this.t});

  Path _starPath(double r) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a1 = (i * 72) * math.pi / 180;
      final a2 = a1 + 36 * math.pi / 180;
      final p1 = Offset(r * math.cos(a1), r * math.sin(a1));
      final p2 = Offset((r * 0.45) * math.cos(a2), (r * 0.45) * math.sin(a2));
      if (i == 0) path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      final a3 = a1 + 72 * math.pi / 180;
      final p3 = Offset(r * math.cos(a3), r * math.sin(a3));
      path.lineTo(p3.dx, p3.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final boxCenter = Offset(size.width * 0.5, size.height * 0.38);
    final bigR = size.width * 0.46;

    for (int i = 0; i < 10; i++) {
      final ang = (i / 10) * 2 * math.pi + t * 2 * math.pi * 0.2;
      final x = boxCenter.dx + math.cos(ang) * bigR;
      final y = boxCenter.dy + math.sin(ang) * bigR;
      final opacity = 0.6 + 0.4 * (0.5 + 0.5 * math.sin((t + i / 10) * 2 * math.pi * 0.2));

      final paint = Paint()..color = Colors.yellow.withOpacity(opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(ang);
      canvas.drawPath(_starPath(size.width * 0.04), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StarsAroundBoxPainter old) => old.t != t;
}

/// -------- “!!” (surprised) ----------
class _ExclaimAroundPainter extends CustomPainter {
  final double t;
  _ExclaimAroundPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.26);
    final amp = 6 * math.sin(t * 2 * math.pi);
    final fade = 0.5 + 0.5 * math.sin(t * math.pi);

    final style = TextStyle(
      fontSize: size.width * 0.16,
      fontWeight: FontWeight.w900,
      color: Colors.orangeAccent.withOpacity(fade),
      letterSpacing: 1.5,
      shadows: [
        Shadow(
          color: Colors.orange.withOpacity(fade),
          blurRadius: 8,
          offset: const Offset(1, 1),
        )
      ],
    );

    void drawBang(double dxFactor) {
      final tp = TextPainter(
        text: TextSpan(text: '!!', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = Offset(
        center.dx + dxFactor * size.width * 0.28 - tp.width / 2,
        center.dy - size.width * 0.02 + amp,
      );
      tp.paint(canvas, pos);
    }

    drawBang(-1.0);
    drawBang(1.0);
  }

  @override
  bool shouldRepaint(covariant _ExclaimAroundPainter old) => old.t != t;
}

/// -------- Triángulos advertencia (caution) ----------
class _CautionTrianglesPainter extends CustomPainter {
  final double t;
  _CautionTrianglesPainter({required this.t});

  Path _triangle(double r) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final a = (-math.pi / 2) + i * 2 * math.pi / 3;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.38);
    final baseR = size.width * 0.48;
    final rot = t * 2 * math.pi * 0.35;
    final alpha = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));

    final triPaint = Paint()..color = Colors.amber.withOpacity(alpha);

    for (int i = 0; i < 3; i++) {
      final ang = (i / 3) * 2 * math.pi + rot;
      final x = center.dx + math.cos(ang) * baseR;
      final y = center.dy + math.sin(ang) * baseR;
      final r = size.width * 0.06;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(ang + math.pi / 2);
      canvas.drawPath(_triangle(r), triPaint);

      // signo "!" central
      final tp = TextPainter(
        text: TextSpan(
          text: '!',
          style: TextStyle(
            fontSize: r * 1.2,
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height * 0.55));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CautionTrianglesPainter old) => old.t != t;
}
