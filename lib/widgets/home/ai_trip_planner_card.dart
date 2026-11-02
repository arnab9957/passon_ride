import 'package:flutter/material.dart';

import '../../screens/ai_trip_planner_screen.dart';
import '../../theme/app_colors.dart';

/// Home-screen entry point for the AI Trip Planner.
class AiTripPlannerCard extends StatelessWidget {
  const AiTripPlannerCard({super.key});

  void _open(BuildContext context, [String destination = '']) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AiTripPlannerScreen(initialDestination: destination)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.auto_awesome, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('AI Trip Planner',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ]),
                  const SizedBox(height: 6),
                  const Text(
                    'Tell us where you\'re going — get a day-by-day plan with rides, stays and tours you can book.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final d in const ['Puri', 'Goa', 'Manali', 'Leh Ladakh'])
                      ActionChip(
                        label: Text(d),
                        avatar: const Icon(Icons.place, size: 16, color: AppColors.primary),
                        backgroundColor: Colors.white,
                        labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        side: BorderSide.none,
                        onPressed: () => _open(context, d),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
