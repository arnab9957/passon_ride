import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/poster_file_helper.dart';
import '../services/social_share_helper.dart';

const _brand = 'PassOn Ride';
const _brandColor = Color(0xFF2563EB);

/// One shareable listing (vehicle, tour or stay) of a provider.
class PromoItem {
  final String kind; // 'vehicle' | 'tour' | 'stay'
  final String id;
  final String title;
  final String category;
  final String location;
  final double price;
  final String priceUnit; // '/day', '/person', '/night'
  final String imageUrl;
  final String link;

  const PromoItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.price,
    required this.priceUnit,
    required this.imageUrl,
    required this.link,
  });

  String get priceLabel =>
      '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(price)}$priceUnit';
}

/// Public storefront URL of a provider; [itemId] opens that vehicle directly.
String providerStoreUrl(String hostId, String hostName, {String? itemId, String? source}) {
  final base = kIsWeb && Uri.base.origin.isNotEmpty ? Uri.base.origin : 'https://passionride.app';
  final q = <String>[
    'id=${Uri.encodeComponent(hostId.trim())}',
    'name=${Uri.encodeComponent(hostName.trim())}',
    if (itemId != null && itemId.isNotEmpty) 'item=${Uri.encodeComponent(itemId)}',
    if (source != null) 'src=$source',
  ];
  return '$base/#/host?${q.join('&')}';
}

enum CaptionStyle { short, detailed, hindi }

/// Builds a ready-to-post caption for [item].
String buildCaption(PromoItem item, String hostName, CaptionStyle style) {
  final tagKind = switch (item.kind) {
    'vehicle' => item.category.toLowerCase().contains('car') ? '#CarRental #SelfDrive' : '#BikeRental #ScootyOnRent',
    'tour' => '#TourPackage #TravelIndia',
    _ => '#Homestay #HotelBooking',
  };
  final city = item.location.split(',').first.trim();
  final cityTag = city.isEmpty ? '' : ' #${city.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';
  final tags = '$tagKind$cityTag #PassOnRide #Travel';
  final where = item.location.isEmpty ? '' : ' in ${item.location}';
  final verb = switch (item.kind) {
    'vehicle' => 'Rent',
    'tour' => 'Join',
    _ => 'Stay at',
  };

  switch (style) {
    case CaptionStyle.short:
      return '🔥 ${item.title}$where — just ${item.priceLabel}!\n'
          '$verb now 👉 ${item.link}\n\n$tags';
    case CaptionStyle.detailed:
      final perks = switch (item.kind) {
        'vehicle' => '✅ Well-maintained & sanitised\n✅ Easy online booking — pay at pickup\n✅ Verified host: $hostName',
        'tour' => '✅ Local expert guide\n✅ Instant online booking\n✅ Hosted by $hostName',
        _ => '✅ Clean, comfortable rooms\n✅ Instant online booking\n✅ Hosted by $hostName',
      };
      return '🌟 ${item.title}${item.category.isEmpty ? '' : ' (${item.category})'}$where\n\n'
          '💰 Only ${item.priceLabel}\n$perks\n\n'
          '📲 Book in 1 minute: ${item.link}\n\n$tags';
    case CaptionStyle.hindi:
      final hVerb = switch (item.kind) {
        'vehicle' => 'किराए पर लें',
        'tour' => 'टूर बुक करें',
        _ => 'रूम बुक करें',
      };
      return '🔥 ${item.title}$where — सिर्फ ${item.priceLabel}!\n'
          '✅ आसान ऑनलाइन बुकिंग, भरोसेमंद होस्ट: $hostName\n'
          '👉 अभी $hVerb: ${item.link}\n\n$tags';
  }
}

/// Lists all of a provider's listings with a one-tap "Promote" action.
class SocialPromoteSheet extends StatelessWidget {
  final String hostId;
  final String hostName;
  final List<PromoItem> items;

  const SocialPromoteSheet({super.key, required this.hostId, required this.hostName, required this.items});

