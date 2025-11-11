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
  final double depth;               // profundidad del efecto 3D

  const CoinButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 78,
    this.rimDark = const Color(0xFF1976D2),      // Azul oscuro como la imagen
    this.rimLight = const Color(0xFF42A5F5),     // Azul claro
    this.faceDark = const Color(0xFF2196F3),     // Azul medio oscuro
    this.faceLight = const Color(0xFF64B5F6),    // Azul medio claro
    this.iconColor = Colors.white,
    this.elevation = 12,
    this.iconScale = 0.48,
    this.depth = 8.0,                            // Profundidad del cilindro
  });

  @override
  State<CoinButton> createState() => _CoinButtonState();
}

class _CoinButtonState extends State<CoinButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final scale = _pressed ? 0.95 : 1.0;
    final y = _pressed ? widget.depth * 0.6 : 0.0;
    final currentDepth = _pressed ? widget.depth * 0.4 : widget.depth;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: s,
        height: s + currentDepth,
        transform: Matrix4.identity()..translate(0.0, y)..scale(scale),
        child: Stack(
          clipBehavior: Clip.none, // Permite que el contenido se extienda fuera del contenedor
          children: [
            // SOMBRA EXTERIOR con color del botón
            if (!_pressed)
              Positioned(
                left: widget.elevation * 0.25,
                top: widget.elevation * 0.4,
                child: Container(
                  width: s,
                  height: s + currentDepth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(s / 2),
                      bottom: Radius.circular(s / 2),
                    ),
                    color: widget.faceDark.withOpacity(0.6),
                  ),
                ),
              ),

            // CUERPO DEL CILINDRO (lateral) - colores más intensos del botón
            Positioned(
              top: s / 2,
              child: Container(
                width: s,
                height: currentDepth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      widget.faceDark,
                      widget.faceLight.withOpacity(0.8),
                      widget.faceDark.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // CARA INFERIOR (elipse) - color del botón
            Positioned(
              top: s / 2 + currentDepth - 1,
              child: Container(
                width: s,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.faceDark.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(s / 2),
                ),
              ),
            ),

            // CARA SUPERIOR (principal)
            Positioned(
              top: 0,
              child: Container(
                width: s,
                height: s,
                // ARO (rim) con gradiente + sombra exterior
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [widget.rimLight, widget.rimDark],
                  ),
                ),
                child: Padding(
                  // deja visible el aro
                  padding: EdgeInsets.all(s * 0.08),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // CARA (face) con radial (centro claro, borde más oscuro)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(-0.2, -0.25),
                              radius: 0.8,
                              colors: [widget.faceLight, widget.faceDark],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),

                        // Sombra interna suave abajo-derecha
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: SweepGradient(
                              startAngle: 0,
                              endAngle: 6.28318, // 2π
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.15),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.05, 0.55, 0.75, 0.85, 1.0],
                              center: Alignment.center,
                            ),
                          ),
                        ),

                        // Brillo elíptico arriba-izq (más suave)
                        Align(
                          alignment: const Alignment(-0.4, -0.4),
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              width: s * 0.6,
                              height: s * 0.35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(s),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.4),
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Ícono con ligera sombra
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
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
            ),
          ],
        ),
      ),
    );
  }
}

// Ejemplo de uso:
class ExampleUsage extends StatelessWidget {
  const ExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón como en la imagen (azul)
            CoinButton(
              icon: Icons.fast_forward,
              onTap: () => print('Botón presionado!'),
              size: 100,
            ),

            SizedBox(height: 40),

            // Versión dorada (tu diseño original)
            CoinButton(
              icon: Icons.play_arrow,
              onTap: () => print('Botón dorado presionado!'),
              size: 100,
              rimDark: Color(0xFFCC8A05),
              rimLight: Color(0xFFFFD54F),
              faceDark: Color(0xFFF2B603),
              faceLight: Color(0xFFFFF176),
            ),

            SizedBox(height: 40),

            // Versión roja
            CoinButton(
              icon: Icons.favorite,
              onTap: () => print('Botón rojo presionado!'),
              size: 80,
              rimDark: Color(0xFFD32F2F),
              rimLight: Color(0xFFEF5350),
              faceDark: Color(0xFFF44336),
              faceLight: Color(0xFFFF7043),
              depth: 6.0,
            ),
          ],
        ),
      ),
    );
  }
}