import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../widgets/aspect_rating_widget.dart';

class FeedbackDashboardScreen extends StatefulWidget {
  const FeedbackDashboardScreen({super.key});

  @override
  State<FeedbackDashboardScreen> createState() => _FeedbackDashboardScreenState();
}

class _FeedbackDashboardScreenState extends State<FeedbackDashboardScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _replyController = TextEditingController();

  List<TripAspectReview> _tripReviews = [];
  List<AppFeedbackReview> _appReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final tripRes = await _feedbackService.getTripAspectReviewsForVehicle('');
    final appRes = await _feedbackService.getPublicAppFeedbackReviews();

    if (mounted) {
      setState(() {
        _tripReviews = tripRes;
        _appReviews = appRes;
        _isLoading = false;
      });
    }
  }

  void _showReplyDialog(TripAspectReview rev) {
    _replyController.text = rev.hostResponse ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${rev.riderName}'),
        content: TextField(
          controller: _replyController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type your official host response...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.trim().isNotEmpty) {
                await _feedbackService.addHostResponse(rev.id, _replyController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _loadDashboardData();
                }
              }
            },
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = AspectRatingSummary.fromReviews(_tripReviews);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Trust Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall rating summary widget
                  AspectRatingWidget(summary: summary),
                  const SizedBox(height: 20),

                  // AI Sentiment Summary Cards
                  Text(
                    'AI Sentiment Analysis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurfaceLight),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSentimentMetricCard('Positive', '92%', Colors.green, Icons.sentiment_very_satisfied),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSentimentMetricCard('Neutral', '6%', Colors.amber, Icons.sentiment_neutral),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSentimentMetricCard('Critical', '2%', Colors.redAccent, Icons.sentiment_very_dissatisfied),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Rental Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Rental & Host Reviews',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurfaceLight),
                      ),
                      Text(
                        '${_tripReviews.length} total',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariantLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tripReviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rev = _tripReviews[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.outlineVariantLight.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(rev.riderAvatar),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rev.riderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Rating: ${rev.overallRating}★', style: TextStyle(fontSize: 11, color: Colors.amber.shade800)),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showReplyDialog(rev),
                                  icon: const Icon(Icons.reply, size: 16),
                                  label: Text(rev.hostResponse != null ? 'Edit Reply' : 'Reply'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(rev.comment, style: const TextStyle(fontSize: 12)),
                            if (rev.hostResponse != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Host Reply: ${rev.hostResponse}', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSentimentMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
