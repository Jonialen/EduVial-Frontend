import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

/// Compat retro: mantenemos los antiguos (waving, pointing, celebrating)
/// pero las animaciones reales son: idle, alert, surprised, happy.
/// - celebrating -> happy
/// - waving -> idle
/// - pointing -> idle
enum MascotState { idle, alert, surprised, happy, waving, pointing, celebrating }

class TrafficMascot extends StatefulWidget {
  final MascotState state;
  final double size;
  final VoidCallback? onTap;
  final bool autoAnimate;
  final bool glow;

  const TrafficMascot({
    super.key,
    this.state = MascotState.idle,
    this.size = 200,
    this.onTap,
    this.autoAnimate = true,
    this.glow = true,
  });

  @override
  _TrafficMascotState createState() => _TrafficMascotState();
}

class _TrafficMascotState extends State<TrafficMascot>
    with TickerProviderStateMixin {
  // Controladores base
  late AnimationController _idleController;
  late AnimationController _alertController;
  late AnimationController _eyeController;

  // Estados nuevos
  late AnimationController _happyController;     // giro de estrellas (lento)
  late AnimationController _surprisedController; // pop + "!!"

  // Animaciones base
  late Animation<double> _bounceAnimation;      // bob idle
  late Animation<double> _rotationAnimation;    // micro rotación idle
  late Animation<double> _eyeBlinkAnimation;    // parpadeo cada 4s
  late Animation<double> _alertShakeAnimation;  // shake ±8 px

  // Surprise: pequeño "pop" de escala
  late Animation<double> _surpriseScaleIn;      // 0.90 ↔ 1.15

  // Tap squash/stretch (feedback al tocar)
  late AnimationController _tapController;
  late Animation<double> _tapSquash;
  late Animation<double> _tapStretch;

  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    if (widget.autoAnimate) _startFor(_normalize(widget.state));
    _startFixedBlink(); // parpadeo cada 4 s
  }

  // Normaliza estados legacy a los 4 reales
  MascotState _normalize(MascotState s) {
    if (s == MascotState.celebrating) return MascotState.happy;
    if (s == MascotState.waving || s == MascotState.pointing) return MascotState.idle;
    return s; // idle, alert, surprised, happy
  }

  void _setupControllers() {
    _idleController       = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);
    _alertController      = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _eyeController        = AnimationController(duration: const Duration(milliseconds: 180), vsync: this);
    _happyController      = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _surprisedController  = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _tapController        = AnimationController(duration: const Duration(milliseconds: 220), vsync: this);

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    _eyeBlinkAnimation = Tween<double>(begin: 1, end: 0.08).animate(
      CurvedAnimation(parent: _eyeController, curve: Curves.easeInOut),
    );
    _alertShakeAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.elasticInOut),
    );

    // Surprise pop (escala MÁS notoria y con rebote)
    _surpriseScaleIn = Tween<double>(begin: 0.85, end: 1.20).animate(
      CurvedAnimation(parent: _surprisedController, curve: Curves.elasticOut),
    );

    _tapSquash = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );
    _tapStretch = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );
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
    _alertController.stop();
    _happyController.stop();
    _surprisedController.stop();
    // _idleController queda corriendo para bob/rot base
    // _eyeController lo maneja el timer
  }

  void _startFor(MascotState s) {
    final state = _normalize(s);
    _stopAll();
    switch (state) {
      case MascotState.idle:
        break;
      case MascotState.alert:
        _alertController.repeat(reverse: true);     // sacudida continua
        break;
      case MascotState.happy:
        _happyController.repeat();                  // estrellas lento
        break;
      case MascotState.surprised:
        _surprisedController
          ..reset()
          ..forward().then((_) {
            // DEBUG: Imprime cuando termina
            debugPrint(' Surprised animation completed');
          });
        debugPrint(' Starting SURPRISED animation');
        break;
      default:
        break;
    }
  }

  @override
  void didUpdateWidget(TrafficMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state && widget.autoAnimate) {
      _startFor(widget.state);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _idleController.dispose();
    _alertController.dispose();
    _eyeController.dispose();
    _happyController.dispose();
    _surprisedController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  // ✅ MÉTODO PÚBLICO PARA FORZAR SURPRISED (útil para debug)
  void forceSurprised() {
    debugPrint(' Forcing surprised animation manually');
    _startFor(MascotState.surprised);
  }

  @override
  Widget build(BuildContext context) {
    final realState = _normalize(widget.state);

    // DEBUG
    debugPrint(' Building with state: $realState (original: ${widget.state})');

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
          _alertController,
          _eyeController,
          _happyController,
          _surprisedController,
          _tapController,
        ]),
        builder: (context, _) {
          //  Cálculos que dependen de animaciones DENTRO del builder
          double scaleX = _tapSquash.value;
          double scaleY = _tapStretch.value;

          if (realState == MascotState.surprised) {
            final pop = _surpriseScaleIn.value;
            scaleX *= pop;
            scaleY *= pop;
          }

          double offsetX = 0;
          double offsetY = -_bounceAnimation.value;
          if (realState == MascotState.alert) {
            offsetX = _alertShakeAnimation.value;              // sacudida
          }

          final angle = _rotationAnimation.value;

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
                      // Estrellitas (feliz) — giro más lento
                      if (realState == MascotState.happy)
                        CustomPaint(
                          size: Size.square(widget.size),
                          painter: _StarsPainter(
                            t: _happyController.value,
                            speedFactor: 0.2, // DESPACIO
                            count: 12,
                          ),
                        ),

                      // Signos de exclamación (!!) en SORPRENDIDO
                      if (realState == MascotState.surprised) ...[
                        // DEBUG: Fondo amarillo para ver el área
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.yellow, width: 3),
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: Size.square(widget.size),
                          painter: _ExclaimPainter(t: _surprisedController.value),
                        ),
                      ],

                      // Mascota
                      CustomPaint(
                        size: Size.square(widget.size),
                        painter: MascotPainter(
                          eyeScale: _eyeBlinkAnimation.value,
                          mascotState: realState,
                          glow: widget.glow,
                        ),
                      ),

                      // Sirena en alerta (brazo NO se mueve)
                      if (realState == MascotState.alert)
                        Positioned(
                          top: widget.size * 0.08,
                          child: _SirenLight(
                            size: widget.size * 0.18,
                            t: _alertController.value,
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
/// Painter principal (sin bastón, brazos quietos)
/// -----------------------------
class MascotPainter extends CustomPainter {
  final double eyeScale;
  final MascotState mascotState;
  final bool glow;

  MascotPainter({
    required this.eyeScale,
    required this.mascotState,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Sombra
    paint.color = Colors.black.withOpacity(0.15);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, size.height * 0.9), width: size.width * 0.6, height: size.height * 0.1),
      paint,
    );

    _drawShoes(canvas, size, paint);
    _drawLegs(canvas, size, paint);

    // Glow sutil según estado
    if (glow && (mascotState == MascotState.alert || mascotState == MascotState.happy)) {
      final c = mascotState == MascotState.alert
          ? const Color(0x66EF5350) // rojizo
          : const Color(0x663DDC84); // verdoso feliz
      canvas.drawCircle(
        center,
        radius * 1.6,
        Paint()
          ..shader = RadialGradient(colors: [c, c.withOpacity(0.08), Colors.transparent])
              .createShader(Rect.fromCircle(center: center, radius: radius * 1.6)),
      );
    }

    // Cuerpo (señal)
    paint.shader = null;
    paint.color = Colors.red;
    canvas.drawCircle(center, radius, paint);

    // Aro blanco
    strokePaint
      ..strokeWidth = 4
      ..color = Colors.white;
    canvas.drawCircle(center, radius, strokePaint);

    // Franja diagonal blanca
    strokePaint
      ..strokeWidth = radius * 0.28
      ..color = Colors.white;
    canvas.drawLine(
      Offset(center.dx - radius * 0.6, center.dy - radius * 0.6),
      Offset(center.dx + radius * 0.6, center.dy + radius * 0.6),
      strokePaint,
    );

    // Borde negro
    strokePaint
      ..strokeWidth = 3
      ..color = Colors.black
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, strokePaint);

    // Brazos QUIETOS (sin bastón)
    _drawArms(canvas, size, paint, center);

    // Gorra
    _drawCap(canvas, size, paint, center);

    // Cara (boca según estado)
    _drawFace(canvas, size, paint, strokePaint, center, radius);
  }

  void _drawShoes(Canvas c, Size s, Paint p) {
    p.color = Colors.grey[800]!;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.25, s.height * 0.85, s.width * 0.18, s.height * 0.1), const Radius.circular(10)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.57, s.height * 0.85, s.width * 0.18, s.height * 0.1), const Radius.circular(10)), p);
    p.color = Colors.orange;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.25, s.height * 0.9, s.width * 0.18, s.height * 0.05), const Radius.circular(8)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.57, s.height * 0.9, s.width * 0.18, s.height * 0.05), const Radius.circular(8)), p);
  }

  void _drawLegs(Canvas c, Size s, Paint p) {
    p.color = Colors.black;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.3, s.height * 0.65, s.width * 0.08, s.height * 0.25), const Radius.circular(5)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * 0.62, s.height * 0.65, s.width * 0.08, s.height * 0.25), const Radius.circular(5)), p);
  }

  void _drawArms(Canvas canvas, Size size, Paint paint, Offset center) {
    // Ambos brazos en posición fija
    paint.color = Colors.black;

    // Izquierdo
    canvas.save();
    canvas.translate(center.dx - size.width * 0.25, center.dy);
    canvas.rotate(-0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.04, -size.width * 0.15, size.width * 0.08, size.width * 0.3),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.restore();

    // Derecho
    canvas.save();
    canvas.translate(center.dx + size.width * 0.25, center.dy);
    canvas.rotate(0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.04, -size.width * 0.15, size.width * 0.08, size.width * 0.3),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.restore();

    // Guantes blancos
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx - size.width * 0.25, center.dy + size.width * 0.15), size.width * 0.06, paint);
    canvas.drawCircle(Offset(center.dx + size.width * 0.25, center.dy + size.width * 0.15), size.width * 0.06, paint);
  }

  void _drawCap(Canvas canvas, Size size, Paint paint, Offset center) {
    paint.color = const Color(0xFF2E5984);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy - size.width * 0.25), width: size.width * 0.5, height: size.width * 0.3),
      math.pi, math.pi, false, paint,
    );
    paint.color = const Color(0xFF1E3A52);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy - size.width * 0.15), width: size.width * 0.6, height: size.width * 0.15),
      math.pi * 0.8, math.pi * 0.4, false, paint,
    );
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx, center.dy - size.width * 0.25), size.width * 0.04, paint);
  }

  void _drawFace(Canvas canvas, Size size, Paint paint, Paint stroke, Offset center, double radius) {
    // Cejas
    paint.color = Colors.black;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - radius * 0.4, center.dy - radius * 0.3, radius * 0.25, radius * 0.1), const Radius.circular(5)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(center.dx + radius * 0.15, center.dy - radius * 0.3, radius * 0.25, radius * 0.1), const Radius.circular(5)), paint);

    // Ojos
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.1), radius * 0.15 * eyeScale, paint);
    canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy - radius * 0.1), radius * 0.15 * eyeScale, paint);

    // Pupilas
    paint.color = Colors.black;
    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.1), radius * 0.08 * eyeScale, paint);
    canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy - radius * 0.1), radius * 0.08 * eyeScale, paint);

    // Boca según estado
    stroke
      ..style = PaintingStyle.stroke
      ..color = Colors.black;
    if (mascotState == MascotState.surprised) {
      // Boca "O" (sorprendido)
      final oPaint = Paint()..color = Colors.black87;
      canvas.drawCircle(Offset(center.dx, center.dy + radius * 0.18), radius * 0.12, oPaint);
    } else if (mascotState == MascotState.happy) {
      // Sonrisa grande
      stroke.strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, center.dy + radius * 0.2), width: radius * 0.6, height: radius * 0.5),
        0, math.pi, false, stroke,
      );
    } else if (mascotState == MascotState.alert) {
      // Boca recta/preocupada
      stroke.strokeWidth = 2.5;
      canvas.drawLine(
        Offset(center.dx - radius * 0.18, center.dy + radius * 0.15),
        Offset(center.dx + radius * 0.18, center.dy + radius * 0.15),
        stroke,
      );
    } else {
      // Sonrisa leve
      stroke.strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, center.dy + radius * 0.15), width: radius * 0.3, height: radius * 0.2),
        0, math.pi, false, stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MascotPainter old) {
    return old.eyeScale != eyeScale ||
        old.mascotState != mascotState ||
        old.glow != glow;
  }
}

