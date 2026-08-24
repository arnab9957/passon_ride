import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../services/feedback_service.dart';
import 'supabase_auth_dialog.dart';

/// Modal Sheet strictly for Bike & Tour Rental Reviews (Cleanliness, Performance, Host Communication, Value)
class RentalReviewModal extends StatefulWidget {
  final String? vehicleId;
  final String? tourId;
  final String? bookingId;

  const RentalReviewModal({
    super.key,
    this.vehicleId,
    this.tourId,
    this.bookingId,
  });

  @override
  State<RentalReviewModal> createState() => _RentalReviewModalState();
}

class _RentalReviewModalState extends State<RentalReviewModal> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _commentController = TextEditingController();

  double _overallRating = 5.0;
  double _cleanlinessRating = 5.0;
  double _performanceRating = 5.0;
  double _communicationRating = 5.0;
  double _valueRating = 5.0;

  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Spotless Clean',
    'Full Battery / Fuel',
    'Smooth Engine',
    'Super Host',
    'Keyless Smooth',
    'Accurate Telematics',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
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
    final uname = appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName : 'Verified Rider';
    final uavatar = appState.activeUserPhotoUrl.isNotEmpty
        ? appState.activeUserPhotoUrl
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80';

    final rawComment = _commentController.text.trim();
    final finalComment = rawComment.isNotEmpty
        ? rawComment
        : 'Rated ${_overallRating.toStringAsFixed(1)} stars for rental experience.';

    try {
      await _feedbackService.submitTripAspectReview(
        bookingId: widget.bookingId,
        vehicleId: widget.vehicleId,
        tourId: widget.tourId,
        riderId: uid,
        hostId: 'host_user_id',
        riderName: uname,
        riderAvatar: uavatar,
        overallRating: _overallRating,
        cleanlinessRating: _cleanlinessRating,
        performanceRating: _performanceRating,
        communicationRating: _communicationRating,
        valueRating: _valueRating,
        comment: finalComment,
        selectedTags: _selectedTags,
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
                Text('Thank you! Your rental review has been published.'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
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

            // Header title
            const Text(
              'Rate Rental & Vehicle Experience',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Rate vehicle cleanliness, performance, host service, and value',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Overall Star Rating
            Center(
              child: Column(
                children: [
                  Text(
                    '${_overallRating.toStringAsFixed(1)} Stars',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        onPressed: () => setState(() => _overallRating = starValue),
                        icon: Icon(
                          starValue <= _overallRating ? Icons.star : Icons.star_border,
                          size: 32,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Aspect Sliders Breakdown
            _buildAspectSlider('Cleanliness & Hygiene', _cleanlinessRating, (val) => setState(() => _cleanlinessRating = val)),
            _buildAspectSlider('Engine / Battery Performance', _performanceRating, (val) => setState(() => _performanceRating = val)),
            _buildAspectSlider('Host Communication', _communicationRating, (val) => setState(() => _communicationRating = val)),
            _buildAspectSlider('Value for Money', _valueRating, (val) => setState(() => _valueRating = val)),

            const SizedBox(height: 12),

            // Quick Rental Tags
            Text(
              'Select Rental Tags',
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
                hintText: 'Share feedback about bike condition, host handover, or pickup...',
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
                onPressed: _isSubmitting ? null : _submitReview,
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
                          Text('Publish Rental Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildAspectSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 5,
            child: Slider(
              value: value,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: value.toStringAsFixed(1),
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
