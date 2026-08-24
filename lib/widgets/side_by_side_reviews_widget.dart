import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import 'advanced_feedback_modal.dart';
import 'supabase_auth_dialog.dart';
import 'tr_text.dart';

/// Clean App Feedback Reviews Showcase Widget with Stars Breakdown
class SideBySideReviewsWidget extends StatefulWidget {
  final String? vehicleId;
  final String? tourId;
  final String title;

  const SideBySideReviewsWidget({
    super.key,
    this.vehicleId,
    this.tourId,
    this.title = 'PassionRide App Reviews & Ratings',
  });

  @override
  State<SideBySideReviewsWidget> createState() => _SideBySideReviewsWidgetState();
}

class _SideBySideReviewsWidgetState extends State<SideBySideReviewsWidget> {
  final FeedbackService _feedbackService = FeedbackService();

  List<AppFeedbackReview> _appReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllReviews();
  }

  Future<void> _loadAllReviews() async {
    setState(() => _isLoading = true);

    try {
      final appList = await _feedbackService.getPublicAppFeedbackReviews();

      if (mounted) {
        setState(() {
          _appReviews = appList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openRateAppModal() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isSignedIn) {
      showDialog(
        context: context,
        builder: (_) => const SupabaseAuthDialog(),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdvancedFeedbackModal(initialCategory: 'app_experience'),
    ).then((_) => _loadAllReviews());
  }

  @override
  Widget build(BuildContext context) {
    double averageAppRating = 0.0;
    if (_appReviews.isNotEmpty) {
      final double totalSum = _appReviews.fold(0.0, (sum, r) => sum + r.rating);
      averageAppRating = totalSum / _appReviews.length;
    }

    final hasReviews = _appReviews.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Rating Stars Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariantLight.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: hasReviews
                          ? LinearGradient(colors: [AppColors.primary, AppColors.tertiary])
                          : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          hasReviews ? averageAppRating.toStringAsFixed(1) : '0.0',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (index) => Icon(
                              hasReviews && index < averageAppRating.floor() ? Icons.star : Icons.star_border,
                              size: 11,
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
                        TrText(
                          'PassionRide App Rating',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurfaceLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TrText(
                          hasReviews
                              ? 'Based on ${_appReviews.length} verified app feedback reviews'
                              : 'No app ratings submitted yet (0 reviews)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariantLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openRateAppModal,
                    icon: const Icon(Icons.rate_review_outlined, size: 16),
                    label: const TrText('Rate App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // App Reviews Stream List
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_appReviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No app reviews submitted yet. Be the first to leave app feedback!',
                style: TextStyle(color: AppColors.onSurfaceVariantLight, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appReviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rev = _appReviews[index];
              return _buildAppReviewCard(rev);
            },
          ),
      ],
    );
  }

  Widget _buildAppReviewCard(AppFeedbackReview rev) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariantLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(rev.userAvatar),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rev.userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceLight,
                      ),
                    ),
                    Text(
                      'PassionRide App Review • ${_timeAgo(rev.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rev.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rev.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            TrText(
              rev.comment,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceLight, height: 1.3),
            ),
          ],
          if (rev.aiTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: rev.aiTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚡ $tag',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
