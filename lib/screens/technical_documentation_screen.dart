import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

// Conditionally register iframe element for Flutter Web
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class TechnicalDocumentationScreen extends StatefulWidget {
  const TechnicalDocumentationScreen({super.key});

  @override
  State<TechnicalDocumentationScreen> createState() => _TechnicalDocumentationScreenState();
}

class _TechnicalDocumentationScreenState extends State<TechnicalDocumentationScreen> {
  int _selectedIndex = 0;
  int _architectureTabIndex = 0;
  final Map<String, bool> _copiedStatus = {};
  late String _videoViewType;

  final List<Map<String, dynamic>> _sections = [
    {
      'title': '1. Overview',
      'icon': Icons.info_outline,
    },
    {
      'title': '2. System Architecture',
      'icon': Icons.account_tree_outlined,
    },
    {
      'title': '3. Data Model Safety',
      'icon': Icons.security,
    },
    {
      'title': '4. OAuth Workflows',
      'icon': Icons.lock_open_outlined,
    },
    {
      'title': '5. Telematics System',
      'icon': Icons.sensors_outlined,
    },
    {
      'title': '6. Hosting Guide',
      'icon': Icons.directions_car_outlined,
    },
    {
      'title': '7. Codebase Map',
      'icon': Icons.folder_open_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _videoViewType = 'youtube-video-iframe-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(_videoViewType, (int viewId) {
        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = 'https://www.youtube.com/embed/0GJHrcNsFHo';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share';
        iframe.allowFullscreen = true;
        return iframe;
      });
    }
  }

  void _copyToClipboard(String text, String key) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedStatus[key] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedStatus[key] = false;
        });
      }
    });
  }

  List<TextSpan> _highlightDartCode(String code, bool isDark) {
    final List<TextSpan> spans = [];
    final keywordColor = const Color(0xFFEC4899); // Pink
    final typeColor = const Color(0xFF06B6D4); // Cyan
    final stringColor = const Color(0xFFFBBF24); // Gold/Amber
    final commentColor = const Color(0xFF10B981); // Green
    final defaultColor = isDark ? Colors.white : Colors.black87;

    final lines = code.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('//')) {
        spans.add(TextSpan(text: line, style: TextStyle(color: commentColor)));
      } else {
        final regExp = RegExp(
            r'(\b(double|int|bool|dynamic|value|defaultValue|null|if|return|is|const|final|void|import|class|static|extends|super)\b|"(?:[^"\\]|\\.)*"|\/\/.*|\S+|\s+)');
        final matches = regExp.allMatches(line);
        for (final match in matches) {
          final text = match.group(0) ?? '';
          if (text.startsWith('//')) {
            spans.add(TextSpan(text: text, style: TextStyle(color: commentColor)));
          } else if (text == 'double' || text == 'int' || text == 'bool' || text == 'dynamic') {
            spans.add(TextSpan(text: text, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold)));
          } else if (text == 'if' || text == 'return' || text == 'is' || text == 'null') {
            spans.add(TextSpan(text: text, style: TextStyle(color: keywordColor, fontWeight: FontWeight.bold)));
          } else if (text.startsWith('"') || text.startsWith("'")) {
            spans.add(TextSpan(text: text, style: TextStyle(color: stringColor)));
          } else {
            spans.add(TextSpan(text: text, style: TextStyle(color: defaultColor)));
          }
        }
      }
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Navigation Sidebar
                _buildSidebar(isDark),
                // Vertical Divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
                // Right Detail View Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: _buildSelectedContent(isDark),
                  ),
                ),
              ],
            );
          } else {
            // Mobile & Tablet Responsive View
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal navigation chips
                _buildHorizontalTabs(isDark),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
                // Main Detail Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: _buildSelectedContent(isDark),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 280,
      color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 16),
            child: Text(
              'DOCUMENTATION TOPICS',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final activeColor = AppColors.primary;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(
                        _sections[index]['icon'] as IconData,
                        color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black54),
                        size: 20,
                      ),
                      title: Text(
                        _sections[index]['title'] as String,
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13.5,
                          color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTabs(bool isDark) {
    return Container(
      height: 52,
      color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_sections[index]['title'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedContent(bool isDark) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewSection(isDark);
      case 1:
        return _buildArchitectureSection(isDark);
      case 2:
        return _buildModelSafetySection(isDark);
      case 3:
        return _buildOAuthSection(isDark);
      case 4:
        return _buildTelematicsSection(isDark);
      case 5:
        return _buildHostingSection(isDark);
      case 6:
        return _buildCodebaseMapSection(isDark);
      default:
        return _buildOverviewSection(isDark);
    }
  }

  // --- 1. OVERVIEW ---
  Widget _buildOverviewSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'System Overview',
          description: 'PassionRide is a premium Peer-to-Peer (P2P) bike and car leasing platform. The architecture is optimized for low-latency synchronization of real-time GPS coordinates, robust security frameworks, and seamless cloud integrations.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth >= 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: 'Robust Authentication',
                  body: 'Secured with Supabase identity wrappers, supporting native username/password auth alongside Google OAuth utilizing a hybrid pop-up callback framework.',
                  isDark: isDark,
                ),
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.sensors,
                  iconColor: const Color(0xFFA855F7), // Purple
                  title: 'Live Telematics',
                  body: 'Real-time vehicle tracking pipeline connected to GPS coordinates, TPMS sensors, fuel levels, engine lock controls, and OBD-II diagnostics logging.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. ARCHITECTURE ---
  Widget _buildArchitectureSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'System Architecture',
          description: 'The platform follows a distributed core architecture that separates interface orchestration, telemetry persistence, and asynchronous operations.',
        ),
        const SizedBox(height: 24),
        // Custom Tab Selector
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerLowestDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  title: 'Frontend Layer',
                  isSelected: _architectureTabIndex == 0,
                  isDark: isDark,
                  onTap: () => setState(() => _architectureTabIndex = 0),
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  title: 'Backend Infrastructure',
                  isSelected: _architectureTabIndex == 1,
                  isDark: isDark,
                  onTap: () => setState(() => _architectureTabIndex = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _architectureTabIndex == 0
              ? _buildFrontendTab(isDark)
              : _buildBackendTab(isDark),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryContainer : AppColors.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontendTab(bool isDark) {
    return Column(
      key: const ValueKey('frontend'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frontend Layer Architecture',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The client application is built entirely using Flutter. State is managed globally via ChangeNotifierProvider inside app_state.dart, which acts as the data hub coordinating Supabase queries, Realtime channels, push notifications, and geolocator APIs.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildBulletItem(
          icon: Icons.phone_android,
          iconColor: Colors.blueAccent,
          title: 'Interface Engine',
          body: 'Material Design 3 rendering engine utilizing responsive breakpoints to adjust typography, margins, and layouts between phones, tablets, and web views.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildBulletItem(
          icon: Icons.map_outlined,
          iconColor: Colors.green,
          title: 'Real-time Providers',
          body: 'Google Maps layers displaying dynamically refreshed driver coordinates, geocoded address lookups, and active cluster marker rendering.',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBackendTab(bool isDark) {
    return Column(
      key: const ValueKey('backend'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backend Infrastructure Responsibilities',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The application operates in a hybrid serverless model, delegating relational operations to Supabase and telemetry/notification pushes to Firebase.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildBulletItem(
          icon: Icons.storage,
          iconColor: const Color(0xFF10B981), // Supabase Green
          title: 'Supabase (Core Backend)',
          body: 'Handles PostgreSQL relational storage, Row-Level Security (RLS) policies, PostGIS spatial queries, secure JWT verification, and Google OAuth callback redirects.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildBulletItem(
          icon: Icons.campaign_outlined,
          iconColor: const Color(0xFFFBBF24), // Firebase Yellow
          title: 'Firebase (Push Service)',
          body: 'Orchestrates the Firebase Core App initialization and handles downstream background pushes through Firebase Cloud Messaging (FCM) to trigger local triggers.',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBulletItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. MODEL SAFETY ---
  Widget _buildModelSafetySection(bool isDark) {
    const codeString = '''double _parseDouble(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? defaultValue;
}

int _parseInt(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? defaultValue;
}

bool _parseBool(dynamic value, bool defaultValue) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final str = value.toString().toLowerCase();
  return str == 'true' || str == '1' || str == 'yes';
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Data Model Safety',
          description: 'Database responses (especially from dynamic SQL numeric schemas or type-flexible backends) often arrive with unexpected types (e.g. integer fields sent as floating numbers or numeric fields sent as raw string hashes). Direct type casting causes immediate runtime crashes.',
        ),
        const SizedBox(height: 16),
        Text(
          'To prevent these runtime parse errors, the PassionRide model layers process all dynamic mappings through private utility methods located at the top of models.dart:',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildCodeCard(
          code: codeString,
          language: 'models.dart',
          isDark: isDark,
          blockKey: 'model_safety_code',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Every domain model (Vehicle, Tour, Booking) utilizes these parsers, rendering the Flutter client immune to runtime JSON cast exceptions.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodeCard({
    required String code,
    required String language,
    required bool isDark,
    required String blockKey,
  }) {
    final isCopied = _copiedStatus[blockKey] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070913) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyToClipboard(code, blockKey),
                  icon: Icon(
                    isCopied ? Icons.check : Icons.copy_all_outlined,
                    size: 14,
                    color: isCopied ? Colors.green : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  label: Text(
                    isCopied ? 'Copied!' : 'Copy Code',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCopied ? Colors.green : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText.rich(
                TextSpan(
                  children: _highlightDartCode(code, isDark),
                ),
                style: GoogleFonts.firaCode(
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. OAUTH FLOW ---
  Widget _buildOAuthSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Google OAuth Hybrid Popup Flow',
          description: 'In development, traditional OAuth redirection often resets web debug compiles. Opening redirect interfaces within the client breaks execution states and generates origin mismatch alerts.',
        ),
        const SizedBox(height: 16),
        Text(
          'To bypass this, PassionRide implements a secure Hybrid Popup-Redirect synchronization flow:',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        _buildTimelineStep(
          stepNumber: '1',
          title: 'Initiate Auth Request',
          body: 'The client triggers the Supabase authentication handler, opening a browser popup window pointing directly to the OAuth server.',
          isDark: isDark,
          linkText: 'Supabase OAuth Authorize API Endpoint',
          linkUrl: 'https://gxqlsogewjjkcdetubuv.supabase.co/auth/v1/authorize?provider=google&redirect_to=${Uri.base.origin}',
        ),
        _buildTimelineStep(
          stepNumber: '2',
          title: 'Google Consent Verification',
          body: 'Google evaluates the request. Since the redirect origin points to the registered Supabase endpoint, Google serves the OAuth Consent chooser page inside the popup without warnings.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '3',
          title: 'Local Callback Resolution',
          body: 'Upon authorization, Google routes back to Supabase, which forwards the callback details (JWT access and refresh tokens inside the hash fragment) directly back to the parent tab\'s origin.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '4',
          title: 'State Sync & Window Disposal',
          body: 'The popup page loads the client callback script, initializes the Supabase package which writes tokens to shared local storage, updating the parent tab instantaneously. The popup window closes itself.',
          isDark: isDark,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String stepNumber,
    required String title,
    required String body,
    required bool isDark,
    String? linkText,
    String? linkUrl,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                stepNumber,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 70,
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              if (linkText != null && linkUrl != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(linkUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 14, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                      Text(
                        linkText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // --- 5. TELEMATICS ---
  Widget _buildTelematicsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Telematics & Real-Time Tracking',
          description: 'The IoT telematics subsystem monitors active leased vehicles. Telemetry logs persist engine state details, tire pressure (TPMS), fuel levels, and GPS tracking coordinates.',
        ),
        const SizedBox(height: 24),
        Text(
          'Simulated Real-Time Sensor Telemetry',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth >= 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildSensorCard(
                  width: cardWidth,
                  title: 'GPS Coordinates',
                  value: '37.7749° N, 122.4194° W',
                  subText: 'San Francisco, CA (Active Lock)',
                  icon: Icons.my_location,
                  iconColor: Colors.blue,
                  isDark: isDark,
                ),
                _buildSensorCard(
                  width: cardWidth,
                  title: 'Battery / Fuel Level',
                  value: '84% SoC',
                  subText: 'Charging status: Idle (Optimal)',
                  icon: Icons.battery_charging_full,
                  iconColor: Colors.green,
                  isDark: isDark,
                  progressValue: 0.84,
                ),
                _buildSensorCard(
                  width: cardWidth,
                  title: 'TPMS Sensors',
                  value: 'Front: 36.5 PSI / Rear: 34.2 PSI',
                  subText: 'All tires normal (Safety check OK)',
                  icon: Icons.tire_repair,
                  iconColor: Colors.orange,
                  isDark: isDark,
                ),
                _buildSensorCard(
                  width: cardWidth,
                  title: 'Engine & Lock Control',
                  value: 'Engine: ON / Lock: LOCKED',
                  subText: 'Remote immobilizer connected',
                  icon: Icons.vpn_key_outlined,
                  iconColor: Colors.purple,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Data Schema Reference',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildSchemaTable(isDark),
      ],
    );
  }

  Widget _buildSensorCard({
    required double width,
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    double? progressValue,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (progressValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                color: iconColor,
                backgroundColor: iconColor.withOpacity(0.15),
                minHeight: 6,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            subText,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemaTable(bool isDark) {
    final List<Map<String, String>> schema = [
      {'param': 'latitude / longitude', 'desc': 'GPS coordinates for live tracking map pins.', 'type': 'Double (Safe-parsed)'},
      {'param': 'batterySoc', 'desc': 'Electric battery state of charge percentage value.', 'type': 'Integer (Safe-parsed)'},
      {'param': 'tpmsFrontPsi / tpmsRearPsi', 'desc': 'Tire pressure sensor readout values (PSI).', 'type': 'Double (Safe-parsed)'},
      {'param': 'engineOn / locked', 'desc': 'Safety state markers of the engine ignition and lock status.', 'type': 'Boolean (Safe-parsed)'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
            ),
            children: [
              _buildTableCell('Parameter', isHeader: true, isDark: isDark),
              _buildTableCell('Description', isHeader: true, isDark: isDark),
              _buildTableCell('Type Class', isHeader: true, isDark: isDark),
            ],
          ),
          ...schema.map(
            (item) => TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    width: 0.5,
                  ),
                ),
              ),
              children: [
                _buildTableCell(item['param']!, isDark: isDark, isCode: true),
                _buildTableCell(item['desc']!, isDark: isDark),
                _buildTableCell(item['type']!, isDark: isDark, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isDark = false,
    bool isCode = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: isCode
            ? GoogleFonts.firaCode(
                fontSize: 11.5,
                color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
              )
            : GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isHeader ? FontWeight.bold : (isBold ? FontWeight.w600 : FontWeight.normal),
                color: isHeader
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
      ),
    );
  }

  // --- 6. HOSTING GUIDE ---
  Widget _buildHostingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Vehicle Onboarding & Hosting',
          description: 'This section details the hosting parameters required to list, verify, and make vehicles available for rentals inside the PassionRide application. Watch the tutorial walkthrough below to review the onboarding configuration screen fields.',
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 380,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: kIsWeb
              ? HtmlElementView(viewType: _videoViewType)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_fill, size: 72, color: Colors.white70),
                          const SizedBox(height: 16),
                          Text(
                            'Watch Walkthrough Tutorial',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Youtube Video: Onboarding & Hosting',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final uri = Uri.parse('https://youtu.be/0GJHrcNsFHo');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () async {
            final uri = Uri.parse('https://youtu.be/0GJHrcNsFHo');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Open Video in External Tab'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // --- 7. CODEBASE MAP ---
  Widget _buildCodebaseMapSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Codebase & Documentation Map',
          description: 'This directory index lists key file layouts and documentation files. Use this map to navigate to core model codes, state managers, and key controller structures.',
        ),
        const SizedBox(height: 24),
        Text(
          'Active Documentation Index',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth >= 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildDocCard(
                  width: cardWidth,
                  badgeText: 'Quickstart',
                  badgeColor: Colors.blueAccent,
                  filePath: '/README.md',
                  title: 'README.md Documentation',
                  description: 'Setup guides, environment variable references, pub dependencies download instructions, and launch scripts.',
                  isDark: isDark,
                ),
                _buildDocCard(
                  width: cardWidth,
                  badgeText: 'Backend',
                  badgeColor: Colors.purpleAccent,
                  filePath: '/BACKEND_ARCHITECTURE.md',
                  title: 'Backend Design Schema',
                  description: 'Outlines Supabase-Firebase distribution models, real-time sync listeners, and security policy rules.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Flutter Client Structure Map (lib/)',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildDirectoryMapItem(
          icon: Icons.folder,
          iconColor: const Color(0xFF06B6D4), // Cyan
          dirName: 'lib/models/',
          subTitle: 'State Entities & Data Parsers',
          files: 'models.dart',
          description: 'Constructs database serialization objects (e.g. Vehicle, Tour, ChatMessage) and houses the dynamic casting safety filters.',
          isDark: isDark,
        ),
        _buildDirectoryMapItem(
          icon: Icons.folder,
          iconColor: const Color(0xFFA855F7), // Purple
          dirName: 'lib/providers/',
          subTitle: 'Global App State Engine',
          files: 'app_state.dart',
          description: 'Maintains local state fields via ChangeNotifier, orchestrating Supabase queries, location coordinate lookups, and message inbox updates.',
          isDark: isDark,
        ),
        _buildDirectoryMapItem(
          icon: Icons.folder,
          iconColor: const Color(0xFFEC4899), // Pink
          dirName: 'lib/services/',
          subTitle: 'Cloud Service Adaptors',
          files: 'document_ocr_service.dart, local_storage_service.dart, supabase_service.dart',
          description: 'Interfaces with external APIs, managing Firestore streams, transactional notifications, and document scanner OCR frameworks.',
          isDark: isDark,
        ),
        _buildDirectoryMapItem(
          icon: Icons.folder,
          iconColor: const Color(0xFFFBBF24), // Amber
          dirName: 'lib/screens/',
          subTitle: 'Views & Interface Controllers',
          files: 'discovery_screen.dart, main_navigation_screen.dart, blog_screen.dart...',
          description: 'Coordinates view layout elements. Key components: discovery_screen.dart maps, telematics dashboards, and document upload forms.',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildDocCard({
    required double width,
    required String badgeText,
    required Color badgeColor,
    required String filePath,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              Text(
                filePath,
                style: GoogleFonts.firaCode(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryMapItem({
    required IconData icon,
    required Color iconColor,
    required String dirName,
    required String subTitle,
    required String files,
    required String description,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dirName,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      files,
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subTitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String description}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            height: 1.5,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