/// -------- Sirena (alert) ----------
class _SirenLight extends StatelessWidget {
  final double size;
  final double t; // 0..1
  const _SirenLight({required this.size, required this.t});
  @override
  Widget build(BuildContext context) {
    final opacity = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(opacity),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: Colors.red.shade900, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(opacity), blurRadius: 16, spreadRadius: 4),
        ],
      ),
    );
  }
}

/// -------- Estrellas (happy) ----------
class _StarsPainter extends CustomPainter {
  final double t; // 0..1
  final int count;
  final double speedFactor; // 0.2 (lento)

  _StarsPainter({required this.t, required this.count, required this.speedFactor});

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
    final center = Offset(size.width / 2, size.height / 2 - size.width * 0.08);
    final radius = size.width * 0.35;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (t * 2 * math.pi * speedFactor);
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      final opacity = 0.6 + 0.4 * (0.5 + 0.5 * math.sin((t + i / count) * 2 * math.pi * speedFactor));
      final paint = Paint()..color = Colors.yellow.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawPath(_starPath(size.width * 0.04), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) =>
      old.t != t || old.count != count || old.speedFactor != speedFactor;
}

/// -------- Exclamaciones (!!) para SORPRENDIDO ----------
class _ExclaimPainter extends CustomPainter {
  final double t; // 0..1 (para opacidad y leve oscilación)
  _ExclaimPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.width * 0.1);

    // DEBUG: Fondo semi-transparente para ver que se dibuja
    final debugPaint = Paint()..color = Colors.purple.withOpacity(0.3);
    canvas.drawCircle(center, size.width * 0.25, debugPaint);

    // Oscilación vertical MUY pronunciada
    final amp = 20 * math.sin(t * 3 * math.pi);

    // Fade que se mantiene visible casi todo el tiempo
    final fade = t < 0.8 ? 1.0 : (1.0 - (t - 0.8) / 0.2);

    final style = TextStyle(
      fontSize: size.width * 0.20, // Más grande
      fontWeight: FontWeight.w900,
      color: Colors.deepOrange.withOpacity(fade.clamp(0.0, 1.0)),
      letterSpacing: 2.0,
      shadows: [
        Shadow(
          color: Colors.orangeAccent.withOpacity(fade.clamp(0.0, 1.0)),
          blurRadius: 12,
          offset: const Offset(2, 2),
        ),
        Shadow(
          color: Colors.yellow.withOpacity(fade.clamp(0.0, 1.0) * 0.5),
          blurRadius: 20,
          offset: const Offset(0, 0),
        )
      ],
    );

    void drawBang(double dxFactor) {
      final tp = TextPainter(
        text: TextSpan(text: '!!', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = Offset(
        center.dx + dxFactor * size.width * 0.35 - tp.width / 2,
        center.dy - size.width * 0.50 + amp,
      );
      tp.paint(canvas, pos);
    }

    drawBang(-1.0);
    drawBang(1.0);
  }

  @override
  bool shouldRepaint(covariant _ExclaimPainter old) => old.t != t;
}

