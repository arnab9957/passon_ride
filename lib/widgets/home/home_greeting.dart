import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';

/// Greeting + search bar that sends the query to Discovery.
class HomeGreeting extends StatefulWidget {
  const HomeGreeting({super.key});

  @override
  State<HomeGreeting> createState() => _HomeGreetingState();
}

class _HomeGreetingState extends State<HomeGreeting> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(AppState appState) {
    appState.updateSearch(_controller.text.trim());
    appState.setNavIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = appState.isLoggedIn ? appState.activeUserDisplayName.split(' ').first : 'Traveller';
    final place = appState.selectedLocation.split(',').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hi $name 👋', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 2),
        const Text('Where to next?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(appState),
          decoration: InputDecoration(
            hintText: 'Search bikes, stays or tours near $place',
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
              onPressed: () => _submit(appState),
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceContainerDark : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
