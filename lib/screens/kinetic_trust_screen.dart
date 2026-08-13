import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class KineticTrustScreen extends StatelessWidget {
  const KineticTrustScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => appState.setNavIndex(7), // Back to profile
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY & REPUTATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Kinetic Trust Scoring', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Trust Score Hero Gauge Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                    : [AppColors.primary, AppColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: 0.985,
                        strokeWidth: 10,
                        backgroundColor: Colors.white24,
                        color: AppColors.secondaryContainer,
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('98.5', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('/ 100', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('TIER 1 SUPERHOST & RENTER', style: TextStyle(color: AppColors.secondaryContainer, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                const Text('Top 1% Reputation Score in San Francisco Bay Area', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Driving Telemetry Metrics
          const Text('Driving & Riding Telemetry Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          _buildHabitRow('Smooth Acceleration & Braking', 0.99, '99%', AppColors.secondary, isDark),
          _buildHabitRow('Speed Limit Adherence', 0.97, '97%', AppColors.primary, isDark),
          _buildHabitRow('On-Time Return Record', 1.0, '100%', AppColors.tertiary, isDark),

          const SizedBox(height: 24),

          // Verification Badges
          const Text('Community Trust Badges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadgeChip('ID Verified', Icons.badge),
              _buildBadgeChip('License Verified', Icons.verified),
              _buildBadgeChip('Clean Telemetry', Icons.sensors),
              _buildBadgeChip('50+ Rentals', Icons.star),
              _buildBadgeChip('Superhost', Icons.military_tech),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHabitRow(String title, double pct, String val, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.black12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.primaryContainer.withOpacity(0.15),
    );
  }
}
