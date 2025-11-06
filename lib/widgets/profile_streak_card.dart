// lib/widgets/profile_streak_card.dart
import 'package:flutter/material.dart';
import 'package:eduvial/services/streak_service.dart';
import 'package:eduvial/models/streak.dart';

class ProfileStreakCard extends StatelessWidget {
  const ProfileStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StreakMe>(
      future: StreakService.getMyStreak(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cargando racha...'),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se pudo cargar la racha'),
            ),
          );
        }
        final me = snap.data!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, size: 36),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Racha actual: ${me.currentStreak} días',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('Máxima: ${me.maxStreak} días',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
