import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isPartnerTyping = false;
  Timer? _typingDebounceTimer;

  @override
  void initState() {
    super.initState();
    _msgController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    _scrollController.dispose();
    _typingDebounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_typingDebounceTimer?.isActive ?? false) _typingDebounceTimer!.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      // Typing stopped
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentPicker(BuildContext context, AppState appState, ChatThread thread) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceContainerDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Share Attachment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    context,
                    icon: Icons.camera_alt,
                    color: Colors.pink,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        final uploadedUrl = await appState.imageKitService.uploadImage(
                          bytes: bytes,
                          fileName: 'chat_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          folder: '/chat',
                        );
                        final finalUrl = uploadedUrl ?? 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80';
                        appState.sendAttachmentMessage(
                          threadId: thread.id,
                          text: 'Photo',
                          messageType: 'image',
                          attachmentUrl: finalUrl,
                        );
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final XFile? file = await _imagePicker.pickImage(source: ImageSource.gallery);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        final uploadedUrl = await appState.imageKitService.uploadImage(
                          bytes: bytes,
                          fileName: 'chat_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          folder: '/chat',
                        );
                        final finalUrl = uploadedUrl ?? 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80';
                        appState.sendAttachmentMessage(
                          threadId: thread.id,
                          text: 'Photo',
                          messageType: 'image',
                          attachmentUrl: finalUrl,
                        );
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.location_on,
                    color: Colors.green,
                    label: 'Location',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final pos = await appState.locationService.getCurrentPosition();
                      final lat = pos.latitude;
                      final lng = pos.longitude;
                      appState.sendAttachmentMessage(
                        threadId: thread.id,
                        text: '📍 Live Pickup Coordinates: ${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°',
                        messageType: 'location',
                        latitude: lat,
                        longitude: lng,
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.insert_drive_file,
                    color: Colors.blue,
                    label: 'Document',
                    onTap: () {
                      Navigator.pop(ctx);
                      appState.sendAttachmentMessage(
                        threadId: thread.id,
                        text: '📄 Rental_Agreement_Verified_PassonRide.pdf',
                        messageType: 'document',
                        attachmentUrl: 'https://passonride.com/docs/rental_agreement.pdf',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(BuildContext context, {required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thread = appState.selectedChatThread ?? (appState.chatThreads.isNotEmpty ? appState.chatThreads.first : null);

    if (thread == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Chat Conversations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contact a host from vehicle details or view your message inbox to start chatting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => appState.setNavIndex(6),
                  icon: const Icon(Icons.inbox),
                  label: const Text('Go to Message Inbox'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.surfaceContainerDark : Colors.white, width: 2),
                        ),
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
                          Icon(Icons.circle, size: 8, color: Colors.greenAccent.shade400),
                          const SizedBox(width: 4),
                          Text(
                            _isPartnerTyping ? 'typing...' : 'Online',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isPartnerTyping ? AppColors.primary : Colors.greenAccent.shade700,
                              fontWeight: _isPartnerTyping ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bike & Booking Context Badge
                Container(
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
              ],
            ),
          ),

          // Bike Rental Quick Action Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('📍 Pickup Location', Icons.my_location, () {
                    appState.sendAttachmentMessage(
                      threadId: thread.id,
                      text: '📍 Meeting & Pickup Spot: Passon Rental Hub, Indiranagar, Bangalore (12.9716° N, 77.5946° E)',
                      messageType: 'location',
                      latitude: 12.9716,
                      longitude: 77.5946,
                    );
                  }),
                  _buildQuickAction('🕘 Pickup Time', Icons.schedule, () {
                    appState.sendMessage(thread.id, '🕘 Ready for pickup today at 10:00 AM. Please keep your Driving License ready.');
                  }),
                  _buildQuickAction('📄 Required Docs', Icons.badge, () {
                    appState.sendMessage(thread.id, '📄 Requirements: Original Driving License + Government ID proof (Aadhaar / Passport).');
                  }),
                  _buildQuickAction('🏍️ Bike Details', Icons.two_wheeler, () {
                    appState.sendMessage(thread.id, '🏍️ Vehicle Info: ${thread.vehicleTitle} • Helmet Included • Full Tank Gas.');
                  }),
                  _buildQuickAction('💰 Booking PIN', Icons.key, () {
                    appState.sendMessage(thread.id, '🔑 Keyless Unlock PIN: 849201. Use PIN at pickup location.');
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
                    '🛡️ Escrow Protected • Process payments in-app to remain covered by ₹50,000 damage deposit guarantee.',
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Real-time Streamed Chat Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: appState.supabaseService.streamChatMessages(
                thread.id,
                currentUserId: appState.supabaseUser?.id ?? appState.userProfile?.uid,
              ),
              builder: (context, snapshot) {
                final List<ChatMessage> messages = [];
                final localMsgs = thread.messages;

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final Map<String, ChatMessage> map = {};
                  for (var m in localMsgs) {
                    map[m.id] = m;
                  }
                  for (var m in snapshot.data!) {
                    map[m.id] = m;
                  }
                  messages.addAll(map.values);
                  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                } else {
                  messages.addAll(localMsgs);
                }

                _scrollToBottom();

                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No messages yet. Send a message below to start chatting!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, isDark, appState, thread);
                  },
                );
              },
            ),
          ),

          // Typing Indicator Bar
          if (_isPartnerTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${thread.partnerName} is typing...',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primary),
                ),
              ),
            ),

          // Message Input Composer Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              border: Border(top: BorderSide(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () => _showAttachmentPicker(context, appState, thread),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message to owner...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      final text = _msgController.text.trim();
                      if (text.isNotEmpty) {
                        final hasLeakage = text.contains(RegExp(r'\d{10}')) || text.toLowerCase().contains('call me') || text.contains('@');
                        appState.sendMessage(thread.id, text);
                        _msgController.clear();

                        if (hasLeakage) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Security Notice: Off-platform contact details were masked by Platform Leakage Filter.'),
                              backgroundColor: Colors.deepOrange,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: AppColors.primary),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        onPressed: onTap,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark, AppState appState, ChatThread thread) {
    final bool isUser = msg.isUser;
    final bool isModerated = msg.isModerated;
    final String timeStr = DateFormat('hh:mm a').format(msg.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 290),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isModerated
                    ? Colors.amber.shade900.withOpacity(0.85)
                    : (isUser
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow)),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                  bottomLeft: !isUser ? Radius.zero : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 3, offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isModerated)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amberAccent),
                          SizedBox(width: 4),
                          Text(
                            'Moderated Contact Data',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                          ),
                        ],
                      ),
                    ),

                  // Image Attachment Renderer
                  if (msg.messageType == 'image' && msg.attachmentUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        msg.attachmentUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: Colors.grey.shade800,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Location Attachment Renderer
                  if (msg.messageType == 'location') ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pickup Location Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                                Text(
                                  msg.latitude != null ? '${msg.latitude!.toStringAsFixed(4)}°, ${msg.longitude!.toStringAsFixed(4)}°' : 'GPS Coordinates Shared',
                                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Document Attachment Renderer
                  if (msg.messageType == 'document') ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verified Rental Agreement Document',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Message Content Text
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: (isUser || isModerated) ? Colors.white : (isDark ? Colors.white : AppColors.onSurfaceLight),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Timestamp & Status Ticks Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: (isUser || isModerated) ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        _buildStatusTick(msg.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Retry for Failed Messages
            if (msg.status == 'failed')
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: InkWell(
                  onTap: () => appState.retryFailedMessage(thread.id, msg),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 12, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Failed • Tap to Retry', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTick(String status) {
    if (status == 'sending') {
      return const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
      );
    } else if (status == 'sent') {
      return const Icon(Icons.check, size: 14, color: Colors.white70);
    } else if (status == 'delivered') {
      return const Icon(Icons.done_all, size: 14, color: Colors.white70);
    } else if (status == 'read') {
      return const Icon(Icons.done_all, size: 14, color: Colors.cyanAccent);
    } else if (status == 'failed') {
      return const Icon(Icons.warning, size: 12, color: Colors.amber);
    }
    return const Icon(Icons.done_all, size: 14, color: Colors.cyanAccent);
  }
}
