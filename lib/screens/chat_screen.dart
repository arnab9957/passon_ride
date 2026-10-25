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
          title: const Text('Host & Customer Chat'),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: kWhatsAppColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_rounded,
                    size: 64,
                    color: kWhatsAppColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Chat with Host on WhatsApp',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'In-app chatting is redirected to WhatsApp for instant responses and real-time updates with hosts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kWhatsAppColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, color: kWhatsAppColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        WhatsAppLauncherService.defaultPlatformWhatsAppDisplay,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: kWhatsAppColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(context, message: 'Hello! I am contacting you from PassionRide regarding vehicle booking and rental support.'),
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text(
                      'Open WhatsApp Chat',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kWhatsAppColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: OutlinedButton.icon(
                    onPressed: () => appState.setNavIndex(6),
                    icon: const Icon(Icons.inbox, size: 18),
                    label: const Text('View All Conversations'),
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
      );
    }

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
                        children: const [
                          Icon(Icons.chat_bubble, size: 10, color: kWhatsAppColor),
                          SizedBox(width: 4),
                          Text(
                            'WhatsApp Chat Active',
                            style: TextStyle(
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

                // Vehicle & WhatsApp Action Button
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
                  tooltip: 'Open WhatsApp',
                  icon: const Icon(Icons.chat, color: kWhatsAppColor),
                  onPressed: () => _openWhatsApp(
                    context,
                    phoneNumber: thread.partnerPhone,
                    message: 'Hello ${thread.partnerName}! I am contacting you from PassionRide regarding ${thread.vehicleTitle}.',
                  ),
                ),
              ],
            ),
          ),

          // Quick Action Template Chips Bar (Redirects directly to WhatsApp with pre-filled message)
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
                      phoneNumber: thread.partnerPhone,
                      message: 'Hello ${thread.partnerName}! Could you please share the exact pickup location coordinates and landmark for ${thread.vehicleTitle}?',
                    );
                  }),
                  _buildQuickAction('🕘 Pickup Time', Icons.schedule, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: thread.partnerPhone,
                      message: 'Hello ${thread.partnerName}! I would like to confirm my pickup time for ${thread.vehicleTitle}.',
                    );
                  }),
                  _buildQuickAction('📄 Required Docs', Icons.badge, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: thread.partnerPhone,
                      message: 'Hello ${thread.partnerName}! What documents (Driving License / Aadhaar) do I need for ${thread.vehicleTitle}?',
                    );
                  }),
                  _buildQuickAction('🏍️ Bike Details', Icons.two_wheeler, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: thread.partnerPhone,
                      message: 'Hello ${thread.partnerName}! Could you share details regarding helmet and fuel for ${thread.vehicleTitle}?',
                    );
                  }),
                  _buildQuickAction('💬 WhatsApp Now', Icons.chat, () {
                    _openWhatsApp(
                      context,
                      phoneNumber: thread.partnerPhone,
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
                    '🛡️ Verified Support • Host & customer communication is powered via WhatsApp (${WhatsAppLauncherService.formatDisplayPhone(thread.partnerPhone)}). Always keep payments inside PassionRide.',
                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Main WhatsApp Redirection Section
          Expanded(
            child: _buildWhatsAppRedirectSection(context, appState, thread, isDark),
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
    bool isDark,
  ) {
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
              const Text(
                'Chat via WhatsApp',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Direct Host & Customer Communication',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Official WhatsApp Number Badge
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
                        const Text(
                          'WHATSAPP SUPPORT NUMBER',
                          style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          WhatsAppLauncherService.formatDisplayPhone(thread.partnerPhone),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Copy Number',
                      icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                      onPressed: () {
                        final copyNum = WhatsAppLauncherService.formatDisplayPhone(thread.partnerPhone);
                        Clipboard.setData(
                          ClipboardData(text: copyNum),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ WhatsApp number $copyNum copied to clipboard!'),
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
                        'Active',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Primary Launch WhatsApp Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(
                    context,
                    phoneNumber: thread.partnerPhone,
                    message: 'Hello ${thread.partnerName}! I am contacting you from PassionRide regarding ${thread.vehicleTitle}.',
                  ),
                  icon: const Icon(Icons.chat_bubble, size: 20),
                  label: Text(
                    'Open WhatsApp Chat (${WhatsAppLauncherService.formatDisplayPhone(thread.partnerPhone)})',
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
                        final copyNum = WhatsAppLauncherService.formatDisplayPhone(thread.partnerPhone);
                        Clipboard.setData(
                          ClipboardData(text: copyNum),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ WhatsApp number $copyNum copied to clipboard!'),
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
                        phoneNumber: thread.partnerPhone,
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
                subtitle: 'Ask host for GPS map pin and nearby landmarks',
                onTap: () => _openWhatsApp(
                  context,
                  phoneNumber: thread.partnerPhone,
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
                  phoneNumber: thread.partnerPhone,
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
                  phoneNumber: thread.partnerPhone,
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
                  phoneNumber: thread.partnerPhone,
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
                        'Notice: Host-customer conversations are routed to WhatsApp at ${WhatsAppLauncherService.formatDisplayPhone(thread.partnerPhone)} to ensure instantaneous delivery, voice notes, and live GPS location sharing.',
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

  Future<void> _openWhatsApp(BuildContext context, {required String message, String? phoneNumber}) async {
    final success = await WhatsAppLauncherService.launchWhatsApp(
      phoneNumber: phoneNumber,
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
     All chat between host and customers is redirected to WhatsApp: +917890738917.
     The code below is preserved for archival purposes.
     ============================================================================

  // final TextEditingController _msgController = TextEditingController();
  // final ScrollController _scrollController = ScrollController();
  // final ImagePicker _imagePicker = ImagePicker();
  // final bool _isPartnerTyping = false;
  // Timer? _typingDebounceTimer;

  // void _scrollToBottom() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (_scrollController.hasClients) {
  //       _scrollController.animateTo(
  //         _scrollController.position.maxScrollExtent,
  //         duration: const Duration(milliseconds: 250),
  //         curve: Curves.easeOut,
  //       );
  //     }
  //   });
  // }

  // void _showAttachmentPicker(BuildContext context, AppState appState, ChatThread thread) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Theme.of(context).brightness == Brightness.dark
  //         ? AppColors.surfaceContainerDark
  //         : Colors.white,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (ctx) {
  //       return Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Container(
  //               width: 40,
  //               height: 4,
  //               decoration: BoxDecoration(
  //                 color: Colors.grey.shade400,
  //                 borderRadius: BorderRadius.circular(2),
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             const Text(
  //               'Share Attachment',
  //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 20),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //               children: [
  //                 _buildAttachmentOption(
  //                   context,
  //                   icon: Icons.camera_alt,
  //                   color: Colors.pink,
  //                   label: 'Camera',
  //                   onTap: () async {
  //                     Navigator.pop(ctx);
  //                     final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
  //                     if (file != null) {
  //                       final bytes = await file.readAsBytes();
  //                       final uploadedUrl = await appState.imageKitService.uploadImage(
  //                         bytes: bytes,
  //                         fileName: 'chat_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
  //                         folder: '/chat',
  //                       );
  //                       final finalUrl = uploadedUrl ?? 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80';
  //                       appState.sendAttachmentMessage(
  //                         threadId: thread.id,
  //                         text: 'Photo',
  //                         messageType: 'image',
  //                         attachmentUrl: finalUrl,
  //                       );
  //                     }
  //                   },
  //                 ),
  //                 _buildAttachmentOption(
  //                   context,
  //                   icon: Icons.photo_library,
  //                   color: Colors.purple,
  //                   label: 'Gallery',
  //                   onTap: () async {
  //                     Navigator.pop(ctx);
  //                     final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery);
  //                     if (file != null) {
  //                       final bytes = await file.readAsBytes();
  //                       final uploadedUrl = await appState.imageKitService.uploadImage(
  //                         bytes: bytes,
  //                         fileName: 'chat_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
  //                         folder: '/chat',
  //                       );
  //                       final finalUrl = uploadedUrl ?? 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80';
  //                       appState.sendAttachmentMessage(
  //                         threadId: thread.id,
  //                         text: 'Photo',
  //                         messageType: 'image',
  //                         attachmentUrl: finalUrl,
  //                       );
  //                     }
  //                   },
  //                 ),
  //                 _buildAttachmentOption(
  //                   context,
  //                   icon: Icons.location_on,
  //                   color: Colors.green,
  //                   label: 'Location',
  //                   onTap: () async {
  //                     Navigator.pop(ctx);
  //                     final pos = await appState.locationService.getCurrentPosition();
  //                     final lat = pos.latitude;
  //                     final lng = pos.longitude;
  //                     appState.sendAttachmentMessage(
  //                       threadId: thread.id,
  //                       text: '📍 Live Pickup Coordinates: ${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°',
  //                       messageType: 'location',
  //                       latitude: lat,
  //                       longitude: lng,
  //                     );
  //                   },
  //                 ),
  //                 _buildAttachmentOption(
  //                   context,
  //                   icon: Icons.insert_drive_file,
  //                   color: Colors.blue,
  //                   label: 'Document',
  //                   onTap: () {
  //                     Navigator.pop(ctx);
  //                     appState.sendAttachmentMessage(
  //                       threadId: thread.id,
  //                       text: '📄 Rental_Agreement_Verified_PassionRide.pdf',
  //                       messageType: 'document',
  //                       attachmentUrl: 'https://PassionRide.com/docs/rental_agreement.pdf',
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 12),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // Widget _buildAttachmentOption(BuildContext context, {required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(12),
  //     child: Column(
  //       children: [
  //         CircleAvatar(
  //           radius: 26,
  //           backgroundColor: color.withOpacity(0.15),
  //           child: Icon(icon, color: color, size: 26),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildRealtimeMessagesList(AppState appState, ChatThread thread, bool isDark) {
  //   return Expanded(
  //     child: StreamBuilder<List<ChatMessage>>(
  //       stream: appState.supabaseService.streamChatMessages(
  //         thread.id,
  //         currentUserId: appState.supabaseUser?.id ?? appState.userProfile?.uid,
  //       ),
  //       builder: (context, snapshot) {
  //         final List<ChatMessage> messages = [];
  //         final localMsgs = thread.messages;

  //         if (snapshot.hasData && snapshot.data!.isNotEmpty) {
  //           final Map<String, ChatMessage> map = {};
  //           for (var m in localMsgs) {
  //             map[m.id] = m;
  //           }
  //           for (var m in snapshot.data!) {
  //             map[m.id] = m;
  //           }
  //           messages.addAll(map.values);
  //           messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  //         } else {
  //           messages.addAll(localMsgs);
  //         }

  //         _scrollToBottom();

  //         if (messages.isEmpty) {
  //           return const Center(
  //             child: Padding(
  //               padding: EdgeInsets.all(24.0),
  //               child: Text(
  //                 'No messages yet. Send a message below to start chatting!',
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(color: Colors.grey),
  //               ),
  //             ),
  //           );
  //         }

  //         return ListView.builder(
  //           controller: _scrollController,
  //           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  //           itemCount: messages.length,
  //           itemBuilder: (context, index) {
  //             final msg = messages[index];
  //             return _buildMessageBubble(msg, isDark, appState, thread);
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }

  // Widget _buildMessageInputComposer(BuildContext context, AppState appState, ChatThread thread, bool isDark) {
  //   return Container(
  //     padding: const EdgeInsets.all(10),
  //     decoration: BoxDecoration(
  //       color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
  //       border: Border(top: BorderSide(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight)),
  //     ),
  //     child: Row(
  //       children: [
  //         IconButton(
  //           icon: const Icon(Icons.attach_file, color: Colors.grey),
  //           onPressed: () => _showAttachmentPicker(context, appState, thread),
  //         ),
  //         Expanded(
  //           child: TextField(
  //             controller: _msgController,
  //             decoration: InputDecoration(
  //               hintText: 'Type a message to owner...',
  //               isDense: true,
  //               contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(24),
  //                 borderSide: BorderSide.none,
  //               ),
  //               filled: true,
  //               fillColor: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 6),
  //         CircleAvatar(
  //           backgroundColor: AppColors.primary,
  //           radius: 20,
  //           child: IconButton(
  //             icon: const Icon(Icons.send, color: Colors.white, size: 18),
  //             onPressed: () {
  //               final text = _msgController.text.trim();
  //               if (text.isNotEmpty) {
  //                 final hasLeakage = text.contains(RegExp(r'\d{10}')) || text.toLowerCase().contains('call me') || text.contains('@');
  //                 appState.sendMessage(thread.id, text);
  //                 _msgController.clear();

  //                 if (hasLeakage) {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text('⚠️ Security Notice: Off-platform contact details were masked by Platform Leakage Filter.'),
  //                       backgroundColor: Colors.deepOrange,
  //                       duration: Duration(seconds: 4),
  //                     ),
  //                   );
  //                 }
  //               }
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildMessageBubble(ChatMessage msg, bool isDark, AppState appState, ChatThread thread) {
  //   final bool isUser = msg.isUser;
  //   final bool isModerated = msg.isModerated;
  //   final String timeStr = DateFormat('hh:mm a').format(msg.timestamp);

  //   return Align(
  //     alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
  //     child: Container(
  //       margin: const EdgeInsets.only(bottom: 8),
  //       constraints: const BoxConstraints(maxWidth: 290),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.end,
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: isModerated
  //                   ? Colors.amber.shade900.withOpacity(0.85)
  //                   : (isUser
  //                       ? AppColors.primary
  //                       : (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow)),
  //               borderRadius: BorderRadius.circular(18).copyWith(
  //                 bottomRight: isUser ? Radius.zero : const Radius.circular(18),
  //                 bottomLeft: !isUser ? Radius.zero : const Radius.circular(18),
  //               ),
  //               boxShadow: [
  //                 BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3, offset: const Offset(0, 1)),
  //               ],
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (isModerated)
  //                   const Padding(
  //                     padding: EdgeInsets.only(bottom: 4),
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amberAccent),
  //                         SizedBox(width: 4),
  //                         Text(
  //                           'Moderated Contact Data',
  //                           style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent),
  //                         ),
  //                       ],
  //                     ),
  //                   ),

  //                 // Image Attachment Renderer
  //                 if (msg.messageType == 'image' && msg.attachmentUrl != null) ...[
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(12),
  //                     child: Image.network(
  //                       msg.attachmentUrl!,
  //                       height: 160,
  //                       width: double.infinity,
  //                       fit: BoxFit.cover,
  //                       errorBuilder: (_, _, _) => Container(
  //                         height: 120,
  //                         color: Colors.grey.shade800,
  //                         child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 6),
  //                 ],

  //                 // Location Attachment Renderer
  //                 if (msg.messageType == 'location') ...[
  //                   Container(
  //                     padding: const EdgeInsets.all(10),
  //                     decoration: BoxDecoration(
  //                       color: Colors.black.withOpacity(0.15),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Row(
  //                       children: [
  //                         const Icon(Icons.location_on, color: Colors.redAccent, size: 24),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               const Text('Pickup Location Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
  //                               Text(
  //                                 msg.latitude != null ? '${msg.latitude!.toStringAsFixed(4)}°, ${msg.longitude!.toStringAsFixed(4)}°' : 'GPS Coordinates Shared',
  //                                 style: const TextStyle(fontSize: 10, color: Colors.white70),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(height: 6),
  //                 ],

  //                 // Document Attachment Renderer
  //                 if (msg.messageType == 'document') ...[
  //                   Container(
  //                     padding: const EdgeInsets.all(10),
  //                     decoration: BoxDecoration(
  //                       color: Colors.blue.withOpacity(0.2),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: const Row(
  //                       children: [
  //                         Icon(Icons.insert_drive_file, color: Colors.white, size: 24),
  //                         SizedBox(width: 8),
  //                         Expanded(
  //                           child: Text(
  //                             'Verified Rental Agreement Document',
  //                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(height: 6),
  //                 ],

  //                 // Message Content Text
  //                 Text(
  //                   msg.text,
  //                   style: TextStyle(
  //                     color: (isUser || isModerated) ? Colors.white : (isDark ? Colors.white : AppColors.onSurfaceLight),
  //                     fontSize: 13,
  //                   ),
  //                 ),

  //                 const SizedBox(height: 4),

  //                 // Timestamp & Status Ticks Row
  //                 Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   mainAxisAlignment: MainAxisAlignment.end,
  //                   children: [
  //                     Text(
  //                       timeStr,
  //                       style: TextStyle(
  //                         fontSize: 9.5,
  //                         color: (isUser || isModerated) ? Colors.white70 : Colors.grey,
  //                       ),
  //                     ),
  //                     if (isUser) ...[
  //                       const SizedBox(width: 4),
  //                       _buildStatusTick(msg.status),
  //                     ],
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),

  //           // Retry for Failed Messages
  //           if (msg.status == 'failed')
  //             Padding(
  //               padding: const EdgeInsets.only(top: 2),
  //               child: InkWell(
  //                 onTap: () => appState.retryFailedMessage(thread.id, msg),
  //                 child: const Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(Icons.error_outline, size: 12, color: Colors.red),
  //                     SizedBox(width: 4),
  //                     Text('Failed • Tap to Retry', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildStatusTick(String status) {
  //   if (status == 'sending') {
  //     return const SizedBox(
  //       width: 10,
  //       height: 10,
  //       child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
  //     );
  //   } else if (status == 'sent') {
  //     return const Icon(Icons.check, size: 14, color: Colors.white70);
  //   } else if (status == 'delivered') {
  //     return const Icon(Icons.done_all, size: 14, color: Colors.white70);
  //   } else if (status == 'read') {
  //     return const Icon(Icons.done_all, size: 14, color: Colors.cyanAccent);
  //   } else if (status == 'failed') {
  //     return const Icon(Icons.warning, size: 12, color: Colors.amber);
  //   }
  //   return const Icon(Icons.done_all, size: 14, color: Colors.cyanAccent);
  // }
  ============================================================================ */
}
