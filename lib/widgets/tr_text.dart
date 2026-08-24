import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// Dynamic Auto-Translating Text Widget powered by LibreTranslate Engine & LRU Cache
class TrText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;

  const TrText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return Text(text, style: style, textAlign: textAlign, overflow: overflow, maxLines: maxLines, softWrap: softWrap);
    }

    final langProvider = Provider.of<LanguageProvider>(context);

    // Default English shortcut
    if (langProvider.currentLanguageCode == 'en') {
      return Text(text, style: style, textAlign: textAlign, overflow: overflow, maxLines: maxLines, softWrap: softWrap);
    }

    final cached = langProvider.getCachedTranslation(text);

    return FutureBuilder<String>(
      future: langProvider.translateText(text),
      initialData: cached,
      builder: (context, snapshot) {
        final displayText = (snapshot.data != null && snapshot.data!.isNotEmpty)
            ? snapshot.data!
            : cached;

        return Text(
          displayText,
          style: style,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          softWrap: softWrap,
        );
      },
    );
  }
}
