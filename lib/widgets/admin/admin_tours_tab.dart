import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class AdminToursTab extends StatefulWidget {
  final List<Tour> tours;
  final Function(Tour tour) onDeleteTour;

  const AdminToursTab({
    super.key,
    required this.tours,
    required this.onDeleteTour,
  });

  @override
  State<AdminToursTab> createState() => _AdminToursTabState();
}

class _AdminToursTabState extends State<AdminToursTab> {
  String _searchQuery = '';

  List<Tour> get _filteredTours {
    return widget.tours.where((t) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.location.toLowerCase().contains(q) ||
          t.guideName.toLowerCase().contains(q);
    }).toList();
  }

  void _showDeleteDialog(Tour tour) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tour Package?'),
        content: Text('Are you sure you want to remove "${tour.title}" from the marketplace?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteTour(tour);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTourDetails(Tour tour) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tour.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tour.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(tour.imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const SizedBox()),
                ),
              const SizedBox(height: 12),
              _buildRow('Tour ID', tour.id),
              _buildRow('Location', tour.location),
              _buildRow('Price', '₹${tour.price.toStringAsFixed(0)} / person'),
              _buildRow('Duration', tour.duration),
              _buildRow('Guide Name', tour.guideName),
              _buildRow('Rating', '★ ${tour.rating.toStringAsFixed(1)} (${tour.reviewCount} reviews)'),
              _buildRow('Expiry Status', tour.formattedExpiryDate),
              if (tour.waypoints.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Waypoints / Stops:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(tour.waypoints.join(' -> '), style: const TextStyle(fontSize: 12)),
              ],
              if (tour.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(tour.description, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredTours;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tours by title, location, or guide name...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 16),

          // Tours List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No guided tour packages found.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tour = filtered[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 60,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
                              child: tour.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(tour.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.tour)),
                                    )
                                  : const Icon(Icons.tour, color: Colors.grey),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tour.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tour.location} • Guide: ${tour.guideName} • Duration: ${tour.duration}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${tour.price.toStringAsFixed(0)} / person • ★ ${tour.rating.toStringAsFixed(1)} (${tour.reviewCount} reviews)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  tooltip: 'Details',
                                  onPressed: () => _showTourDetails(tour),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  tooltip: 'Delete Tour',
                                  onPressed: () => _showDeleteDialog(tour),
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
}
