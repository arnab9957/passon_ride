import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class AiTourGeneratorScreen extends StatefulWidget {
  const AiTourGeneratorScreen({super.key});

  @override
  State<AiTourGeneratorScreen> createState() => _AiTourGeneratorScreenState();
}

class _AiTourGeneratorScreenState extends State<AiTourGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Create a 1-day scenic motorcycle tour starting from San Francisco through Big Sur with twisty coastal roads, scenic photo spots, and local seafood stops.',
  );
  bool _isGenerating = false;
  bool _hasResult = false;

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.tertiary, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI CO-PILOT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('AI Tour Guide Generator', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Prompt Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Describe Your Ideal Tour Experience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _promptController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Enter preferences, terrain, duration, budget, points of interest...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating
                        ? null
                        : () async {
                            setState(() {
                              _isGenerating = true;
                              _hasResult = false;
                            });
                            await Future.delayed(const Duration(seconds: 2));
                            setState(() {
                              _isGenerating = false;
                              _hasResult = true;
                            });
                          },
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.bolt),
                    label: Text(_isGenerating ? 'AI Generating Itinerary...' : 'Generate Itinerary with AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Generated Result
          if (_hasResult) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pacific Coast Highway & Big Sur Coastal Run',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('AI GENERATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Curated 6-hour route covering 142 miles of iconic Northern California coastline. Optimized for adventure and touring motorcycles.',
                    style: TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('Generated Waypoints:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildAiWaypoint('1. Start: Ocean Beach SF (09:00 AM)', 'Check-in & safety briefing'),
                  _buildAiWaypoint('2. Bixby Creek Bridge (11:30 AM)', 'Scenic photo viewpoint & drone spot'),
                  _buildAiWaypoint('3. Nepenthe Restaurant (01:00 PM)', 'Cliffside lunch with ocean views'),
                  _buildAiWaypoint('4. McWay Falls Point (03:00 PM)', 'Waterfall over beach viewpoint'),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.spatial_audio_off, color: AppColors.tertiary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Includes AI Voice Guide Script & Intercom Audio Markers',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final prompt = _promptController.text.trim();
                        final generatedTour = Tour(
                          id: 't_${DateTime.now().millisecondsSinceEpoch}',
                          title: prompt.isEmpty ? 'AI Tour: Pacific Coast Run' : 'AI Tour: Scenic Coastal Run',
                          location: 'Big Sur & Monterey, CA',
                          price: 185.00,
                          duration: '1-Day Tour',
                          rating: 5.0,
                          reviewCount: 1,
                          imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80',
                          guideName: appState.activeUserDisplayName,
                          guideAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
                          waypoints: ['Bixby Bridge Overlook', 'Nepenthe Seaside Stop', 'Pfeiffer Canyon Ride'],
                          includedGear: ['Helmet with Intercom', 'GoPro Camera Mount', 'Snacks & Hydration'],
                          description: 'AI optimized touring route curated for maximum scenery, safe turns, and scenic rest stops.',
                        );

                        appState.setDraftTourFromAi(generatedTour);
                        appState.setNavIndex(11); // Go to register tour screen
                      },
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Convert AI Tour to Marketplace Listing'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAiWaypoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, color: AppColors.primary),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  TextSpan(text: '$title - ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
