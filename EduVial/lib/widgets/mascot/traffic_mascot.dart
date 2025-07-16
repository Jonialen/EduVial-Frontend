import 'package:flutter/material.dart';

enum MascotState { idle, waving, alert, pointing, celebrating }

class TrafficMascot extends StatefulWidget {
  final MascotState state;
  final double size;
  final VoidCallback? onTap;
  final bool autoAnimate;

  const TrafficMascot({
    Key? key,
    this.state = MascotState.idle,
    this.size = 200,
    this.onTap,
    this.autoAnimate = true,
  }) : super(key: key);

  @override
  _TrafficMascotState createState() => _TrafficMascotState();
}

class _TrafficMascotState extends State<TrafficMascot>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _waveController;
  late AnimationController _alertController;
  late AnimationController _eyeController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _armWaveAnimation;
  late Animation<double> _alertShakeAnimation;
  late Animation<double> _eyeBlinkAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.autoAnimate) {
      _startCurrentAnimation();
    }
  }

  void _setupAnimations() {
    // Animación de respiración/idle
    _idleController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    // Animación de saludo con la mano
    _waveController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Animación de alerta
    _alertController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    // Animación de parpadeo
    _eyeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    ));

    _armWaveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.elasticOut,
    ));

    _alertShakeAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _alertController,
      curve: Curves.elasticInOut,
    ));

    _eyeBlinkAnimation = Tween<double>(
      begin: 1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _eyeController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    ));
  }

  void _startCurrentAnimation() {
    _stopAllAnimations();

    switch (widget.state) {
      case MascotState.idle:
        _idleController.repeat(reverse: true);
        _startRandomBlink();
        break;
      case MascotState.waving:
        _waveController.repeat(reverse: true);
        _idleController.repeat(reverse: true);
        break;
      case MascotState.alert:
        _alertController.repeat(reverse: true);
        break;
      case MascotState.pointing:
        _idleController.repeat(reverse: true);
        break;
      case MascotState.celebrating:
        _waveController.repeat();
        _idleController.repeat(reverse: true);
        break;
    }
  }

  void _startRandomBlink() {
    Future.delayed(Duration(milliseconds: 2000 + (DateTime.now().millisecond % 3000)), () {
      if (mounted && widget.state == MascotState.idle) {
        _eyeController.forward().then((_) {
          _eyeController.reverse().then((_) {
            _startRandomBlink();
          });
        });
      }
    });
  }

  void _stopAllAnimations() {
    _idleController.stop();
    _waveController.stop();
    _alertController.stop();
    _eyeController.stop();
  }

  @override
  void didUpdateWidget(TrafficMascot oldWidget) {
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
        animation: Listenable.merge([
          _idleController,
          _waveController,
          _alertController,
          _eyeController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              widget.state == MascotState.alert ? _alertShakeAnimation.value : 0,
              -_bounceAnimation.value,
            ),
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: MascotPainter(
                    armWaveProgress: _armWaveAnimation.value,
                    eyeScale: _eyeBlinkAnimation.value,
                    mascotState: widget.state,
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

class MascotPainter extends CustomPainter {
  final double armWaveProgress;
  final double eyeScale;
  final MascotState mascotState;

  MascotPainter({
    required this.armWaveProgress,
    required this.eyeScale,
    required this.mascotState,
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
    paint.color = Colors.black.withOpacity(0.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.9),
        width: size.width * 0.6,
        height: size.height * 0.1,
      ),
      paint,
    );

    // Zapatos
    _drawShoes(canvas, size, paint, strokePaint);

    // Piernas
    _drawLegs(canvas, size, paint, strokePaint);

    // Cuerpo (señal de tráfico)
    _drawBody(canvas, size, paint, strokePaint, center, radius);

    // Brazos
    _drawArms(canvas, size, paint, strokePaint, center);

    // Gorra de policía
    _drawCap(canvas, size, paint, strokePaint, center);

    // Cara
    _drawFace(canvas, size, paint, strokePaint, center, radius);
  }

  void _drawShoes(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    paint.color = Colors.grey[800]!;

    // Zapato izquierdo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.85, size.width * 0.18, size.height * 0.1),
        Radius.circular(10),
      ),
      paint,
    );

    // Zapato derecho
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.57, size.height * 0.85, size.width * 0.18, size.height * 0.1),
        Radius.circular(10),
      ),
      paint,
    );

    // Suela naranja
    paint.color = Colors.orange;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.9, size.width * 0.18, size.height * 0.05),
        Radius.circular(8),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.57, size.height * 0.9, size.width * 0.18, size.height * 0.05),
        Radius.circular(8),
      ),
      paint,
    );
  }

  void _drawLegs(Canvas canvas, Size size, Paint paint, Paint strokePaint) {
    paint.color = Colors.black;

    // Pierna izquierda
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.65, size.width * 0.08, size.height * 0.25),
        Radius.circular(5),
      ),
      paint,
    );

    // Pierna derecha
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.65, size.width * 0.08, size.height * 0.25),
        Radius.circular(5),
      ),
      paint,
    );
  }

  void _drawBody(Canvas canvas, Size size, Paint paint, Paint strokePaint, Offset center, double radius) {
    // Cuerpo principal (círculo rojo)
    paint.color = Colors.red;
    canvas.drawCircle(center, radius, paint);

    // Borde del círculo
    strokePaint.strokeWidth = 4;
    strokePaint.color = Colors.white;
    canvas.drawCircle(center, radius, strokePaint);

    // Línea diagonal blanca (señal de prohibido)
    strokePaint.strokeWidth = radius * 0.3;
    strokePaint.color = Colors.white;
    canvas.drawLine(
      Offset(center.dx - radius * 0.6, center.dy - radius * 0.6),
      Offset(center.dx + radius * 0.6, center.dy + radius * 0.6),
      strokePaint,
    );

    // Borde negro exterior
    strokePaint.strokeWidth = 3;
    strokePaint.color = Colors.black;
    strokePaint.style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, strokePaint);
  }

  void _drawArms(Canvas canvas, Size size, Paint paint, Paint strokePaint, Offset center) {
    paint.color = Colors.black;

    // Brazo izquierdo
    double leftArmAngle = mascotState == MascotState.waving ?
    -0.5 - (armWaveProgress * 0.8) : -0.3;
    canvas.save();
    canvas.translate(center.dx - size.width * 0.25, center.dy);
    canvas.rotate(leftArmAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.04, -size.width * 0.15, size.width * 0.08, size.width * 0.3),
        Radius.circular(8),
      ),
      paint,
    );
    canvas.restore();

    // Brazo derecho (sostiene bastón)
    double rightArmAngle = mascotState == MascotState.pointing ? -0.8 : 0.3;
    canvas.save();
    canvas.translate(center.dx + size.width * 0.25, center.dy);
    canvas.rotate(rightArmAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.width * 0.04, -size.width * 0.15, size.width * 0.08, size.width * 0.3),
        Radius.circular(8),
      ),
      paint,
    );
    canvas.restore();

    // Guantes blancos
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.25, center.dy + size.width * 0.15),
      size.width * 0.06,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.25, center.dy + size.width * 0.15),
      size.width * 0.06,
      paint,
    );

    // Bastón
    if (mascotState == MascotState.pointing || mascotState == MascotState.alert) {
      strokePaint.strokeWidth = 4;
      strokePaint.color = Colors.brown;
      canvas.drawLine(
        Offset(center.dx + size.width * 0.25, center.dy + size.width * 0.15),
        Offset(center.dx + size.width * 0.4, center.dy - size.width * 0.2),
        strokePaint,
      );
    }
  }

  void _drawCap(Canvas canvas, Size size, Paint paint, Paint strokePaint, Offset center) {
    // Gorra azul
    paint.color = Color(0xFF2E5984);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - size.width * 0.25),
        width: size.width * 0.5,
        height: size.width * 0.3,
      ),
      3.14, // π
      3.14, // π
      false,
      paint,
    );

    // Visera
    paint.color = Color(0xFF1E3A52);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - size.width * 0.15),
        width: size.width * 0.6,
        height: size.width * 0.15,
      ),
      3.14 * 0.8,
      3.14 * 0.4,
      false,
      paint,
    );

    // Insignia blanca
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.width * 0.25),
      size.width * 0.04,
      paint,
    );
  }

  void _drawFace(Canvas canvas, Size size, Paint paint, Paint strokePaint, Offset center, double radius) {
    // Cejas
    paint.color = Colors.black;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - radius * 0.4, center.dy - radius * 0.3, radius * 0.25, radius * 0.1),
        Radius.circular(5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx + radius * 0.15, center.dy - radius * 0.3, radius * 0.25, radius * 0.1),
        Radius.circular(5),
      ),
      paint,
    );

    // Ojos
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.1),
      radius * 0.15 * eyeScale,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.3, center.dy - radius * 0.1),
      radius * 0.15 * eyeScale,
      paint,
    );

    // Pupilas
    paint.color = Colors.black;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.1),
      radius * 0.08 * eyeScale,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.3, center.dy - radius * 0.1),
      radius * 0.08 * eyeScale,
      paint,
    );

    // Boca
    if (mascotState == MascotState.celebrating) {
      // Sonrisa grande
      strokePaint.strokeWidth = 3;
      strokePaint.color = Colors.black;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius * 0.2),
          width: radius * 0.6,
          height: radius * 0.4,
        ),
        0,
        3.14,
        false,
        strokePaint,
      );
    } else {
      // Boca normal
      strokePaint.strokeWidth = 2;
      strokePaint.color = Colors.black;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius * 0.15),
          width: radius * 0.3,
          height: radius * 0.2,
        ),
        0,
        3.14,
        false,
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) {
    return oldDelegate.armWaveProgress != armWaveProgress ||
        oldDelegate.eyeScale != eyeScale ||
        oldDelegate.mascotState != mascotState;
  }
}

// Ejemplo de uso
class MascotDemo extends StatefulWidget {
  @override
  _MascotDemoState createState() => _MascotDemoState();
}

class _MascotDemoState extends State<MascotDemo> {
  MascotState currentState = MascotState.idle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mascota de Tráfico'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TrafficMascot(
              state: currentState,
              size: 250,
              onTap: () {
                setState(() {
                  currentState = MascotState.celebrating;
                });
                Future.delayed(Duration(seconds: 2), () {
                  setState(() {
                    currentState = MascotState.idle;
                  });
                });
              },
            ),
            SizedBox(height: 40),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => currentState = MascotState.idle),
                  child: Text('Idle'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentState = MascotState.waving),
                  child: Text('Saludar'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentState = MascotState.alert),
                  child: Text('Alerta'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentState = MascotState.pointing),
                  child: Text('Señalar'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentState = MascotState.celebrating),
                  child: Text('Celebrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}