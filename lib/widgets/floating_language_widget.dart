import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import 'native_language_selector_dialog.dart';

/// Quick-Access Native Language Selector Button
class FloatingLanguageWidget extends StatelessWidget {
  final bool compact;

  const FloatingLanguageWidget({
    super.key,
    this.compact = false,
  });

  void _openLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NativeLanguageSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final active = langProvider.activeLanguage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLanguageModal(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineVariantLight.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(active.flagEmoji, style: const TextStyle(fontSize: 16)),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  active.nativeName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceLight,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: AppColors.onSurfaceVariantLight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
