import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Links to the static policy pages in web/legal/.
class LegalLinks {
  static const _siteUrl = 'https://passon-ride-rental-888.web.app';

  static Uri uriFor(String page) =>
      kIsWeb ? Uri.base.resolve('legal/$page.html') : Uri.parse('$_siteUrl/legal/$page.html');

  static Future<void> open(String page) =>
      launchUrl(uriFor(page), mode: LaunchMode.externalApplication);
}

/// "By continuing you agree to the Terms, Privacy Policy and Cancellation Policy."
class LegalConsentText extends StatelessWidget {
  final String prefix;

  const LegalConsentText({super.key, this.prefix = 'By continuing you agree to our'});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 11, color: Theme.of(context).hintColor);
    final link = base.copyWith(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline);
    TextSpan linkSpan(String text, String page) =>
        TextSpan(text: text, style: link, recognizer: TapGestureRecognizer()..onTap = () => LegalLinks.open(page));

    return Text.rich(
      TextSpan(style: base, children: [
        TextSpan(text: '$prefix '),
        linkSpan('Terms', 'terms'),
        const TextSpan(text: ', '),
        linkSpan('Privacy Policy', 'privacy'),
        const TextSpan(text: ' and '),
        linkSpan('Cancellation Policy', 'refunds'),
        const TextSpan(text: '.'),
      ]),
      textAlign: TextAlign.center,
    );
  }
}

/// List of the three policies, for the profile / settings screen.
class LegalLinksSection extends StatelessWidget {
  const LegalLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String page) => ListTile(
          dense: true,
          leading: Icon(icon, size: 20),
          title: Text(title),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => LegalLinks.open(page),
        );
    return Column(
      children: [
        tile(Icons.description_outlined, 'Terms of Service', 'terms'),
        tile(Icons.privacy_tip_outlined, 'Privacy Policy', 'privacy'),
        tile(Icons.receipt_long_outlined, 'Cancellation & Refund Policy', 'refunds'),
      ],
    );
  }
}
