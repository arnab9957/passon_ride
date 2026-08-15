import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class RegisterTourScreen extends StatefulWidget {
  const RegisterTourScreen({super.key});

  @override
  State<RegisterTourScreen> createState() => _RegisterTourScreenState();
}

class _RegisterTourScreenState extends State<RegisterTourScreen> {
  final _titleController = TextEditingController(text: 'Sierra Nevada Alpine Ridge Tour');
  final _priceController = TextEditingController(text: '179.00');
  final _locationController = TextEditingController(text: 'Lake Tahoe, CA');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      final draft = appState.draftTourFromAi;
      if (draft != null) {
        _titleController.text = draft.title;
        _priceController.text = draft.price.toStringAsFixed(0);
        _locationController.text = draft.location;
      }
    });
  }

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
                onPressed: () => appState.setNavIndex(8),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GUIDE WIZARD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Register Guided Tour', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tour Experience Title',
              prefixIcon: Icon(Icons.tour),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Starting Location / Region',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price Per Rider (₹ INR)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),

          const SizedBox(height: 24),

          const Text('Waypoints & Stops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          _buildWaypointTile('Stop 1', 'Emerald Bay Lookout Point'),
          _buildWaypointTile('Stop 2', 'Mount Rose Summit Peak'),
          _buildWaypointTile('Stop 3', 'High Alpine Cafe Lunch Break'),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final title = _titleController.text.trim();
                final price = double.tryParse(_priceController.text.trim()) ?? 179.0;
                final location = _locationController.text.trim();

                final newTour = Tour(
                  id: 't_${DateTime.now().millisecondsSinceEpoch}',
                  title: title.isEmpty ? 'Sierra Nevada Alpine Ridge Tour' : title,
                  location: location.isEmpty ? 'Lake Tahoe, CA' : location,
                  price: price,
                  duration: 'Full Day (6 hrs)',
                  rating: 5.0,
                  reviewCount: 1,
                  imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80',
                  guideName: appState.activeUserDisplayName,
                  guideAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
                  waypoints: ['Emerald Bay Lookout', 'Mount Rose Peak', 'High Alpine Cafe'],
                  includedGear: ['Full Face Helmet', 'Bluetooth Intercom', 'Roadside Assist'],
                  description: 'Experience guided mountain roads with an experienced local host.',
                );

                await appState.addTour(newTour);
                appState.clearDraftTourFromAi();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Guided Tour "$title" Published Live!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  appState.setNavIndex(8);
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Publish Guided Tour', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWaypointTile(String stop, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(stop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
