import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

/// Estados "legacy" mapean a los nuevos:
/// - celebrating -> happy
/// - waving -> idle
/// - pointing -> idle
/// Estados reales: idle, surprised, happy, caution
enum MascotState { idle, surprised, happy, caution, waving, pointing, celebrating }

class TrafficConeMascot extends StatefulWidget {
  final MascotState state;
  final double size;
  final VoidCallback? onTap;
  final bool autoAnimate;
  final bool glow;

  const TrafficConeMascot({
    super.key,
    this.state = MascotState.idle,
    this.size = 300,
    this.onTap,
    this.autoAnimate = true,
    this.glow = true,
  });

  @override
  State<TrafficConeMascot> createState() => _TrafficConeMascotState();
}

class _TrafficConeMascotState extends State<TrafficConeMascot>
    with TickerProviderStateMixin {
  // Controladores base
  late AnimationController _idleController;
  late AnimationController _eyeController;

  // Estados nuevos
  late AnimationController _happyController;      // estrellas (lento)
  late AnimationController _surprisedController;  // pop + "!!"
  late AnimationController _cautionController;    // pulso franjas + triángulos ⚠

  // Animaciones base
  late Animation<double> _bounce;          // bob idle
  late Animation<double> _tilt;            // micro rotación idle
  late Animation<double> _eyeBlink;        // parpadeo cada 4s
  late Animation<double> _surpriseScale;   // 0.98 ↔ 1.04

  // Caution (precaución)
  late Animation<double> _cautionSway;     // leve vaivén horizontal (±6px)
  late Animation<double> _cautionPulse;    // 0..1 para pulso de franjas

  // Tap feedback
  late AnimationController _tapController;
  late Animation<double> _tapSquash;
  late Animation<double> _tapStretch;

  Timer? _blinkTimer;

  MascotState _normalize(MascotState s) {
    if (s == MascotState.celebrating) return MascotState.happy;
    if (s == MascotState.waving || s == MascotState.pointing) return MascotState.idle;
    return s;
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.autoAnimate) _startFor(_normalize(widget.state));
    _startFixedBlink();
  }

  void _setupAnimations() {
    _idleController      = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _eyeController       = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));

    _happyController     = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _surprisedController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _cautionController   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

    _tapController       = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

    _bounce   = Tween(begin: 0.0, end: 10.0).animate(CurvedAnimation(parent: _idleController, curve: Curves.easeInOut));
    _tilt     = Tween(begin: -0.02, end: 0.02).animate(CurvedAnimation(parent: _idleController, curve: Curves.easeInOut));
    _eyeBlink = Tween(begin: 1.0, end: 0.08).animate(CurvedAnimation(parent: _eyeController, curve: Curves.easeInOut));

    _surpriseScale = Tween(begin: 0.98, end: 1.04).animate(CurvedAnimation(parent: _surprisedController, curve: Curves.easeInOut));

    _cautionSway  = Tween(begin: -6.0, end: 6.0).animate(CurvedAnimation(parent: _cautionController, curve: Curves.easeInOut));
    _cautionPulse = Tween(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _cautionController, curve: Curves.easeInOut));

    _tapSquash  = Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic));
    _tapStretch = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic));
  }

  void _startFixedBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_eyeController.isAnimating) {
        _eyeController.forward().then((_) => _eyeController.reverse());
      }
    });
  }

  void _stopAll() {
    _happyController.stop();
    _surprisedController.stop();
    _cautionController.stop();
    // idle/eye siguen
  }

  void _startFor(MascotState s) {
    final state = _normalize(s);
    _stopAll();
    switch (state) {
      case MascotState.idle:
        break;
      case MascotState.happy:
        _happyController.repeat();            // estrellas lento
        break;
      case MascotState.surprised:
        _surprisedController
          ..reset()
          ..forward();                        // pop + "!!"
        break;
      case MascotState.caution:
        _cautionController.repeat(reverse: true); // sway + pulso franjas + triángulos
        break;
      default:
        break;
    }
  }

  @override
  void didUpdateWidget(covariant TrafficConeMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state && widget.autoAnimate) {
      _startFor(widget.state);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idleController.dispose();
    _eyeController.dispose();
    _happyController.dispose();
    _surprisedController.dispose();
    _cautionController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final realState = _normalize(widget.state);

    return GestureDetector(
      onTap: () {
        _tapController
          ..reset()
          ..forward();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _eyeController,
          _happyController,
          _surprisedController,
          _cautionController,
          _tapController,
        ]),
        builder: (context, _) {
          // cálculos dependientes dentro del builder
          double scaleX = _tapSquash.value;
          double scaleY = _tapStretch.value;
          if (realState == MascotState.surprised) {
            final pop = _surpriseScale.value;
            scaleX *= pop;
            scaleY *= pop;
          }

          double offsetX = 0;
          double offsetY = -_bounce.value;
          if (realState == MascotState.caution) offsetX = _cautionSway.value;

          final angle = _tilt.value;

          return Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scaleX: scaleX,
                scaleY: scaleY,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // estrellas (happy)
                      if (realState == MascotState.happy)
                        CustomPaint(
                          size: Size.square(widget.size),
                          painter: _StarsPainterCone(
                            t: _happyController.value,
                            speedFactor: 0.2,
                            count: 10,
                          ),
                        ),

                      // exclamaciones (!!) (surprised)
                      if (realState == MascotState.surprised)
                        CustomPaint(
                          size: Size.square(widget.size),
                          painter: _ExclaimPainterCone(t: _surprisedController.value),
                        ),

                      // triángulos de precaución (caution) + overlay de franjas
                      if (realState == MascotState.caution)
                        CustomPaint(
                          size: Size.square(widget.size),
                          painter: _CautionPainterCone(
                            t: _cautionController.value,
                            pulse: _cautionPulse.value,
                          ),
                        ),

                      // cono base
                      CustomPaint(
                        size: Size.square(widget.size),
                        painter: _ConePainter(
                          state: realState,
                          eyeScale: _eyeBlink.value,
                          glow: widget.glow,
                          stripePulse: (realState == MascotState.caution) ? _cautionPulse.value : 0,
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

/// -----------------------------
/// Painter principal del CONO
/// -----------------------------
class _ConePainter extends CustomPainter {
  final MascotState state;
  final double eyeScale;
  final bool glow;
  final double stripePulse; // 0..1 para intensificar franjas en 'caution'

  _ConePainter({
    required this.state,
    required this.eyeScale,
    required this.glow,
    required this.stripePulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 2;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Sombra
    paint.color = Colors.black.withOpacity(0.18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.93), width: w * 0.46, height: h * 0.08),
      paint,
    );

    // Glow según estado
    if (glow && (state == MascotState.caution || state == MascotState.happy)) {
      final c = state == MascotState.caution
          ? const Color(0x66FFC107) // ámbar
          : const Color(0x663DDC84); // verde feliz
      canvas.drawCircle(
        Offset(cx, h * 0.48),
        w * 0.42,
        Paint()
          ..shader = RadialGradient(
            colors: [c, c.withOpacity(0.08), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(cx, h * 0.48), radius: w * 0.42)),
      );
    }

    _drawShoes(canvas, size, paint);
    _drawLegs(canvas, size, paint);
    _drawConeBody(canvas, size, paint, stroke);
    _drawArmsQuiet(canvas, size, paint); // brazos QUIETOS
    _drawFace(canvas, size, paint, stroke);

    // Overlay de franjas en CAUTION (pulso)
    if (state == MascotState.caution && stripePulse > 0) {
      final overlay = Paint()..color = Colors.white.withOpacity(0.25 * stripePulse);
      final y1 = h * 0.51, y2 = h * 0.58, sH = h * 0.034;
      final s1 = Rect.fromLTWH(cx - w * 0.20, y1, w * 0.40, sH);
      final s2 = Rect.fromLTWH(cx - w * 0.26, y2, w * 0.52, sH);
      canvas.drawRect(s1, overlay);
      canvas.drawRect(s2, overlay);
    }
  }

  void _drawShoes(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    paint.color = Colors.grey[800]!;
    final r = Radius.circular(w * 0.04);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.88, w * 0.14, h * 0.06), r), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.54, h * 0.88, w * 0.14, h * 0.06), r), paint);
  }

  void _drawLegs(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    paint.color = Colors.black;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.70, w * 0.06, h * 0.16), Radius.circular(w * 0.02)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.58, h * 0.70, w * 0.06, h * 0.16), Radius.circular(w * 0.02)), paint);
  }

  void _drawConeBody(Canvas canvas, Size size, Paint paint, Paint stroke) {
    final w = size.width, h = size.height;
    final cx = w / 2;

    // Base redondeada
    final baseTop = h * 0.68;
    final baseHeight = h * 0.055;
    final baseWidth = w * 0.68;

    paint.color = const Color(0xFFFF7A00);
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, baseTop + baseHeight / 2), width: baseWidth, height: baseHeight),
      Radius.circular(baseHeight / 2),
    );
    canvas.drawRRect(baseRect, paint);
    canvas.drawRRect(baseRect, stroke);

    // Cono delgado con punta redondeada
    final tipY = h * 0.14;
    final tipRadius = w * 0.08;
    final body = Path()
      ..moveTo(cx - w * 0.28, baseTop)
      ..lineTo(cx - tipRadius * 0.7, tipY + tipRadius * 0.7)
      ..quadraticBezierTo(cx, tipY, cx + tipRadius * 0.7, tipY + tipRadius * 0.7)
      ..lineTo(cx + w * 0.28, baseTop)
      ..close();

    paint.color = const Color(0xFFFF7A00);
    canvas.drawPath(body, paint);
    canvas.drawPath(body, Paint()..color = Colors.black.withOpacity(0.04)); // sombra sutil
    canvas.drawPath(body, stroke);

    // Franjas blancas
    paint.color = Colors.white;
    final sH = h * 0.034;
    final y1 = h * 0.51;
    final y2 = h * 0.58;

    final stripe1 = Path()
      ..moveTo(cx - w * 0.20, y1)
      ..lineTo(cx + w * 0.20, y1)
      ..lineTo(cx + w * 0.18, y1 + sH)
      ..lineTo(cx - w * 0.18, y1 + sH)
      ..close();

    final stripe2 = Path()
      ..moveTo(cx - w * 0.26, y2)
      ..lineTo(cx + w * 0.26, y2)
      ..lineTo(cx + w * 0.24, y2 + sH)
      ..lineTo(cx - w * 0.24, y2 + sH)
      ..close();

    canvas.drawPath(stripe1, paint);
    canvas.drawPath(stripe2, paint);
  }

  void _drawArmsQuiet(Canvas canvas, Size size, Paint paint) {
    // Brazos estáticos, sin bastón
    final w = size.width, h = size.height;
    paint.color = Colors.black;

    final anchorY = h * 0.55;

    // Izquierdo
    canvas.save();
    canvas.translate(w * 0.30, anchorY);
    canvas.rotate(-0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.03, -w * 0.10, w * 0.06, w * 0.22),
        Radius.circular(w * 0.03),
      ),
      paint,
    );
    canvas.restore();

    // Derecho
    canvas.save();
    canvas.translate(w * 0.70, anchorY);
    canvas.rotate(0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.03, -w * 0.10, w * 0.06, w * 0.22),
        Radius.circular(w * 0.03),
      ),
      paint,
    );
    canvas.restore();

    // Guantes
    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.32, anchorY + w * 0.07), w * 0.045, paint);
    canvas.drawCircle(Offset(w * 0.68, anchorY + w * 0.07), w * 0.045, paint);
  }

  void _drawFace(Canvas canvas, Size size, Paint paint, Paint stroke) {
    final w = size.width, h = size.height;

    // Cejas
    paint.color = Colors.black;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.37, h * 0.29, w * 0.12, w * 0.02), Radius.circular(w * 0.02)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.51, h * 0.29, w * 0.12, w * 0.02), Radius.circular(w * 0.02)),
      paint,
    );

    // Ojos
    paint.color = Colors.white;
    final eyeR = w * 0.055 * eyeScale;
    canvas.drawCircle(Offset(w * 0.43, h * 0.37), eyeR, paint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.37), eyeR, paint);

    paint.color = Colors.black;
    canvas.drawCircle(Offset(w * 0.43, h * 0.37), eyeR * 0.55, paint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.37), eyeR * 0.55, paint);

    // Boca según estado
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 2;

    if (state == MascotState.surprised) {
      // Boca O
      final oPaint = Paint()..color = Colors.black87;
      canvas.drawCircle(Offset(w * 0.50, h * 0.46), w * 0.06, oPaint);
    } else if (state == MascotState.happy) {
      mouth.strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.47), width: w * 0.18, height: h * 0.11),
        0, math.pi, false, mouth,
      );
    } else {
      // sonrisa leve por defecto
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.47), width: w * 0.14, height: h * 0.09),
        0, math.pi, false, mouth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConePainter old) {
    return old.state != state ||
        old.eyeScale != eyeScale ||
        old.glow != glow ||
        old.stripePulse != stripePulse;
  }
}

