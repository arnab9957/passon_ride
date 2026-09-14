import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A robust circular avatar that renders network images, base64 images,
/// and gracefully falls back to the user's initial or person icon on loading error.
/// Prevents blank solid color circles when images fail to load or have CORS restrictions.
class UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = photoUrl.trim();
    final cleanName = displayName.trim();
    final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '';
    final bg = backgroundColor ?? AppColors.primary;
    final fg = textColor ?? Colors.white;
    final size = radius * 2;

    Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bg,
            bg.withValues(alpha: 0.82),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: initial.isNotEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: fg,
                fontSize: fontSize ?? (radius * 0.72),
                fontWeight: FontWeight.bold,
              ),
            )
          : Icon(
              Icons.person_rounded,
              color: fg,
              size: radius * 1.1,
            ),
    );

    Widget content = fallback;

    if (cleanUrl.isNotEmpty && cleanUrl != 'null' && cleanUrl != 'undefined') {
      if (cleanUrl.startsWith('data:image')) {
        try {
          final base64Str = cleanUrl.contains(',') ? cleanUrl.split(',').last : cleanUrl;
          final bytes = base64Decode(base64Str);
          content = ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          );
        } catch (_) {
          content = fallback;
        }
      } else {
        content = ClipOval(
          child: Image.network(
            cleanUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return fallback;
            },
          ),
        );
      }
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
