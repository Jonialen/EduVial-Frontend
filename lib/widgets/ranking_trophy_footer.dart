import 'package:flutter/material.dart';

class RankingTrophyFooter extends StatefulWidget {
  const RankingTrophyFooter({super.key});

  @override
  State<RankingTrophyFooter> createState() => _RankingTrophyFooterState();
}

class _RankingTrophyFooterState extends State<RankingTrophyFooter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl =
  AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  late final Animation<double> _sweep =
  Tween(begin: -0.3, end: 1.3).animate(CurvedAnimation(
    parent: _shineCtrl,
    curve: Curves.easeInOut,
  ));

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 160, // altura fija → no tapa la lista
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Trofeo base
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.emoji_events,
                      size: 110,
                      color: Color(0xFFFFC107), // amarillo trofeo
                    ),
                  ),
                  // Brillo que barre en diagonal
                  AnimatedBuilder(
                    animation: _shineCtrl,
                    builder: (_, __) {
                      final dx = _sweep.value; // -0.3 → 1.3
                      return Transform.translate(
                        offset: Offset(110 * dx - 20, -10),
                        child: Transform.rotate(
                          angle: 0.6,
                          child: Container(
                            width: 28,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.45),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Estrellitas
                  const Positioned(
                    right: -4,
                    top: 6,
                    child: Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                  ),
                  const Positioned(
                    left: -2,
                    bottom: 8,
                    child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