/// -------- Estrellas (happy) ----------
class _StarsPainterCone extends CustomPainter {
  final double t; // 0..1
  final int count;
  final double speedFactor;

  _StarsPainterCone({required this.t, required this.count, required this.speedFactor});

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
    final center = Offset(size.width / 2, size.height / 2 - size.width * 0.10);
    final radius = size.width * 0.40;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (t * 2 * math.pi * speedFactor);
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      final opacity = 0.6 + 0.4 * (0.5 + 0.5 * math.sin((t + i / count) * 2 * math.pi * speedFactor));
      final paint = Paint()..color = Colors.yellow.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawPath(_starPath(size.width * 0.045), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainterCone old) =>
      old.t != t || old.count != count || old.speedFactor != speedFactor;
}

/// -------- Exclamaciones (!!) para SORPRENDIDO ----------
class _ExclaimPainterCone extends CustomPainter {
  final double t; // 0..1 (opacidad/vaivén)
  _ExclaimPainterCone({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.width * 0.12);
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
        center.dx + dxFactor * size.width * 0.32 - tp.width / 2,
        center.dy - size.width * 0.46 + amp,
      );
      tp.paint(canvas, pos);
    }

    drawBang(-1.0);
    drawBang(1.0);
  }

  @override
  bool shouldRepaint(covariant _ExclaimPainterCone old) => old.t != t;
}

