import 'package:flutter/material.dart';

enum MascotState { idle, waving, alert, pointing, celebrating }

class TrafficConeMascot extends StatefulWidget {
  final MascotState state;
  final double size;
  final VoidCallback? onTap;
  final bool autoAnimate;

  const TrafficConeMascot({
    super.key,
    this.state = MascotState.idle,
    this.size = 300,
    this.onTap,
    this.autoAnimate = true,
  });

  @override
  State<TrafficConeMascot> createState() => _TrafficConeMascotState();
}

class _TrafficConeMascotState extends State<TrafficConeMascot>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _waveController;
  late AnimationController _alertController;
  late AnimationController _eyeController;

  late Animation<double> _bounce;
  late Animation<double> _armWave;
  late Animation<double> _alertShake;
  late Animation<double> _eyeBlink;
  late Animation<double> _tilt;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.autoAnimate) _startCurrentAnimation();
  }

  void _setupAnimations() {
    _idleController  = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _waveController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _alertController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _eyeController   = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _bounce   = Tween(begin: 0.0, end: 8.0).animate(CurvedAnimation(parent: _idleController, curve: Curves.easeInOut));
    _armWave  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _waveController, curve: Curves.elasticOut));
    _alertShake = Tween(begin: -5.0, end: 5.0).animate(CurvedAnimation(parent: _alertController, curve: Curves.elasticInOut));
    _eyeBlink = Tween(begin: 1.0, end: 0.1).animate(CurvedAnimation(parent: _eyeController, curve: Curves.easeInOut));
    _tilt     = Tween(begin: -0.02, end: 0.02).animate(CurvedAnimation(parent: _idleController, curve: Curves.easeInOut));
  }

  void _startCurrentAnimation() {
    _stopAll();
    switch (widget.state) {
      case MascotState.idle:
        _idleController.repeat(reverse: true);
        _randomBlink();
        break;
      case MascotState.waving:
        _waveController.repeat(reverse: true);
        _idleController.repeat(reverse: true);
        _randomBlink();
        break;
      case MascotState.alert:
        _alertController.repeat(reverse: true);
        break;
      case MascotState.pointing:
        _idleController.repeat(reverse: true);
        _randomBlink();
        break;
      case MascotState.celebrating:
        _waveController.repeat();
        _idleController.repeat(reverse: true);
        _randomBlink();
        break;
    }
  }

  void _randomBlink() {
    Future.delayed(
      Duration(milliseconds: 1800 + (DateTime.now().millisecond % 2200)),
          () {
        if (!mounted) return;
        if (widget.state == MascotState.alert) return;
        _eyeController.forward().then((_) => _eyeController.reverse().then((_) {
          if (mounted && widget.autoAnimate) _randomBlink();
        }));
      },
    );
  }

  void _stopAll() {
    _idleController.stop();
    _waveController.stop();
    _alertController.stop();
    _eyeController.stop();
  }

  @override
  void didUpdateWidget(covariant TrafficConeMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state && widget.autoAnimate) {
      _startCurrentAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleController, _waveController, _alertController, _eyeController]),
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(widget.state == MascotState.alert ? _alertShake.value : 0, -_bounce.value),
            child: Transform.rotate(
              angle: _tilt.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _ConePainter(
                    state: widget.state,
                    armWave: _armWave.value,
                    eyeScale: _eyeBlink.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _waveController.dispose();
    _alertController.dispose();
    _eyeController.dispose();
    super.dispose();
  }
}

class _ConePainter extends CustomPainter {
  final MascotState state;
  final double armWave;
  final double eyeScale;

  _ConePainter({
    required this.state,
    required this.armWave,
    required this.eyeScale,
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
    final cy = h / 2;

    // Sombra elíptica
    paint.color = Colors.black.withOpacity(0.2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.92), width: w * 0.45, height: h * 0.08),
      paint,
    );

    // Zapatos (más estrechos)
    _drawShoes(canvas, size, paint);

    // Piernas (más delgadas)
    _drawLegs(canvas, size, paint);

    // Cuerpo (cono + franjas + base) - MÁS DELGADO
    _drawConeBody(canvas, size, paint, stroke);

    // Brazos
    _drawArms(canvas, size, paint);

