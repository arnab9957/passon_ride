import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/feedback_model.dart';

class AspectRatingWidget extends StatelessWidget {
  final AspectRatingSummary summary;
  final bool isInteractive;
  final Function(double cleanliness, double performance, double communication, double value)? onAspectsChanged;

  const AspectRatingWidget({
    super.key,
    required this.summary,
    this.isInteractive = false,
    this.onAspectsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasReviews = summary.totalReviews > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariantLight.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: hasReviews
                      ? LinearGradient(colors: [AppColors.primary, AppColors.tertiary])
                      : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      hasReviews ? summary.averageOverall.toStringAsFixed(1) : '0.0',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          hasReviews && index < summary.averageOverall.floor() ? Icons.star : Icons.star_border,
                          size: 10,
                          color: hasReviews ? Colors.amber : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public Aspect Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasReviews
                          ? 'Based on ${summary.totalReviews} verified rental reviews'
                          : 'No ratings submitted yet (0 reviews)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _buildAspectBar('Vehicle Cleanliness', summary.averageCleanliness, Icons.clean_hands_outlined, hasReviews),
          const SizedBox(height: 10),
          _buildAspectBar('Engine & Battery Performance', summary.averagePerformance, Icons.speed_outlined, hasReviews),
          const SizedBox(height: 10),
          _buildAspectBar('Host Communication', summary.averageCommunication, Icons.chat_bubble_outline, hasReviews),
          const SizedBox(height: 10),
          _buildAspectBar('Value for Money', summary.averageValue, Icons.attach_money, hasReviews),
        ],
      ),
    );
  }

  Widget _buildAspectBar(String label, double rating, IconData icon, bool hasReviews) {
    final percentage = hasReviews ? (rating / 5.0).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: hasReviews ? AppColors.primary : Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceLight,
                ),
              ),
            ),
            Text(
              '${hasReviews ? rating.toStringAsFixed(1) : '0.0'} / 5.0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: hasReviews ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(
              !hasReviews
                  ? Colors.grey.shade400
                  : (rating >= 4.5
                      ? Colors.green.shade700
                      : (rating >= 3.5 ? Colors.amber.shade700 : Colors.deepOrangeAccent)),
            ),
          ),
        ),
      ],
    );
  }
}