/// -------- Triángulos de precaución (CAUTION) ----------
class _CautionPainterCone extends CustomPainter {
  final double t;     // 0..1 (para giro/opacidad)
  final double pulse; // 0..1 (para intensidad simultánea)
  _CautionPainterCone({required this.t, required this.pulse});

  Path _triangle(double r) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final a = (-math.pi / 2) + i * 2 * math.pi / 3;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.width * 0.06);
    final baseRadius = size.width * 0.36;
    final rotation = t * 2 * math.pi * 0.35; // giro suave
    final alpha = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)); // fade

    final triPaint = Paint()..color = Colors.amber.withOpacity(alpha);
    final innerPaint = Paint()..color = Colors.black.withOpacity(alpha);

    // 3 triángulos alrededor
    for (int i = 0; i < 3; i++) {
      final ang = (i / 3) * 2 * math.pi + rotation;
      final x = center.dx + math.cos(ang) * baseRadius;
      final y = center.dy + math.sin(ang) * baseRadius;
      final r = size.width * 0.06;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(ang + math.pi / 2);
      canvas.drawPath(_triangle(r), triPaint);

      // signo "!" dentro
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
  bool shouldRepaint(covariant _CautionPainterCone old) =>
      old.t != t || old.pulse != pulse;
}

/// ---------------------------------------------------------------------
///  PROBABILIDADES (mismo archivo, sin extras) — con CAUTION
/// ---------------------------------------------------------------------
class ProbabilisticConeMascot extends StatefulWidget {
  const ProbabilisticConeMascot({
    super.key,
    required this.size,
    this.idleWeight = 0.15,
    this.surprisedWeight = 0.15,
    this.cautionWeight = 0.35,
    this.happyWeight = 0.35,
    this.idleBetween = const Duration(milliseconds: 900),
    this.happyDuration = const Duration(seconds: 2),
    this.surprisedDuration = const Duration(seconds: 2),
    this.cautionDuration = const Duration(seconds: 2),
    this.autoStart = true,
    this.interval = const Duration(seconds: 3),
    this.glow = true,
  });

