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
  final TextEditingController _promptController = TextEditingController();
  int _durationDays = 3;
  String _selectedBudget = 'Standard';
  String _selectedTerrain = 'Mountain Pass';
  bool _isGenerating = false;
  bool _hasResult = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draftTour = appState.draftTourFromAi;

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
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
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

          // Form Card
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
                const Text('Describe Your Tour Destination & Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _promptController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Kolkata → Darjeeling, Pacific Coast Highway, Leh Ladakh...',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Trip Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('$_durationDays Days', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                Slider(
                  value: _durationDays.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_durationDays Days',
                  onChanged: (val) => setState(() => _durationDays = val.toInt()),
                ),
                const SizedBox(height: 12),
                const Text('Budget Tier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Extreme Budget', 'Standard', 'Luxury'].map((b) {
                    final isSel = _selectedBudget == b;
                    return ChoiceChip(
                      label: Text(b),
                      selected: isSel,
                      onSelected: (v) {
                        if (v) setState(() => _selectedBudget = b);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Terrain & Route Style', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Mountain Pass', 'Coastal Highway', 'Desert Highway', 'Forest Trails'].map((t) {
                    final isSel = _selectedTerrain == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: isSel,
                      onSelected: (v) {
                        if (v) setState(() => _selectedTerrain = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
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
                            await appState.generateAiItinerary(
                              destination: _promptController.text.trim(),
                              durationDays: _durationDays,
                              budget: _selectedBudget,
                              terrain: _selectedTerrain,
                            );
                            if (mounted) {
                              setState(() {
                                _isGenerating = false;
                                _hasResult = true;
                              });
                            }
                          },
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.bolt),
                    label: Text(_isGenerating ? 'AI Generating Itinerary...' : 'Generate Itinerary with AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Generated Result Card
          if (_hasResult && draftTour != null) ...[
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
                      Expanded(
                        child: Text(
                          draftTour.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  Text(
                    draftTour.description,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('Generated Waypoints & Daily Stops:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...draftTour.waypoints.map((wp) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(wp, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 16),
                  const Text('Included Riding Gear:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: draftTour.includedGear.map((g) => Chip(
                          label: Text(g, style: const TextStyle(fontSize: 11)),
                          padding: const EdgeInsets.all(2),
                        )).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        appState.setNavIndex(11); // Go to register tour screen with draft prefilled
                      },
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('Publish as Guided Group Tour', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
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
}
