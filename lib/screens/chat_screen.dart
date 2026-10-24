// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../services/whatsapp_launcher_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color kWhatsAppColor = Color(0xFF25D366);
  static const Color kWhatsAppDarkColor = Color(0xFF128C7E);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thread = appState.selectedChatThread ??
        (appState.chatThreads.isNotEmpty ? appState.chatThreads.first : null);

    if (thread == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Host & Customer WhatsApp Support'),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kWhatsAppColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      size: 54,
                      color: kWhatsAppColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Direct WhatsApp Host Channels',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a verified fleet operator or central helpdesk to chat directly on WhatsApp for instantaneous vehicle booking updates, location sharing, and assistance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Contact 1: Puri Adventure Ride
                  _buildDirectHostCard(
                    context: context,
                    isDark: isDark,
                    title: 'Puri Adventure Ride',
                    subtitle: 'Bikes, Scooters, Adventure Tours & Beach Fleet',
                    phoneDisplay: WhatsAppLauncherService.puriAdventureWhatsAppDisplay,
                    rawPhone: WhatsAppLauncherService.puriAdventureWhatsAppNumber,
                    cleanPhone: WhatsAppLauncherService.cleanPuriAdventureWhatsAppNumber,
                    icon: Icons.two_wheeler,
                    avatarColor: Colors.deepOrange,
                    defaultMessage: 'Hello Puri Adventure Ride! I am inquiring about vehicle rental and booking availability in Puri.',
                  ),
                  const SizedBox(height: 12),

                  // Contact 2: Bluewaves Rental
                  _buildDirectHostCard(
                    context: context,
                    isDark: isDark,
                    title: 'Bluewaves Rental',
                    subtitle: 'Self-Drive Bikes, Scooters & Premium Beach Cruisers',
                    phoneDisplay: WhatsAppLauncherService.bluewavesWhatsAppDisplay,
                    rawPhone: WhatsAppLauncherService.bluewavesWhatsAppNumber,
                    cleanPhone: WhatsAppLauncherService.cleanBluewavesWhatsAppNumber,
                    icon: Icons.motorcycle,
                    avatarColor: Colors.blueAccent,
                    defaultMessage: 'Hello Bluewaves Rental! I am inquiring about bike rental and booking availability in Puri.',
                  ),
                  const SizedBox(height: 12),

                  // Contact 3: Central Platform Support
                  _buildDirectHostCard(
                    context: context,
                    isDark: isDark,
                    title: 'PassionRide Central Support',
                    subtitle: 'Customer Care, Payments, Escrow & Host Onboarding',
                    phoneDisplay: WhatsAppLauncherService.hostCustomerWhatsAppDisplay,
                    rawPhone: WhatsAppLauncherService.hostCustomerWhatsAppNumber,
                    cleanPhone: WhatsAppLauncherService.cleanWhatsAppNumber,
                    icon: Icons.support_agent,
                    avatarColor: Colors.teal,
                    defaultMessage: 'Hello PassionRide Support! I need assistance with my rental reservation.',
                  ),
                  const SizedBox(height: 24),

                  // View messages button
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: OutlinedButton.icon(
                      onPressed: () => appState.setNavIndex(6),
                      icon: const Icon(Icons.inbox, size: 18),
                      label: const Text('View All Inbox Conversations'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Resolve specific WhatsApp contact info for the selected thread's host
    final hostNumber = WhatsAppLauncherService.getWhatsAppNumberForHost(thread.partnerName);
    final hostDisplay = WhatsAppLauncherService.getWhatsAppDisplayForHost(thread.partnerName);
    final cleanNumber = WhatsAppLauncherService.getCleanWhatsAppNumberForHost(thread.partnerName);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // WhatsApp-Style Custom Header Bar
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 10, left: 12, right: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => appState.setNavIndex(6),
                ),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(thread.partnerAvatar),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: kWhatsAppColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.surfaceContainerDark : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 7, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.partnerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble, size: 10, color: kWhatsAppColor),
                          const SizedBox(width: 4),
                          Text(
                            hostDisplay,
                            style: const TextStyle(
                              fontSize: 11,
                              color: kWhatsAppColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Vehicle Badge
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        thread.vehicleTitle.length > 14 ? '${thread.vehicleTitle.substring(0, 14)}...' : thread.vehicleTitle,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Open WhatsApp ($hostDisplay)',
                  icon: const Icon(Icons.chat, color: kWhatsAppColor),
                  onPressed: () => _openWhatsApp(
                    context,
                    phoneNumber: cleanNumber,
                    message: 'Hello ${thread.partnerName}! I am contacting you from PassionRide regarding ${thread.vehicleTitle}.',
                  ),
                ),
              ],
            ),
          ),

          // Quick Action Template Chips Bar (Redirects directly to host's WhatsApp with pre-filled message)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('📍 Pickup Location', Icons.my_location, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: cleanNumber,
                      message: 'Hello ${thread.partnerName}! Could you please share the exact pickup location coordinates and landmark for ${thread.vehicleTitle}?',
                    );
                  }),
                  _buildQuickAction('🕘 Pickup Time', Icons.schedule, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: cleanNumber,
                      message: 'Hello ${thread.partnerName}! I would like to confirm my pickup time for ${thread.vehicleTitle}.',
                    );
                  }),
                  _buildQuickAction('📄 Required Docs', Icons.badge, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: cleanNumber,
                      message: 'Hello ${thread.partnerName}! What documents (Driving License / Aadhaar) do I need for ${thread.vehicleTitle}?',
                    );
                  }),
                  _buildQuickAction('🏍️ Bike Details', Icons.two_wheeler, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: cleanNumber,
                      message: 'Hello ${thread.partnerName}! Could you share details regarding helmet and fuel for ${thread.vehicleTitle}?',
                    );
                  }),
                  _buildQuickAction('💬 WhatsApp Now', Icons.chat, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: cleanNumber,
                      message: 'Hello ${thread.partnerName}! I am reaching out regarding ${thread.vehicleTitle} on PassionRide.',
                    );
                  }),
                ],
              ),
            ),
          ),

          // Security & Escrow Protection Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withOpacity(0.12),
              border: Border(bottom: BorderSide(color: Colors.amber.shade800.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🛡️ Verified Support • Host communication with ${thread.partnerName} is powered via WhatsApp ($hostDisplay). Keep booking and payments inside PassionRide.',
                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Main WhatsApp Redirection Section
          Expanded(
            child: _buildWhatsAppRedirectSection(
              context,
              appState,
              thread,
              isDark,
              hostNumber: hostNumber,
              hostDisplay: hostDisplay,
              cleanNumber: cleanNumber,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a verified host direct WhatsApp contact card in the empty state
  Widget _buildDirectHostCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required String phoneDisplay,
    required String rawPhone,
    required String cleanPhone,
    required IconData icon,
    required Color avatarColor,
    required String defaultMessage,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: avatarColor.withOpacity(0.15),
                radius: 20,
                child: Icon(icon, color: avatarColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy Number',
                icon: const Icon(Icons.copy, size: 17, color: AppColors.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: rawPhone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $title WhatsApp ($rawPhone) copied!'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: kWhatsAppDarkColor,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kWhatsAppColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat, color: kWhatsAppColor, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      phoneDisplay,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: kWhatsAppDarkColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openWhatsApp(
                  context,
                  phoneNumber: cleanPhone,
                  message: defaultMessage,
                ),
                icon: const Icon(Icons.send, size: 14),
                label: const Text('Chat WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWhatsAppColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the dedicated WhatsApp Redirection UI between host and customer
  Widget _buildWhatsAppRedirectSection(
    BuildContext context,
    AppState appState,
    ChatThread thread,
    bool isDark, {
    required String hostNumber,
    required String hostDisplay,
    required String cleanNumber,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // WhatsApp Brand Icon Badge
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kWhatsAppColor, kWhatsAppDarkColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kWhatsAppColor.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Chat with ${thread.partnerName}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Direct Host & Customer WhatsApp Communication',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Host WhatsApp Number Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kWhatsAppColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kWhatsAppColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk, color: kWhatsAppColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${thread.partnerName.toUpperCase()} WHATSAPP',
                          style: const TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hostDisplay,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Copy Number',
                      icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: hostNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ WhatsApp number $hostNumber copied to clipboard!'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: kWhatsAppDarkColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Conversation Context Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(thread.partnerAvatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Host: ${thread.partnerName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Listing: ${thread.vehicleTitle}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Verified Host',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Primary Launch WhatsApp Button
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(
                    context,
                    phoneNumber: cleanNumber,
                    message: 'Hello ${thread.partnerName}! I am contacting you from PassionRide regarding ${thread.vehicleTitle}.',
                  ),
                  icon: const Icon(Icons.chat_bubble, size: 20),
                  label: Text(
                    'Open WhatsApp Chat ($hostDisplay)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWhatsAppColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Row: Copy Number & Open in Browser
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: hostNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ WhatsApp number $hostNumber copied to clipboard!'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: kWhatsAppDarkColor,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Number'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(
                        context,
                        phoneNumber: cleanNumber,
                        message: 'Hello ${thread.partnerName}! I am contacting you from PassionRide regarding ${thread.vehicleTitle}.',
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Direct Web Link'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Message Templates Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Message Starters:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Template 1: Pickup Location
              _buildTemplateCard(
                context: context,
                title: '📍 Request Exact Pickup Location',
                subtitle: 'Ask host for GPS map pin and nearby landmarks in Puri',
                onTap: () => _openWhatsApp(
                  context,
                  phoneNumber: cleanNumber,
                  message: 'Hello ${thread.partnerName}! Could you please share the exact pickup location coordinates and landmark for ${thread.vehicleTitle}?',
                ),
                isDark: isDark,
              ),

              // Template 2: Pickup Timing
              _buildTemplateCard(
                context: context,
                title: '🕘 Confirm Pickup Timing',
                subtitle: 'Coordinate vehicle handover time and schedule',
                onTap: () => _openWhatsApp(
                  context,
                  phoneNumber: cleanNumber,
                  message: 'Hello ${thread.partnerName}! I would like to confirm my pickup timing for ${thread.vehicleTitle}. What time works best?',
                ),
                isDark: isDark,
              ),

              // Template 3: Documents
              _buildTemplateCard(
                context: context,
                title: '📄 Verify Required Documents',
                subtitle: 'Confirm Driving License and identity verification',
                onTap: () => _openWhatsApp(
                  context,
                  phoneNumber: cleanNumber,
                  message: 'Hello ${thread.partnerName}! What documents do I need to bring for ${thread.vehicleTitle} pickup? (Driving License / Aadhaar)',
                ),
                isDark: isDark,
              ),

              // Template 4: Bike Condition
              _buildTemplateCard(
                context: context,
                title: '🏍️ Vehicle Specs & Helmets',
                subtitle: 'Ask about fuel level, helmet availability, and gear',
                onTap: () => _openWhatsApp(
                  context,
                  phoneNumber: cleanNumber,
                  message: 'Hello ${thread.partnerName}! Could you please confirm if helmets and full tank fuel are included with ${thread.vehicleTitle}?',
                ),
                isDark: isDark,
              ),

              const SizedBox(height: 24),
              // Explanatory Footer Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notice: Host-customer conversations with ${thread.partnerName} are routed to WhatsApp at $hostDisplay for instantaneous delivery, voice notes, and live GPS location sharing.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.blue.shade100 : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kWhatsAppColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_outlined, color: kWhatsAppColor, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: kWhatsAppColor),
      ),
    );
  }

  Future<void> _openWhatsApp(
    BuildContext context, {
    required String message,
    String? phoneNumber,
    String? hostName,
  }) async {
    final success = await WhatsAppLauncherService.launchWhatsApp(
      phoneNumber: phoneNumber,
      hostName: hostName,
      message: message,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Opening WhatsApp link in browser...'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: kWhatsAppColor),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        onPressed: onTap,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
    );
  }

  /* ============================================================================
     OLD IN-APP CHATTING SECTION COMMENTED OUT AS PER USER REQUEST.
     All chat between host and customers is redirected to WhatsApp.
     ============================================================================ */
}
