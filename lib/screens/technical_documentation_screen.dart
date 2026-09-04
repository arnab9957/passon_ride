import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/language_provider.dart';
import '../widgets/native_language_selector_dialog.dart';
import '../widgets/tr_text.dart';

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
  late String _videoViewType;

  final List<Map<String, dynamic>> _sections = [
    {
      'title': '1. Getting Started',
      'icon': Icons.explore_outlined,
    },
    {
      'title': '2. Vehicle Booking',
      'icon': Icons.car_rental_outlined,
    },
    {
      'title': '3. Hosting Guide',
      'icon': Icons.directions_car_outlined,
    },
    {
      'title': '4. Guided Tour Hosting',
      'icon': Icons.tour_outlined,
    },
    {
      'title': '5. Safety & Trust',
      'icon': Icons.verified_user_outlined,
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

  void _openLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NativeLanguageSelectorDialog(),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final activeLang = langProvider.activeLanguage;

    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumb / Topic indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Text(
                  'USER GUIDE v2.4',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 4),
              TrText(
                _sections[_selectedIndex]['title'] as String,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),

          // App Translator Button
          InkWell(
            onTap: () => _openLanguageModal(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.g_translate_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${activeLang.flagEmoji} ${activeLang.nativeName}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      activeLang.code.toUpperCase(),
                      style: GoogleFonts.firaCode(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: isDark ? Colors.white60 : Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(isDark),
                        _buildSelectedContent(isDark),
                      ],
                    ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(isDark),
                        _buildSelectedContent(isDark),
                      ],
                    ),
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
            child: TrText(
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
                      title: TrText(
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
          const SizedBox(height: 12),
          // Sidebar App Translator Widget
          Consumer<LanguageProvider>(
            builder: (context, langProvider, _) {
              final active = langProvider.activeLanguage;
              return InkWell(
                onTap: () => _openLanguageModal(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerLowDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.g_translate_rounded, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TrText(
                              'App Translator',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '${active.flagEmoji} ${active.nativeName}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.unfold_more, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTabs(bool isDark) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final active = langProvider.activeLanguage;

    return Container(
      height: 52,
      color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: TrText(_sections[index]['title'] as String),
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
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _openLanguageModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.g_translate_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${active.flagEmoji} ${active.code.toUpperCase()}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedContent(bool isDark) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewSection(isDark);
      case 1:
        return _buildVehicleBookingSection(isDark);
      case 2:
        return _buildHostingSection(isDark);
      case 3:
        return _buildTourHostingSection(isDark);
      case 4:
        return _buildSafetyTrustSection(isDark);
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
          title: 'Welcome & Platform Overview',
          description: 'PassionRide is India\'s premier mobility ecosystem connecting travelers, vehicle owners, and adventure enthusiasts. Whether you want to rent a vehicle for a road trip, monetize your idle personal vehicle, or lead guided group motorcycle convoys, PassionRide delivers a seamless, secure journey.',
        ),
        const SizedBox(height: 20),

        // About the Project Banner Card
        _buildAboutProjectBanner(isDark),
        const SizedBox(height: 32),

        TrText(
          'Core Platform Services',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth >= 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.car_rental,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: '🚗 Self-Drive Vehicle Rentals',
                  body: 'Browse verified cars, superbikes, cruisers, and EVs nearby. Enjoy instant booking, transparent pricing, flexible rental durations, and digital keyless pickup.',
                  isDark: isDark,
                ),
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFA855F7), // Purple
                  title: '💰 Vehicle Hosting & Passive Income',
                  body: 'Transform your parked vehicle into an earning asset. Automated insurance protection, strict renter KYC, and IoT tracking keep your vehicle safe and covered.',
                  isDark: isDark,
                ),
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.tour_outlined,
                  iconColor: const Color(0xFFEC4899), // Pink
                  title: '🗺️ Guided Adventure Tours',
                  body: 'Join curated convoy rides led by seasoned tour marshals, or publish your own custom tour itinerary with safety escorts, mechanic backups, and group billing.',
                  isDark: isDark,
                ),
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF10B981), // Green
                  title: '🛡️ Kinetic Trust™ Safety Framework',
                  body: 'Every member is verified through automated driving license and government ID OCR. Transparent trust ratings and 24/7 roadside assistance guarantee peace of mind.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        TrText(
          'Why PassionRide? Innovation & Trust Pillars',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 650;
            final double cardWidth = isMultiCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.document_scanner_outlined,
                  iconColor: const Color(0xFF06B6D4),
                  title: '60-Second Automated KYC',
                  description: 'Automated on-device and cloud OCR verifies Driving Licenses and government IDs instantly, removing friction and manual gatekeeping.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.lock_outline,
                  iconColor: const Color(0xFFA855F7),
                  title: 'Bank-Grade Escrow Protection',
                  description: 'Security deposits and rental charges are protected in institutional escrow, guaranteeing automatic timely refunds and host payouts.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.sensors,
                  iconColor: const Color(0xFF10B981),
                  title: 'IoT Telematics & Keyless Unlock',
                  description: 'Unlock vehicles with Bluetooth or GPS smart commands without physical keys, while telemetry tracks battery health and tire pressure.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.smart_toy_outlined,
                  iconColor: const Color(0xFFFBBF24),
                  title: 'IRSARGO AI Assistant Support',
                  description: 'Tap our context-aware floating AI companion anytime for vehicle specifications, highway rules, regional weather, or instant support.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutProjectBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B).withOpacity(0.55), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF6366F1).withOpacity(0.35) : const Color(0xFFC7D2FE),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TrText(
                          'About Passion Ride',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                          child: Text(
                            'PASS-ON RIDE',
                            style: GoogleFonts.firaCode(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    TrText(
                      'Decentralized Peer-to-Peer Mobility & Experiential Tourism Ecosystem',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TrText(
            'PassionRide was born from a fundamental mobility insight: in India, over 85% of privately-owned vehicles remain parked idle for upwards of 20 hours every day, losing value through rapid depreciation, fixed insurance costs, and maintenance fees. Meanwhile, millions of passionate explorers, weekend travelers, and daily commuters face exorbitant cab fares or inflexible rental contracts.\n\nOur platform eliminates this friction by connecting verified local vehicle owners with respectful renters and adventure seekers. Powered by automated AI/OCR regulatory verification, IoT-enabled keyless smart locks, and institutional escrow financial safety, PassionRide empowers anyone to rent safely, earn passive income, or lead organized convoy adventures across India\'s most scenic trails.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final width = isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildMissionPill(
                    width: width,
                    icon: Icons.flag_outlined,
                    iconColor: const Color(0xFF06B6D4),
                    title: 'Our Mission',
                    description: 'Democratize personal vehicle ownership into accessible, on-demand mobility for all.',
                    isDark: isDark,
                  ),
                  _buildMissionPill(
                    width: width,
                    icon: Icons.lightbulb_outline,
                    iconColor: const Color(0xFFA855F7),
                    title: 'Our Vision',
                    description: 'Build India\'s largest community of verified hosts, passionate riders, and tour leaders.',
                    isDark: isDark,
                  ),
                  _buildMissionPill(
                    width: width,
                    icon: Icons.handshake_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'Core Values',
                    description: 'Zero hidden charges, bank-grade escrow protection, and uncompromising trip safety.',
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissionPill({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              TrText(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TrText(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
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
                ),
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
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          TrText(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TrText(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. VEHICLE BOOKING GUIDE ---
  Widget _buildVehicleBookingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Vehicle Booking Guide',
          description: 'Renting a vehicle on PassionRide is quick, transparent, and completely digital. Follow this step-by-step walkthrough to discover, verify, book, and return vehicles safely.',
        ),
        const SizedBox(height: 20),

        // Feature Highlight Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 650;
            final double cardWidth = isMultiCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: 'Live Geolocation Map',
                  description: 'Locate available vehicles parked within walking distance of your current location or drop a custom pin anywhere on the live interactive map.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.security,
                  iconColor: const Color(0xFF10B981), // Green
                  title: 'Escrow Protection & Zero Hidden Fees',
                  description: 'Rental fares and security deposits are held in institutional escrow. Your deposit is automatically refunded within hours of trip completion.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        TrText(
          'Step-by-Step Booking Workflow',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _buildTimelineStep(
          stepNumber: '1',
          title: 'Discover & Filter Vehicles Nearby',
          body: 'Open the Discovery Map (DiscoveryScreen) or marketplace feed. Filter listings across Hatchbacks, Sedans, SUVs, Superbikes, Cruisers, Scooters, and Electric Vehicles (EVs). Select Automatic or Manual, Petrol, Diesel, or Electric range.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '2',
          title: 'Review Vehicle Details & Host Trust Score',
          body: 'Tap on any vehicle card to inspect daylight photos of the exterior, cockpit, and storage. Review the host\'s Kinetic Trust Score, verified host badges, completed trips, and amenities like Bluetooth audio and complimentary helmets.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '3',
          title: 'Configure Trip Dates & Pickup Method',
          body: 'Select pickup date/time and drop-off date/time. Multi-day trips frequently receive automatic discounts of 15% to 25%. Choose between self-pickup at the host\'s curbside pin or select Doorstep Delivery.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '4',
          title: 'Instant KYC & Driving License Verification',
          body: 'First-time renters complete a swift 60-second automated verification. Upload a clear photo of your valid Driving License (DL). Automated OCR validates license class permissions (LMV for cars, MCWG for geared bikes).',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '5',
          title: 'Transparent Fare Breakdown & Escrow Payment',
          body: 'Review the transparent fare breakdown with zero hidden charges: Base Rental Rate + Insurance Protection + Refundable Security Deposit. Pay securely via UPI, Credit/Debit Cards, or NetBanking.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '6',
          title: 'Pickup & Keyless Smart Lock Unlock',
          body: 'On trip day, use pedestrian map routing to reach the vehicle. Unlock keylessly via Bluetooth if equipped with PassionRide IoT Smart Lock, or meet the host. Complete the mandatory Pre-Trip Photo Inspection by snapping 4 exterior photos and recording initial odometer and fuel level.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '7',
          title: 'On the Road: Navigation & 24/7 Roadside Assistance',
          body: 'Enjoy unlimited freedom with built-in navigation, in-app host chat, and one-tap emergency SOS roadside assistance for flat tires, jumpstarts, or towing.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '8',
          title: 'Vehicle Return & Automated Deposit Release',
          body: 'Park at the designated return pin with matching fuel level, take post-trip photos, and tap "End Trip & Lock". Your refundable security deposit is automatically released to your original payment method within 2-4 hours.',
          isDark: isDark,
          isLast: true,
        ),
        const SizedBox(height: 28),

        // Renter Best Practices
        TrText(
          'Renter Best Practices Checklist',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 650;
            final double cardWidth = isMultiCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.camera_alt_outlined,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: 'Thorough Pre-Trip Photos',
                  description: 'Always photograph all four sides and wheels during pickup. The app stores timestamps in the cloud to protect you against damage claims.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.local_gas_station_outlined,
                  iconColor: const Color(0xFFA855F7), // Purple
                  title: 'Fair Fuel Matching',
                  description: 'Return the vehicle with the same fuel or charge level you received to avoid host refueling convenience surcharges.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.schedule_outlined,
                  iconColor: const Color(0xFF10B981), // Green
                  title: 'Punctual Returns & Extensions',
                  description: 'If running behind schedule due to traffic, request an in-app extension at least 1 hour before scheduled drop-off.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFFBBF24), // Amber
                  title: 'Official In-App Messaging',
                  description: 'Always communicate with the host via PassionRide chat to maintain a verified record of agreements regarding parking pins or keys.',
                  isDark: isDark,
                ),
              ],
            );
          },
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
              TrText(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TrText(
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
                      Text(
                        linkText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. HOSTING GUIDE ---
  Widget _buildHostingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Vehicle Onboarding & Hosting Guide',
          description: 'This technical guide provides an exhaustive, step-by-step onboarding walkthrough for new users and fleet operators listing a vehicle on PassionRide. Follow this pipeline to configure vehicle details, verify regulatory documents with automated OCR, pair IoT hardware, and publish to the live peer-to-peer marketplace.',
        ),
        const SizedBox(height: 20),

        // Feature Highlight Cards (Responsive)
        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 650;
            final double cardWidth = isMultiCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.document_scanner_outlined,
                  iconColor: AppColors.primary,
                  title: 'AI/OCR Compliance',
                  description: 'Real-time automated scanning of RC, insurance, and challan clearances with auto-filled metadata.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.sensors,
                  iconColor: Colors.purpleAccent,
                  title: 'IoT & Smart Lock',
                  description: 'Digital keyless locks, live GPS tracking, TPMS tire pressure monitoring, and battery/fuel analytics.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Video Walkthrough Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TrText(
              'Video Walkthrough: Host Listing Wizard',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            InkWell(
              onTap: () async {
                final uri = Uri.parse('https://youtu.be/0GJHrcNsFHo');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  Text(
                    'Open on YouTube',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new, size: 13, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          height: 360,
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
        const SizedBox(height: 32),

        // Step-by-Step Workflow Heading
        TrText(
          'Step-by-Step Hosting Workflow for New Users',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TrText(
          'Follow these numbered steps to list and launch your vehicle on the platform:',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 24),

        // Timeline Steps
        _buildTimelineStep(
          stepNumber: '1',
          title: 'Pre-Listing: Account Onboarding & Kinetic Trust KYC',
          body: 'Sign in via native email or Google OAuth. Ensure your legal name, phone number, and avatar are saved. Navigate to DocumentsComplianceScreen to upload a Govt ID or Driving License to earn the Kinetic Trust Verified Host badge.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '2',
          title: 'Navigate to the Host Listing Wizard',
          body: 'Open the bottom navigation or sidebar and tap Host Fleet Dashboard (ProviderDashboardScreen, Index 8). Tap "Register New Vehicle" or "+" to open the 6-step Listing Wizard (RegisterVehicleScreen, Index 10).',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '3',
          title: 'Fill Basic Vehicle Information & Geolocation',
          body: 'Enter Make & Model (e.g. Bajaj Pulsar N250), category (Motorcycle, Scooter, Car, SUV, Electric), VIN / Plate number, and rental description. Set the pickup pin using "Use Live GPS" or "Pick Pin on Map" (InteractiveMapPinPicker).',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '4',
          title: 'Curate Vehicle Photo Gallery & Cloud CDN Sync',
          body: 'Select high-resolution photos using multi-image gallery picker or camera capture. Tap any photo to set it as the primary cover photo. Images are asynchronously uploaded to ImageKit Cloud CDN (/vehicles) for fast loading.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '5',
          title: 'Configure Specifications, Fuel & Seating',
          body: 'Set Fuel Type (Petrol, Diesel, Electric, Hybrid), Transmission (Manual, Automatic), and passenger seating capacity. Selecting Electric automatically enables EV battery SoC indicators.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '6',
          title: 'Set Rental Rates & Instant Booking Policy',
          body: 'Set your daily rental rate in INR (₹) or USD (\$). Toggle Instant Booking ON so verified renters can book immediately without waiting for manual host approval.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '7',
          title: 'Pair IoT Telematics & Keyless Digital Smart Lock',
          body: 'Pair vehicle OBD-II or GPS telematics module. The app initializes real-time telemetry (smart lock state, engine status, battery SoC, odometer, TPMS front/rear PSI). Test connectivity with the "Test Lock" action button.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '8',
          title: 'Upload & Verify Mandatory Regulatory Documents (AI/OCR)',
          body: 'Upload Registration Certificate (RC), Challan Clearance, and Insurance Policy scans (PDF/JPG). Built-in DocumentOcrService automatically scans and parses document numbers and expiry dates in real time.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '9',
          title: 'Publish Listing & Instant Marketplace Activation',
          body: 'Tap "Publish Vehicle Listing". The listing is saved to the Supabase "vehicles" table with Row Level Security (RLS) linked to your hostId. It appears immediately on the live Discovery map and category search feeds.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '10',
          title: 'Post-Listing: Fleet Management & Earnings Payouts',
          body: 'Use ProviderDashboardScreen to toggle availability (Available, In Service, Rented, Maintenance). Verify handovers via QR code/PIN in BookingVerificationScreen, track telemetry in TelematicsHubScreen, and withdraw earnings in EarningsScreen.',
          isDark: isDark,
          isLast: true,
        ),
        const SizedBox(height: 28),

        // Host Operational Checklist Cards
        TrText(
          'Host Best Practices & Operational Checklist',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 650;
            final double cardWidth = isMultiCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.camera_alt_outlined,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: 'Crisp Photography',
                  description: 'Upload at least 4 bright daylight photos (front, side, cockpit, helmet/trunk) to boost bookings by 40%.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFA855F7), // Purple
                  title: 'Precise Pickup Pin',
                  description: 'Drop the map pin at the exact curbside or parking spot so renters find the vehicle easily.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF10B981), // Green
                  title: 'Keep Docs Active',
                  description: 'Renew insurance and RC at least 15 days before expiry to avoid automated listing suspension.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFFBBF24), // Amber
                  title: 'Fast Response Rate',
                  description: 'Reply to guest inquiries within 15 mins via in-app chat to maximize your Kinetic Trust score.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildChecklistCard({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowestDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TrText(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TrText(
            description,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. GUIDED TOUR HOSTING GUIDE ---
  Widget _buildTourHostingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Guided Tour Hosting Guide',
          description: 'Turn your passion for travel, motorcycling, and route exploration into an organized business. Publish curated group adventures, manage rider rosters, and collect secure bookings with escrow protection.',
        ),
        const SizedBox(height: 20),

        // Feature Highlight Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 650;
            final double cardWidth = isMultiCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.explore_outlined,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: 'Convoy Coordination & Live Roster',
                  description: 'Publish multi-stop itineraries with waypoint checkpoints, mandatory safety gear requirements, and live participant rosters with rider group chat.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFFA855F7), // Purple
                  title: 'Guaranteed Escrow Payouts',
                  description: 'Participant fees are secured in platform escrow when riders book. Payouts are transferred automatically to your registered bank account upon tour completion.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        TrText(
          'Step-by-Step Tour Creation Workflow',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        _buildTimelineStep(
          stepNumber: '1',
          title: 'Access the Tour Registration Wizard',
          body: 'Open the navigation menu and select Register Guided Tour (RegisterTourScreen, Index 11) or tap "Host Tour" from the Provider Dashboard. Use the AI Tour Generator (AiTourGeneratorScreen) to brainstorm routes.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '2',
          title: 'Define Tour Title, Theme & Category',
          body: 'Choose from Mountain Passes, Coastal Cruises, Off-Road Dirt Trails, Heritage & Cultural Rides, or Weekend Breakfast Getaways. Upload a striking landscape photo showing the scenic destination or convoy formation.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '3',
          title: 'Map Out Itinerary, Waypoints & Checkpoints',
          body: 'Define the exact GPS departure spot, scheduled rest stops, scenic viewpoints, breakfast/lunch halts, and fuel refill stations. Provide total kilometers and estimated daily riding hours.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '4',
          title: 'Set Convoy Capacity, Dates & Terrain Difficulty',
          body: 'Specify minimum and maximum rider limits (e.g. 8–15 riders to keep convoys manageable). Set departure date and rate terrain difficulty: Beginner-Friendly, Intermediate, or Advanced/Pro.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '5',
          title: 'Specify Vehicle Eligibility & Mandatory Safety Gear',
          body: 'State whether riders Bring Their Own Vehicle (BYOV) or if rental vehicle packages are available. Clearly mandate ISI/DOT full-face helmets, armored jackets, knee guards, riding boots, and gloves.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '6',
          title: 'Transparent Pricing & Package Inclusions',
          body: 'Set registration fee in INR (₹) or USD (\$). Checkmark package inclusions: Safety Marshal Escort, Support Sweep Vehicle, Luggage Transfer, Meals, Puncture Repair Backup, First-Aid Kit, and Action Photos.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '7',
          title: 'Convoy Safety Protocols & In-Trip Communication',
          body: 'Assign Lead and Sweep riders to maintain steady pace and assist stragglers. Confirmed riders are automatically added to the private in-app Tour Group Chat for coordination and packing checklists.',
          isDark: isDark,
        ),
        _buildTimelineStep(
          stepNumber: '8',
          title: 'Publish Tour & Manage Confirmed Riders',
          body: 'Tap "Publish Guided Tour". Your tour appears on the Discover Tours feed. Track registrations and participant trust scores. On tour completion, mark it finished to receive bank payouts via UPI or NEFT.',
          isDark: isDark,
          isLast: true,
        ),
        const SizedBox(height: 28),

        // Tour Host Best Practices
        TrText(
          'Tour Host Best Practices & Convoy Safety',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMultiCol = constraints.maxWidth >= 650;
            final double cardWidth = isMultiCol ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.alt_route_outlined,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: 'Pre-Ride Route Reconnaissance',
                  description: 'Always pre-scout your itinerary within 7 days of departure to check for unexpected road closures, monsoon landslides, or detour conditions.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.campaign_outlined,
                  iconColor: const Color(0xFFA855F7), // Purple
                  title: 'Mandatory Pre-Departure Briefing',
                  description: 'Review stagger riding formation, braking distances, hand signals (hazard left/right, slowdown, single file), and overtaking etiquette.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.build_circle_outlined,
                  iconColor: const Color(0xFF10B981), // Green
                  title: 'Sweep Vehicle & Tool Support',
                  description: 'For tours exceeding 100km, arrange a sweep vehicle carrying tubeless puncture kits, portable 12V inflators, jumpstart cables, and spare fuel.',
                  isDark: isDark,
                ),
                _buildChecklistCard(
                  width: cardWidth,
                  icon: Icons.military_tech_outlined,
                  iconColor: const Color(0xFFFBBF24), // Amber
                  title: 'Build Rider Loyalty & Badges',
                  description: 'Take high-quality group photos at scenic viewpoints and share them in the tour chat to earn repeat riders who boost your trust rating.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- 5. SAFETY & TRUST SECTION ---
  Widget _buildSafetyTrustSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Safety, Trust & Support Ecosystem',
          description: 'Community safety is our paramount priority. Every booking, host vehicle listing, and guided tour is shielded by automated verification, bank-grade escrow, and 24/7 emergency response infrastructure.',
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
                  iconColor: const Color(0xFF10B981), // Green
                  title: 'Kinetic Trust™ Scoring',
                  body: 'A multi-factor reputation algorithm that computes user trust scores from verified government KYC, trip completion history, prompt communication, and genuine reviews.',
                  isDark: isDark,
                ),
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.lock_outline,
                  iconColor: const Color(0xFFA855F7), // Purple
                  title: 'Automated Escrow Protection',
                  body: 'Rental fees, security deposits, and tour bookings are secured in institutional escrow. Hosts receive payouts seamlessly after trip conclusion; security deposits refund automatically.',
                  isDark: isDark,
                ),
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.emergency_outlined,
                  iconColor: const Color(0xFFEF4444), // Red
                  title: '24/7 Emergency SOS & Roadside Help',
                  body: 'Encountered a flat tire, dead battery, or breakdown? Tap the emergency SOS button on your active trip screen for immediate dispatch of on-site recovery mechanics or towing.',
                  isDark: isDark,
                ),
                _buildOverviewCard(
                  width: cardWidth,
                  icon: Icons.smart_toy_outlined,
                  iconColor: const Color(0xFF06B6D4), // Cyan
                  title: 'IRSARGO AI Assistant Support',
                  body: 'Tap the floating IRSARGO AI assistant in the bottom corner of any screen to get real-time context-aware answers regarding vehicle specs, booking policies, or local driving laws.',
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required String description}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrText(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        TrText(
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
