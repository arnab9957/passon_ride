import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

Widget buildBlogIframe({required String postId, required String embedUrl}) {
  final isYoutube = embedUrl.contains('youtube.com') || embedUrl.contains('youtu.be');
  final isInstagram = embedUrl.contains('instagram.com');
  final isTwitter = embedUrl.contains('twitter.com') || embedUrl.contains('x.com') || embedUrl.contains('Tweet.html');
  final isFacebook = embedUrl.contains('facebook.com');

  Color platformColor = Colors.grey.shade700;
  IconData platformIcon = Icons.link;
  String platformName = 'Web Post';

  if (isYoutube) {
    platformColor = const Color(0xFFFF0000);
    platformIcon = Icons.play_circle_filled;
    platformName = 'YouTube';
  } else if (isInstagram) {
    platformColor = const Color(0xFFE1306C);
    platformIcon = Icons.camera_alt;
    platformName = 'Instagram';
  } else if (isTwitter) {
    platformColor = const Color(0xFF1DA1F2);
    platformIcon = Icons.chat_bubble_outline;
    platformName = 'Twitter / X';
  } else if (isFacebook) {
    platformColor = const Color(0xFF1877F2);
    platformIcon = Icons.facebook;
    platformName = 'Facebook';
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    decoration: BoxDecoration(
      color: platformColor.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: platformColor.withOpacity(0.15)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: platformColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(platformIcon, size: 36, color: platformColor),
        ),
        const SizedBox(height: 12),
        Text(
          '$platformName Embed Available',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'Connect social handle to view live posts',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            // If the URL is an embed URL, attempt to open the original link or the embed link itself
            final uri = Uri.parse(embedUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
          label: Text('View Live on $platformName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: platformColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(fontSize: 12),
          ),
        )
      ],
    ),
  );
}
