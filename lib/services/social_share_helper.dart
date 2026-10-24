import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialShareHelper {
  /// Opens WhatsApp with pre-composed text
  static Future<bool> shareToWhatsApp(String text) async {
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    return _launch(uri);
  }

  /// Opens Telegram share
  static Future<bool> shareToTelegram(String text, {String? url}) async {
    final uri = Uri.parse(
      'https://t.me/share/url?url=${Uri.encodeComponent(url ?? '')}&text=${Uri.encodeComponent(text)}',
    );
    return _launch(uri);
  }

  /// Opens X / Twitter share
  static Future<bool> shareToTwitter(String text, {String? url}) async {
    final uri = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}${url != null ? '&url=${Uri.encodeComponent(url)}' : ''}',
    );
    return _launch(uri);
  }

  /// Opens Facebook web share
  static Future<bool> shareToFacebook(String url) async {
    final uri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}',
    );
    return _launch(uri);
  }

  /// Copy text or link to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
