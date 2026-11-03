import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../services/social_share_helper.dart';
import '../screens/provider_catalog_showcase_screen.dart';

class ShareProviderCatalogDialog extends StatefulWidget {
  final String hostId;
  final String hostName;
  final List<Vehicle> vehicles;
  final List<Tour> tours;
  final List<Hotel> hotels;

  const ShareProviderCatalogDialog({
    super.key,
    required this.hostId,
    required this.hostName,
    required this.vehicles,
    required this.tours,
    this.hotels = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required String hostId,
    required String hostName,
    required List<Vehicle> vehicles,
    required List<Tour> tours,
    List<Hotel> hotels = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareProviderCatalogDialog(
        hostId: hostId,
        hostName: hostName,
        vehicles: vehicles,
        tours: tours,
        hotels: hotels,
      ),
    );
  }

  @override
  State<ShareProviderCatalogDialog> createState() => _ShareProviderCatalogDialogState();
}

class _ShareProviderCatalogDialogState extends State<ShareProviderCatalogDialog> {
  bool _showQrCode = false;

  String get _catalogUrl {
    final cleanId = widget.hostId.trim();
    final cleanName = Uri.encodeComponent(widget.hostName.trim());
    final baseUrl = kIsWeb && Uri.base.origin.isNotEmpty
        ? Uri.base.origin
        : 'https://passionride.app';
    return '$baseUrl/#/host?id=$cleanId&name=$cleanName';
  }

  String get _shareText {
    final buffer = StringBuffer();
    buffer.writeln('🏍️🚗 Explore ${widget.hostName}\'s Rental Fleet & Tours on PassionRide!');
    buffer.writeln('');

    if (widget.vehicles.isNotEmpty) {
      buffer.writeln('Available Vehicles:');
      for (final v in widget.vehicles.take(4)) {
        buffer.writeln('• ${v.title} — ₹${v.pricePerDay.toStringAsFixed(0)}/day');
      }
      if (widget.vehicles.length > 4) {
        buffer.writeln('  (+${widget.vehicles.length - 4} more bikes and cars)');
      }
      buffer.writeln('');
    }

    if (widget.hotels.isNotEmpty) {
      buffer.writeln('Hotels & Stays:');
      for (final h in widget.hotels.take(3)) {
        buffer.writeln('  - ${h.name}, ${h.location}');
      }
      buffer.writeln();
    }

    if (widget.tours.isNotEmpty) {
      buffer.writeln('Guided Experiences:');
      for (final t in widget.tours.take(2)) {
        buffer.writeln('• ${t.title} — ₹${t.price.toStringAsFixed(0)} (${t.duration})');
      }
      buffer.writeln('');
    }

    buffer.writeln('Book online instantly: $_catalogUrl');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Storefront & Catalog',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Share all your ${widget.vehicles.length} vehicles, ${widget.tours.length} tours & ${widget.hotels.length} stays',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR Code Card or Toggle
          if (_showQrCode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _catalogUrl,
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan to view ${widget.hostName}\'s Catalog',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Place this QR at your rental desk or counter',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick Action Chips (Preview & QR Toggle)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _showQrCode = !_showQrCode);
                  },
                  icon: Icon(_showQrCode ? Icons.qr_code : Icons.qr_code_2),
                  label: Text(_showQrCode ? 'Hide QR Code' : 'Display Counter QR'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderCatalogShowcaseScreen(
                          hostId: widget.hostId,
                          hostName: widget.hostName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('Live Customer View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Social Share Buttons Row
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SHARE DIRECTLY ON SOCIAL MEDIA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSocialButton(
                  title: 'WhatsApp',
                  icon: Icons.chat,
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    await SocialShareHelper.shareToWhatsApp(_shareText);
                  },
                ),
                const SizedBox(width: 12),
                _buildSocialButton(
                  title: 'Telegram',
                  icon: Icons.send,
                  color: const Color(0xFF0088CC),
                  onTap: () async {
                    await SocialShareHelper.shareToTelegram(_shareText, url: _catalogUrl);
                  },
                ),
                const SizedBox(width: 12),
                _buildSocialButton(
                  title: 'X / Twitter',
                  icon: Icons.tag,
                  color: Colors.black,
                  onTap: () async {
                    await SocialShareHelper.shareToTwitter(
                      'Check out my verified rental vehicles on PassionRide!',
                      url: _catalogUrl,
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildSocialButton(
                  title: 'Facebook',
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  onTap: () async {
                    await SocialShareHelper.shareToFacebook(_catalogUrl);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Copy Link & Copy Formatted Summary Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerLowest : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _catalogUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await SocialShareHelper.copyToClipboard(_catalogUrl);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Catalog link copied to clipboard!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Copy Link'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await SocialShareHelper.copyToClipboard(_shareText);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete listing message copied with vehicle prices!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_all, size: 16),
            label: const Text('Copy Full Catalog Summary Message'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
