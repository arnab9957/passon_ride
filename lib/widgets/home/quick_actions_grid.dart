import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';

class _QuickAction {
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final void Function(AppState) onTap;

  const _QuickAction(this.title, this.hint, this.icon, this.color, this.onTap);
}

void _browse(AppState s, String category) {
  s.setCategory(category);
  s.setNavIndex(1);
}

final _actions = [
  _QuickAction(
    'Rent a Ride',
    'Bikes, cars & scooters',
    Icons.two_wheeler,
    const Color(0xFF1E6FD9),
    (s) => _browse(s, 'Motorcycles'),
  ),
  _QuickAction(
    'Book a Stay',
    'Homestays & hotels',
    Icons.holiday_village_rounded,
    const Color(0xFF0E9F6E),
    (s) => _browse(s, 'Hotels and Stays'),
  ),
  _QuickAction(
    'Join a Tour',
    'Guided group trips',
    Icons.tour,
    const Color(0xFFE07A10),
    (s) => _browse(s, 'Guided Tours'),
  ),
  _QuickAction(
    'List & Earn',
    'Host your bike or stay',
    Icons.add_rounded,
    const Color(0xFF8B3FD9),
    (s) => s.setNavIndex(8),
  ), // Provider dashboard
];

/// "What do you need?" 2x2 grid of the app's main actions.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What do you need?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // 2x2 on phones, single row of 4 on tablet/desktop
              crossAxisCount: constraints.maxWidth >= 700 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 110,
            ),
            children: _actions.map((a) {
              return InkWell(
                onTap: () => a.onTap(appState),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : a.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: a.color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(12)),
                        child: Icon(a.icon, color: Colors.white, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            a.hint,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