/// ---------------------------------------------------------------------
///  PROBABILIDADES INTEGRADAS EN EL MISMO ARCHIVO (sin crear otro file)
/// ---------------------------------------------------------------------
/// Controla la TrafficMascot con probabilidades por estado.
/// - Usa pesos (porcentajes) por animación.
/// - Evita solapes (lock) y vuelve a idle entre animaciones.
/// - Puedes iniciar/detener el ciclo (expuesto con GlobalKey si quieres).
class ProbabilisticMascot extends StatefulWidget {
  const ProbabilisticMascot({
    super.key,
    required this.size,
    this.idleWeight = 0.10,       // 10% (reducido)
    this.surprisedWeight = 0.10,  // 40% ⬆️ AUMENTADO
    this.alertWeight = 0.50,      // 25%
    this.happyWeight = 0.30,      // 25%
    this.idleBetween = const Duration(milliseconds: 900),
    this.happyDuration = const Duration(seconds: 2),
    this.surprisedDuration = const Duration(seconds: 3), // ⬆️ más tiempo
    this.alertDuration = const Duration(seconds: 2),
    this.autoStart = true,
    this.interval = const Duration(seconds: 3), // cada cuánto intento disparar algo
    this.glow = true,
  });

  /// Tamaño de la mascota
  final double size;

