import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';

// Conditionally register iframe element for Flutter Web
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class InAppWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String title;

  const InAppWebViewScreen({
    super.key,
    this.initialUrl = 'https://ik.imagekit.io/hsqoovxu0',
    this.title = 'In-App Web Portal',
  });

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  late TextEditingController _urlController;
  late String _currentUrl;
  bool _isLoading = false;
  String _viewType = 'iframe-web-portal';

  final List<Map<String, String>> _presets = [
    {'name': 'ImageKit CDN', 'url': 'https://ik.imagekit.io/hsqoovxu0'},
    {'name': 'ImageKit Console', 'url': 'https://imagekit.io/dashboard'},
    {'name': 'PassOn Ride Web', 'url': 'https://passonride.com'},
    {'name': 'Supabase Portal', 'url': 'https://supabase.com/dashboard'},
    {'name': 'Google Maps', 'url': 'https://maps.google.com'},
  ];

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _urlController = TextEditingController(text: _currentUrl);
    _registerIframe(_currentUrl);
  }

  void _registerIframe(String url) {
    if (kIsWeb) {
      _viewType = 'iframe-${DateTime.now().millisecondsSinceEpoch}';
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = url;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow = 'camera; microphone; geolocation; fullscreen';
        return iframe;
      });
    }
  }

  void _loadUrl(String rawUrl) {
    String formattedUrl = rawUrl.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    setState(() {
      _currentUrl = formattedUrl;
      _urlController.text = formattedUrl;
      _isLoading = true;
      _registerIframe(formattedUrl);
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _launchExternalBrowser() async {
    final uri = Uri.parse(_currentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $_currentUrl'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.language, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Page',
            onPressed: () => _loadUrl(_currentUrl),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in Browser',
            onPressed: _launchExternalBrowser,
          ),
        ],
      ),
      body: Column(
        children: [
          // URL Address Input & Control Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                        ),
                        child: TextField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Enter URL (e.g. https://website.com)...',
                            prefixIcon: Icon(Icons.lock, size: 16, color: Colors.green),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: _loadUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _loadUrl(_urlController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Go', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Quick Preset Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _presets.map((preset) {
                      final isSelected = _currentUrl == preset['url'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(preset['name']!),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) _loadUrl(preset['url']!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const LinearProgressIndicator(color: AppColors.primary, minHeight: 3),

          // Main Embedded Web View Viewport
          Expanded(
            child: kIsWeb
                ? HtmlElementView(key: ValueKey(_viewType), viewType: _viewType)
                : Container(
                    width: double.infinity,
                    color: isDark ? Colors.black : Colors.grey.shade100,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.public, size: 64, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Web View Loaded',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _launchExternalBrowser,
                          icon: const Icon(Icons.open_in_browser, color: Colors.white),
                          label: const Text('Open Website in External Browser', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
