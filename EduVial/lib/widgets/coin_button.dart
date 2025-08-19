import 'package:flutter/material.dart';

class CoinButton extends StatefulWidget {
  final double size;                // diámetro
  final IconData icon;
  final VoidCallback onTap;
  final Color rimDark;              // aro oscuro
  final Color rimLight;             // aro claro
  final Color faceDark;             // cara (fondo) oscuro
  final Color faceLight;            // cara (fondo) claro
  final Color iconColor;
  final double elevation;           // sombra exterior
  final double iconScale;           // tamaño relativo del ícono

  const CoinButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 78,
    this.rimDark = const Color(0xFFCC8A05),
    this.rimLight = const Color(0xFFFFD54F),
    this.faceDark = const Color(0xFFF2B603),
    this.faceLight = const Color(0xFFFFF176),
    this.iconColor = Colors.white,
    this.elevation = 12,
    this.iconScale = 0.48,
  });

  @override
  State<CoinButton> createState() => _CoinButtonState();
}

class _CoinButtonState extends State<CoinButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final scale = _pressed ? 0.97 : 1.0;
    final y = _pressed ? 2.0 : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        width: s,
        height: s,
        transform: Matrix4.identity()..translate(0.0, y)..scale(scale),
        // ARO (rim) con gradiente + sombra exterior
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.rimLight, widget.rimDark],
          ),
          boxShadow: _pressed
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              offset: Offset(widget.elevation * 0.35, widget.elevation * 0.55),
              blurRadius: widget.elevation * 1.2,
            ),
          ],
        ),
        child: Padding(
          // deja visible el aro
          padding: EdgeInsets.all(s * 0.10),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // CARA (face) con radial (centro claro, borde más oscuro)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.25),
                      radius: 0.95,
                      colors: [widget.faceLight, widget.faceDark],
                      stops: const [0.15, 1.0],
                    ),
                  ),
                ),

                // Sombra interna suave abajo-derecha (simula bisel hundido)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      startAngle: 0,
                      endAngle: 6.28318, // 2π
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.18), // zona oscura
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.05, 0.58, 0.72, 0.86, 1.0],
                      center: Alignment.center,
                    ),
                  ),
                ),

                // Brillo elíptico arriba-izq
                Align(
                  alignment: const Alignment(-0.55, -0.55),
                  child: Transform.rotate(
                    angle: -0.35,
                    child: Container(
                      width: s * 0.55,
                      height: s * 0.30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(s),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.55),
                            Colors.white.withOpacity(0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Ícono con ligera sombra para que “flote”
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          offset: const Offset(0, 2.2),
                          blurRadius: 4.5,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: s * widget.iconScale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
