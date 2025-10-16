import 'package:flutter/material.dart';
import 'package:eduvial/widgets/mascot/traffic_light_mascot.dart';

Future<void> showRankingWelcomeDialog(
    BuildContext context, {
      required String message,
      bool autoClose = true,
    }) async {
  if (!context.mounted) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Bienvenida',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim, secAnim) {
      return _RankingWelcomeContent(message: message, autoClose: autoClose);
    },
    transitionBuilder: (ctx, anim, secAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return Transform.scale(
        scale: 0.95 + 0.05 * curved.value,
        child: Opacity(opacity: anim.value, child: child),
      );
    },
  );
}

class _RankingWelcomeContent extends StatefulWidget {
  final String message;
  final bool autoClose;
  const _RankingWelcomeContent({required this.message, this.autoClose = true});

  @override
  State<_RankingWelcomeContent> createState() => _RankingWelcomeContentState();
}

class _RankingWelcomeContentState extends State<_RankingWelcomeContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);
  late final Animation<double> _bob =
  Tween<double>(begin: -6, end: 6).chain(CurveTween(curve: Curves.easeInOut)).animate(_ctrl);

  @override
  void initState() {
    super.initState();
    if (widget.autoClose) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double cardW = screen.width * 0.88;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: cardW,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(blurRadius: 24, color: Colors.black26, offset: Offset(0, 12))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _bob,
                builder: (_, child) => Transform.translate(offset: Offset(0, _bob.value), child: child),
                child: const TrafficLightMascot(state: MascotState.waving, size: 96),
              ),
              const SizedBox(height: 12),
              _SpeechBubble(text: widget.message, maxWidth: cardW - 32),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Entendido'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final double maxWidth;
  const _SpeechBubble({required this.text, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDEE4EE)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1F2937), height: 1.25),
          ),
        ),
        Positioned(
          top: -8,
          left: 32,
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                border: Border(
                  top: BorderSide(color: const Color(0xFFDEE4EE)),
                  left: BorderSide(color: const Color(0xFFDEE4EE)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