  /// Pesos/probabilidades (no tienen que sumar 1; se normalizan)
  final double idleWeight;
  final double surprisedWeight;
  final double alertWeight;
  final double happyWeight;

  /// Duración visible de cada animación antes de volver a idle
  final Duration happyDuration;
  final Duration surprisedDuration;
  final Duration alertDuration;

  /// Pausa breve en idle entre animaciones
  final Duration idleBetween;

  /// Intentos periódicos (si hay lock, se salta)
  final Duration interval;

  /// Arranca automáticamente
  final bool autoStart;

  /// Efecto glow del painter
  final bool glow;

  @override
  State<ProbabilisticMascot> createState() => _ProbabilisticMascotState();
}

class _ProbabilisticMascotState extends State<ProbabilisticMascot> {
  final _rng = math.Random();
  MascotState _state = MascotState.idle;

  Timer? _ticker;      // intenta disparar según interval
  Timer? _lockTimer;   // mantiene la animación activa
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lockTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(widget.interval, (_) => _tryFire());
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  MascotState _pickByWeights() {
    final wIdle = widget.idleWeight;
    final wSurp = widget.surprisedWeight;
    final wAlert = widget.alertWeight;
    final wHappy = widget.happyWeight;

    final total = wIdle + wSurp + wAlert + wHappy;
    if (total <= 0) return MascotState.idle;

    final r = _rng.nextDouble() * total;
    double acc = 0;

    acc += wIdle;
    if (r < acc) return MascotState.idle;
    acc += wSurp;
    if (r < acc) return MascotState.surprised;
    acc += wAlert;
    if (r < acc) return MascotState.alert;
    return MascotState.happy;
  }