  final double size;
  final double idleWeight;
  final double surprisedWeight;
  final double cautionWeight;
  final double happyWeight;

  final Duration happyDuration;
  final Duration surprisedDuration;
  final Duration cautionDuration;

  final Duration idleBetween;
  final Duration interval;
  final bool autoStart;
  final bool glow;

  @override
  State<ProbabilisticConeMascot> createState() => _ProbabilisticConeMascotState();
}

class _ProbabilisticConeMascotState extends State<ProbabilisticConeMascot> {
  final _rng = math.Random();
  MascotState _state = MascotState.idle;

  Timer? _ticker;
  Timer? _lock;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lock?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(widget.interval, (_) => _tryFire());
  }

  MascotState _pick() {
    final wI = widget.idleWeight;
    final wS = widget.surprisedWeight;
    final wC = widget.cautionWeight;
    final wH = widget.happyWeight;
    final total = wI + wS + wC + wH;
    if (total <= 0) return MascotState.idle;

    final r = _rng.nextDouble() * total;
    double acc = 0;

    acc += wI;
    if (r < acc) return MascotState.idle;
    acc += wS;
    if (r < acc) return MascotState.surprised;
    acc += wC;
    if (r < acc) return MascotState.caution;
    return MascotState.happy;
  }

  void _tryFire() {
    if (_locked) return;

    final next = _pick();
    if (next == MascotState.idle) {
      setState(() => _state = MascotState.idle);
      return;
    }

    Duration keep;
    switch (next) {
      case MascotState.happy:
        keep = widget.happyDuration;
        break;
      case MascotState.surprised:
        keep = widget.surprisedDuration;
        break;
      case MascotState.caution:
        keep = widget.cautionDuration;
        break;
      default:
        keep = const Duration(seconds: 1);
        break;
    }

    _locked = true;
    setState(() => _state = next);

    _lock?.cancel();
    _lock = Timer(keep, () {
      if (!mounted) return;
      setState(() => _state = MascotState.idle);
      Timer(widget.idleBetween, () {
        _locked = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TrafficConeMascot(
      state: _state,
      size: widget.size,
      autoAnimate: true,
      glow: widget.glow,
    );
  }
}