  static Future<void> show(
    BuildContext context, {
    required String hostId,
    required String hostName,
    required List<Vehicle> vehicles,
    required List<Tour> tours,
    required List<Hotel> hotels,
  }) {
    final storeLink = providerStoreUrl(hostId, hostName);
    final items = <PromoItem>[
      for (final v in vehicles)
        PromoItem(
          kind: 'vehicle',
          id: v.id,
          title: v.title,
          category: v.category,
          location: v.location,
          price: v.pricePerDay,
          priceUnit: '/day',
          imageUrl: v.imageUrl,
          link: providerStoreUrl(hostId, hostName, itemId: v.id),
        ),
      for (final t in tours)
        PromoItem(
          kind: 'tour',
          id: t.id,
          title: t.title,
          category: t.duration,
          location: t.location,
          price: t.price,
          priceUnit: '/person',
          imageUrl: t.imageUrl,
          link: storeLink,
        ),
      for (final h in hotels)
        PromoItem(
          kind: 'stay',
          id: h.id,
          title: h.name,
          category: h.roomType,
          location: h.location,
          price: h.pricePerNight,
          priceUnit: '/night',
          imageUrl: h.imageUrl,
          link: storeLink,
        ),
    ];
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SocialPromoteSheet(hostId: hostId, hostName: hostName, items: items),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.campaign_rounded, color: _brandColor),
          const SizedBox(width: 8),
          Text('Promote on Social Media',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: scheme.onSurface)),
        ]),
        const SizedBox(height: 4),
        Text('Pick a listing — we make a poster with a booking QR code and a ready caption.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Add a vehicle, tour or stay first to promote it.',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final it = items[i];
                return Material(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(width: 56, height: 56, child: _NetImage(it.imageUrl)),
                    ),
                    title: Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${it.priceLabel} • ${it.kind[0].toUpperCase()}${it.kind.substring(1)}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: FilledButton.icon(
                      onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => PromoComposerScreen(item: it, hostName: hostName),
                      )),
                      style: FilledButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                    ),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }
}

/// Poster preview + caption editor + share buttons for one listing.
class PromoComposerScreen extends StatefulWidget {
  final PromoItem item;
  final String hostName;

  const PromoComposerScreen({super.key, required this.item, required this.hostName});

  @override
  State<PromoComposerScreen> createState() => _PromoComposerScreenState();
}

class _PromoComposerScreenState extends State<PromoComposerScreen> {
  final _posterKey = GlobalKey();
  final _caption = TextEditingController();
  bool _story = false;
  CaptionStyle _style = CaptionStyle.short;
  bool _busy = false;

  PromoItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _caption.text = buildCaption(item, widget.hostName, _style);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (item.imageUrl.isNotEmpty) {
      precacheImage(NetworkImage(item.imageUrl), context).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _setStyle(CaptionStyle s) {
    setState(() {
      _style = s;
      _caption.text = buildCaption(item, widget.hostName, s);
    });
  }

  Future<Uint8List?> _renderPoster() async {
    final boundary = _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  /// Caption that always carries the booking link, even if the provider edited it out.
  String get _captionWithLink {
    final t = _caption.text.trim();
    return t.contains(item.link) ? t : '$t\n\n👉 Book here: ${item.link}';
  }

  String get _posterName =>
      '${item.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_${_story ? 'story' : 'post'}.png';

  Future<Uint8List?> _safeRender() async {
    try {
      return await _renderPoster();
    } catch (e) {
      debugPrint('Poster render failed: $e');
      return null;
    }
  }

  Future<void> _sharePoster() async {
    setState(() => _busy = true);
    final text = _captionWithLink;
    try {
      final png = await _safeRender();
      if (png == null) {
        _toast("Couldn't create the poster image — sharing caption + link only.");
        await SharePlus.instance.share(ShareParams(text: text, subject: item.title));
        return;
      }
      if (kIsWeb && !canShareImageFile(png, _posterName)) {
        // Desktop browsers can't attach files: download the poster, copy the caption.
        downloadFile(png, _posterName);
        await SocialShareHelper.copyToClipboard(text);
        _toast('Poster downloaded & caption (with link) copied — attach the image in your post.');
        return;
      }
      // Many apps (WhatsApp, Instagram…) drop the text when an image is attached,
      // so copy it too — the provider can just paste.
      await SocialShareHelper.copyToClipboard(text);
      final result = await SharePlus.instance.share(ShareParams(
        text: text,
        subject: item.title,
        files: [XFile.fromData(png, mimeType: 'image/png', name: _posterName)],
        fileNameOverrides: [_posterName],
      ));
      if (result.status == ShareResultStatus.success || result.status == ShareResultStatus.unavailable) {
        _toast('Caption with link is copied — paste it if the app shows only the image.');
      }
    } catch (e) {
      await SocialShareHelper.copyToClipboard(text);
      _toast('Sharing failed — caption with link copied instead.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPoster() async {
    final png = await _safeRender();
    if (png == null) {
      _toast("Couldn't create the poster image.");
      return;
    }
    if (kIsWeb) {
      downloadFile(png, _posterName);
      _toast('Poster downloaded');
    } else {
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png', name: _posterName)],
        fileNameOverrides: [_posterName],
      ));
    }
  }

  Future<void> _open(Future<bool> Function() launch, String app) async {
    await SocialShareHelper.copyToClipboard(_captionWithLink);
    final ok = await launch();
    if (!ok) _toast('Could not open $app');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final link = item.link;
    final text = _captionWithLink;
    return Scaffold(
      appBar: AppBar(title: const Text('Promote listing')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // Format toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.crop_square), label: Text('Post 1:1')),
                ButtonSegment(value: true, icon: Icon(Icons.crop_portrait), label: Text('Story 9:16')),
              ],
              selected: {_story},
              onSelectionChanged: (s) => setState(() => _story = s.first),
            ),
            const SizedBox(height: 12),

            // Poster preview (rendered at a fixed logical size, scaled to fit)
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: _story ? 520 : 400),
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _posterKey,
                    child: _Poster(item: item, hostName: widget.hostName, story: _story),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Caption
            Text('Caption', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final s in CaptionStyle.values)
                ChoiceChip(
                  label: Text(switch (s) {
                    CaptionStyle.short => 'Short',
                    CaptionStyle.detailed => 'Detailed',
                    CaptionStyle.hindi => 'हिंदी',
                  }),
                  selected: _style == s,
                  onSelected: (_) => _setStyle(s),
                ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _caption,
              minLines: 4,
              maxLines: 10,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  tooltip: 'Copy caption',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await SocialShareHelper.copyToClipboard(_caption.text);
                    _toast('Caption copied');
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Primary share
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _busy ? null : _sharePoster,
                style: FilledButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.ios_share),
                label: const Text('Share poster + caption (Instagram, WhatsApp…)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Quick share (caption is copied too)',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _QuickBtn('WhatsApp', Icons.chat, const Color(0xFF25D366),
                  () => _open(() => SocialShareHelper.shareToWhatsApp(text), 'WhatsApp')),
              _QuickBtn('Facebook', Icons.facebook, const Color(0xFF1877F2),
                  () => _open(() => SocialShareHelper.shareToFacebook(link), 'Facebook')),
              _QuickBtn('X', Icons.alternate_email, Colors.black,
                  () => _open(() => SocialShareHelper.shareToTwitter(text), 'X')),
              _QuickBtn('Telegram', Icons.send, const Color(0xFF229ED9),
                  () => _open(() => SocialShareHelper.shareToTelegram(text, url: link), 'Telegram')),
              _QuickBtn('Tumblr', Icons.text_fields, const Color(0xFF001935),
                  () => _open(() => SocialShareHelper.shareToTumblr(link, caption: text), 'Tumblr')),
              _QuickBtn('Download poster', Icons.download, const Color(0xFFDB2777), _downloadPoster),
              _QuickBtn('Copy link', Icons.link, Colors.grey.shade700, () async {
                await SocialShareHelper.copyToClipboard(link);
                _toast('Booking link copied');
              }),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class _NetImage extends StatelessWidget {
  final String url;
  const _NetImage(this.url);

  @override
  Widget build(BuildContext context) => url.isEmpty
      ? Container(color: Colors.grey.shade300, child: const Icon(Icons.image, color: Colors.grey))
      : Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Container(color: Colors.grey.shade300, child: const Icon(Icons.image, color: Colors.grey)));
}

/// The shareable marketing poster. Fixed logical size so exports are consistent.
class _Poster extends StatelessWidget {
  final PromoItem item;
  final String hostName;
  final bool story;
  const _Poster({required this.item, required this.hostName, required this.story});

  @override
  Widget build(BuildContext context) {
    const w = 360.0;
    final h = story ? 640.0 : 360.0;
    final imageH = story ? 340.0 : 200.0;
    final cta = switch (item.kind) {
      'vehicle' => 'Rent now',
      'tour' => 'Book this tour',
      _ => 'Book your stay',
    };
    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.noScaling),
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: w,
          height: h,
          child: Column(children: [
            SizedBox(
              height: imageH,
              width: w,
              child: Stack(fit: StackFit.expand, children: [
                _NetImage(item.imageUrl),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _brandColor, borderRadius: BorderRadius.circular(20)),
                    child: const Text(_brand,
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(10)),
                    child: Text(item.priceLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: story ? 24 : 18, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.1)),
                      const SizedBox(height: 4),
                      if (item.location.isNotEmpty)
                        Row(children: [
                          const Icon(Icons.location_on, size: 13, color: Colors.redAccent),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                          ),
                        ]),
                      Text('Hosted by $hostName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                      if (story) ...[
                        const SizedBox(height: 14),
                        const Text('✅ Instant online booking\n✅ Verified host\n✅ Pay at pickup',
                            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: _brandColor, borderRadius: BorderRadius.circular(10)),
                        child: Text('$cta on $_brand →',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    QrImageView(data: item.link, size: story ? 110 : 92, padding: EdgeInsets.zero),
                    const SizedBox(height: 3),
                    const Text('Scan to book', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
