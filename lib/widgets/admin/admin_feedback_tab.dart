import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/feedback_model.dart';
import '../../theme/app_colors.dart';

class AdminFeedbackTab extends StatefulWidget {
  final List<AppFeedbackReview> feedbacks;
  final Function(AppFeedbackReview review, String newStatus)? onUpdateFeedbackStatus;

  const AdminFeedbackTab({
    super.key,
    required this.feedbacks,
    this.onUpdateFeedbackStatus,
  });

  @override
  State<AdminFeedbackTab> createState() => _AdminFeedbackTabState();
}

class _AdminFeedbackTabState extends State<AdminFeedbackTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSentiment = 'All';

  List<AppFeedbackReview> get _filteredFeedbacks {
    return widget.feedbacks.where((f) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          f.userName.toLowerCase().contains(q) ||
          f.comment.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q) ||
          f.aiTags.any((tag) => tag.toLowerCase().contains(q));

      final matchesCategory = _selectedCategory == 'All' ||
          f.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesSentiment = _selectedSentiment == 'All' ||
          f.aiSentiment.toLowerCase() == _selectedSentiment.toLowerCase();

      return matchesSearch && matchesCategory && matchesSentiment;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredFeedbacks;

    final int bugReportsCount = widget.feedbacks.where((f) => f.category == 'bug_report').length;
    final int negativeSentimentCount = widget.feedbacks.where((f) => f.aiSentiment == 'negative').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search feedback comments, users, or tags...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              // Category Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    items: ['All', 'bug_report', 'app_experience', 'feature_request', 'platform_trust'].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Categories' : c.replaceAll('_', ' ').toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sentiment Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSentiment,
                    items: ['All', 'positive', 'neutral', 'negative'].map((s) {
                      return DropdownMenuItem(value: s, child: Text('AI: ${s.toUpperCase()}'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSentiment = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overview counters
          Row(
            children: [
              Text(
                'Showing ${filtered.length} of ${widget.feedbacks.length} Feedback Records',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              if (bugReportsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text('$bugReportsCount Bug Reports', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                ),
              if (negativeSentimentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text('$negativeSentimentCount Negative Sentiments', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Feedbacks List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No feedback entries found matching current filter criteria.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isNegative = item.aiSentiment.toLowerCase() == 'negative';
                      final isBug = item.category.toLowerCase() == 'bug_report';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isBug || isNegative
                                ? Colors.red.withValues(alpha: 0.4)
                                : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
                            width: isBug || isNegative ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: item.userAvatar.isNotEmpty ? NetworkImage(item.userAvatar) : null,
                                  child: item.userAvatar.isEmpty ? const Icon(Icons.person, size: 18) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.userName.isNotEmpty ? item.userName : 'Anonymous Rider',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                // Rating Stars
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      starIdx < item.rating.floor() ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 10),
                                _buildSentimentBadge(item.aiSentiment),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.comment,
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            // Tags & Category
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.category.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                for (final tag in item.aiTags)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('#$tag', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ),
                                if (item.attachmentUrls.isNotEmpty)
                                  InkWell(
                                    onTap: () async {
                                      final uri = Uri.tryParse(item.attachmentUrls.first);
                                      if (uri != null && await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.attachment, size: 12, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text('${item.attachmentUrls.length} Attachment(s)', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentBadge(String sentiment) {
    Color bg;
    Color fg;
    switch (sentiment.toLowerCase()) {
      case 'positive':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        break;
      case 'negative':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(sentiment.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