  void _tryFire() {
    if (_locked) return;

    final next = _pickByWeights();

    // DEBUG: Imprime qué estado se seleccionó
    debugPrint('Picked state: $next (locked: $_locked)');

    // Si salió idle, simplemente setea idle sin lock (respira)
    if (next == MascotState.idle) {
      setState(() => _state = MascotState.idle);
      return;
    }

    // Dispara una animación con lock y duración
    Duration keep;
    switch (next) {
      case MascotState.happy:
        keep = widget.happyDuration;
        debugPrint(' Starting HAPPY for ${keep.inSeconds}s');
        break;
      case MascotState.surprised:
        keep = widget.surprisedDuration;
        debugPrint(' Starting SURPRISED for ${keep.inSeconds}s');
        break;
      case MascotState.alert:
        keep = widget.alertDuration;
        debugPrint(' Starting ALERT for ${keep.inSeconds}s');
        break;
      default:
        keep = const Duration(seconds: 1);
        break;
    }

    _locked = true;
    setState(() => _state = next);

    // Mantén animación 'keep', luego vuelve a idle y deja descansar 'idleBetween'
    _lockTimer?.cancel();
    _lockTimer = Timer(keep, () {
      if (!mounted) return;
      debugPrint(' Animation finished, returning to idle');
      setState(() => _state = MascotState.idle);
      Timer(widget.idleBetween, () {
        if (!mounted) return;
        _locked = false;
        debugPrint(' Lock released, ready for next animation');
      });
    });
  }

  /// Métodos públicos opcionales (si usas GlobalKey):
  void startCycle() => _start();
  void stopCycle() => _stop();
  MascotState get current => _state;

  @override
  Widget build(BuildContext context) {
    return TrafficMascot(
      state: _state,
      size: widget.size,
      autoAnimate: true,
      glow: widget.glow,
    );
  }
}

/// ---------------------------------------------------------------------
///  WIDGET DE PRUEBA PARA DEBUG
/// ---------------------------------------------------------------------
class MascotDebugTester extends StatefulWidget {
  const MascotDebugTester({super.key});

  @override
  State<MascotDebugTester> createState() => _MascotDebugTesterState();
}

class _MascotDebugTesterState extends State<MascotDebugTester> {
  MascotState _currentState = MascotState.idle;
  final _mascotKey = GlobalKey<_TrafficMascotState>();
  bool _useProbabilistic = false;
  final _probKey = GlobalKey<_ProbabilisticMascotState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mascot Debug Tester'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Selector de modo
            SwitchListTile(
              title: const Text('Usar ProbabilisticMascot'),
              value: _useProbabilistic,
              onChanged: (val) => setState(() => _useProbabilistic = val),
            ),
            const SizedBox(height: 20),

            // Mascota
            if (_useProbabilistic)
              ProbabilisticMascot(
                key: _probKey,
                size: 250,
                surprisedWeight: 0.50,
                // 50% de probabilidad!
                alertWeight: 0.25,
                happyWeight: 0.25,
                idleWeight: 0.0,
                // Sin idle
                surprisedDuration: const Duration(seconds: 4),
              )
            else
              TrafficMascot(
                key: _mascotKey,
                state: _currentState,
                size: 250,
                autoAnimate: true,
                glow: true,
              ),

            const SizedBox(height: 40),
            Text(
              'Estado: $_currentState',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (!_useProbabilistic) ...[
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _currentState = MascotState.idle),
                    child: const Text('Idle'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _currentState = MascotState.surprised);
                      debugPrint('🔴 Button pressed: SURPRISED');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('SURPRISED'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _currentState = MascotState.alert),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: const Text('Alert'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _currentState = MascotState.happy),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: const Text('Happy'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _mascotKey.currentState?.forceSurprised();
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Force Surprised (Direct)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                ),
              ),
            ] else
              ...[
                Text(
                  'Modo probabilístico activo\n50% surprised, 25% alert, 25% happy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Observa la consola para ver qué estado se selecciona',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
          ],
        ),
      ),
    );
  }
}