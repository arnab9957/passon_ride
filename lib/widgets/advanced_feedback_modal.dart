// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../services/feedback_service.dart';
import 'supabase_auth_dialog.dart';

/// Modal Sheet strictly for PassionRide App & Platform Experience Feedback / Bug Reports
class AdvancedFeedbackModal extends StatefulWidget {
  final String initialCategory;

  const AdvancedFeedbackModal({
    super.key,
    this.initialCategory = 'app_experience',
  });

  @override
  State<AdvancedFeedbackModal> createState() => _AdvancedFeedbackModalState();
}

class _AdvancedFeedbackModalState extends State<AdvancedFeedbackModal> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _commentController = TextEditingController();

  late String _selectedCategory;
  double _rating = 5.0;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  String _aiSentimentBadge = 'Positive';

  final List<String> _availableTags = [
    'Super Smooth UI',
    'Keyless Pin Fast',
    'AI Itinerary Epic',
    'Slick Design',
    'High Performance',
    'Fast Support',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _commentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _commentController.text.toLowerCase();
    setState(() {
      if (_rating <= 2.5 || text.contains('bug') || text.contains('fail') || text.contains('crash')) {
        _aiSentimentBadge = 'Needs Review';
      } else if (_rating <= 3.5 || text.contains('okay') || text.contains('slow')) {
        _aiSentimentBadge = 'Neutral';
      } else {
        _aiSentimentBadge = 'Positive';
      }
    });
  }

  Future<void> _submitFeedback() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (!appState.isSignedIn) {
      showDialog(
        context: context,
        builder: (_) => const SupabaseAuthDialog(),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final uid = appState.activeUserId.isNotEmpty ? appState.activeUserId : 'user_authenticated';
    final uname = appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName : 'PassionRide Member';
    final uavatar = appState.activeUserPhotoUrl.isNotEmpty
        ? appState.activeUserPhotoUrl
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80';

    final rawComment = _commentController.text.trim();
    final finalComment = rawComment.isNotEmpty
        ? rawComment
        : 'Rated ${_rating.toStringAsFixed(1)} stars for app experience.';

    try {
      await _feedbackService.submitAppFeedbackReview(
        userId: uid,
        userName: uname,
        userAvatar: uavatar,
        category: _selectedCategory,
        rating: _rating,
        comment: finalComment,
        isPublic: true,
        metadata: {
          'app_version': '2.4.0',
          'platform': Theme.of(context).platform.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Thank you! Your app feedback has been published.'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Handle pill bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariantLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header title & AI sentiment badge
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PassionRide App Feedback',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Help us improve app UI, report bugs, or suggest features',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _aiSentimentBadge == 'Positive'
                        ? Colors.green.withOpacity(0.15)
                        : Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _aiSentimentBadge == 'Positive' ? Colors.green : Colors.amber,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: _aiSentimentBadge == 'Positive' ? Colors.green : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI: $_aiSentimentBadge',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _aiSentimentBadge == 'Positive' ? Colors.green.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category selector tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('app_experience', 'App Experience', Icons.stars),
                  const SizedBox(width: 8),
                  _buildCategoryChip('bug_report', 'Report Bug', Icons.bug_report_outlined),
                  const SizedBox(width: 8),
                  _buildCategoryChip('feature_request', 'Feature Suggestion', Icons.lightbulb_outline),
                  const SizedBox(width: 8),
                  _buildCategoryChip('platform_trust', 'Security & Platform', Icons.verified_user_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rating Stars Bar
            Center(
              child: Column(
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        onPressed: () => setState(() => _rating = starValue),
                        icon: Icon(
                          starValue <= _rating ? Icons.star : Icons.star_border,
                          size: 32,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick App Tags
            Text(
              'Select Tags',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariantLight),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceLight,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Comment text area
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your feedback about PassionRide app features, UI, speed, or bugs...',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outlineVariantLight),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Publish App Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildCategoryChip(String catId, String label, IconData icon) {
    final isSelected = _selectedCategory == catId;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.onSurfaceVariantLight),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = catId),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.onSurfaceLight,
      ),
    );
  }
}