    // Cara
    _drawFace(canvas, size, paint, stroke);
  }

  void _drawShoes(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    paint.color = Colors.grey[800]!;
    final r = Radius.circular(w * 0.04);
    // Izquierdo - más estrechos
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.88, w * 0.14, h * 0.06),
        r,
      ),
      paint,
    );
    // Derecho
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.54, h * 0.88, w * 0.14, h * 0.06),
        r,
      ),
      paint,
    );
  }

  void _drawLegs(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    paint.color = Colors.black;
    // Izquierda - más delgadas
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.68, w * 0.06, h * 0.18),
        Radius.circular(w * 0.02),
      ),
      paint,
    );
    // Derecha
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.68, w * 0.06, h * 0.18),
        Radius.circular(w * 0.02),
      ),
      paint,
    );
  }

  void _drawConeBody(Canvas canvas, Size size, Paint paint, Paint stroke) {
    final w = size.width, h = size.height;
    final cx = w / 2;

    // Base - con extremos redondeados
    final baseTop = h * 0.68;
    final baseHeight = h * 0.055;
    final baseWidth = w * 0.68;

    paint.color = const Color(0xFFFF7A00);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, baseTop + baseHeight / 2),
          width: baseWidth,
          height: baseHeight,
        ),
        Radius.circular(baseHeight / 2), // Esto redondea los extremos
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, baseTop + baseHeight / 2),
          width: baseWidth,
          height: baseHeight,
        ),
        Radius.circular(baseHeight / 2),
      ),
      stroke,
    );


    // Cono MUCHO MÁS DELGADO con punta redondeada
    final tipY = h * 0.14;
    final tipRadius = w * 0.08; // Radio para la punta redondeada

    // Crear path con punta redondeada
    final body = Path()
      ..moveTo(cx - w * 0.28, baseTop) // Más estrecho (antes 0.36)
    // Línea izquierda hasta cerca de la punta
      ..lineTo(cx - tipRadius * 0.7, tipY + tipRadius * 0.7)
    // Arco redondeado en la punta
      ..quadraticBezierTo(cx, tipY, cx + tipRadius * 0.7, tipY + tipRadius * 0.7)
    // Línea derecha
      ..lineTo(cx + w * 0.28, baseTop)
      ..close();

    paint.color = const Color(0xFFFF7A00);
    canvas.drawPath(body, paint);
    // Sombreado sutil
    canvas.drawPath(body, Paint()..color = Colors.black.withOpacity(0.04));

    // Franjas blancas - más estrechas
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

    // Contorno del cono
    canvas.drawPath(body, stroke);
  }

  void _drawArms(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    final anchorY = h * 0.55;

    // Brazo izquierdo (saludo) - más corto y pegado
    final leftRot = state == MascotState.waving ? (-0.45 - armWave * 0.8) : -0.35;
    canvas.save();
    canvas.translate(w * 0.30, anchorY);
    canvas.rotate(leftRot);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.03, -w * 0.10, w * 0.06, w * 0.22),
        Radius.circular(w * 0.03),
      ),
      paint,
    );
    canvas.restore();

    // Brazo derecho (apunta/alerta) - más corto y pegado
    final rightRot = state == MascotState.pointing ? -0.9 : 0.35;
    canvas.save();
    canvas.translate(w * 0.70, anchorY);
    canvas.rotate(rightRot);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.03, -w * 0.10, w * 0.06, w * 0.22),
        Radius.circular(w * 0.03),
      ),
      paint,
    );
    canvas.restore();

    // Guantes - más pequeños
    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.32, anchorY + w * 0.07), w * 0.045, paint);
    canvas.drawCircle(Offset(w * 0.68, anchorY + w * 0.07), w * 0.045, paint);

    // Bastón si pointing/alert
    if (state == MascotState.pointing || state == MascotState.alert) {
      final stick = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.brown;
      canvas.drawLine(
        Offset(w * 0.70, anchorY + w * 0.09),
        Offset(w * 0.85, h * 0.38),
        stick,
      );
    }
  }

  void _drawFace(Canvas canvas, Size size, Paint paint, Paint stroke) {
    final w = size.width, h = size.height;

    // Cejas
    paint.color = Colors.black;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.37, h * 0.29, w * 0.12, w * 0.02),
        Radius.circular(w * 0.02),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.51, h * 0.29, w * 0.12, w * 0.02),
        Radius.circular(w * 0.02),
      ),
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

    // Boca
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 2;
    if (state == MascotState.celebrating) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.47), width: w * 0.12, height: h * 0.08),
        0, 3.14, false, mouth,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.46), width: w * 0.12, height: h * 0.08),
        0, 3.14, false, mouth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConePainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.armWave != armWave ||
        oldDelegate.eyeScale != eyeScale;
  }
}