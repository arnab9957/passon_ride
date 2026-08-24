import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'advanced_feedback_modal.dart';
import 'supabase_auth_dialog.dart';

/// Movable & Draggable Global Feedback Trigger Button
class GlobalFeedbackFab extends StatefulWidget {
  const GlobalFeedbackFab({super.key});

  @override
  State<GlobalFeedbackFab> createState() => _GlobalFeedbackFabState();
}

class _GlobalFeedbackFabState extends State<GlobalFeedbackFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  double? _left;
  double? _top;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openFeedbackModal(BuildContext context) {
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
      builder: (_) => const AdvancedFeedbackModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final estimatedWidth = 128.0;
    final buttonHeight = 44.0;

    // Default position: Down Left Corner
    _left ??= 16.0;
    _top ??= screenSize.height - buttonHeight - 120.0;

    return Positioned(
      left: _left,
      top: _top,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _left = (_left! + details.delta.dx).clamp(10.0, screenSize.width - estimatedWidth - 10.0).toDouble();
            _top = (_top! + details.delta.dy).clamp(40.0, screenSize.height - buttonHeight - 40.0).toDouble();
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onTap: () => _openFeedbackModal(context),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            elevation: _isDragging ? 10 : 6,
            borderRadius: BorderRadius.circular(24),
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: buttonHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.secondaryContainer,
                border: Border.all(
                  color: _isDragging ? AppColors.primary : AppColors.secondary,
                  width: _isDragging ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isDragging ? AppColors.primary : Colors.black).withValues(alpha: _isDragging ? 0.35 : 0.2),
                    blurRadius: _isDragging ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 18,
                    color: AppColors.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
