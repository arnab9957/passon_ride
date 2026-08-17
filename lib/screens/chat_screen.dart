import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thread = appState.chatThreads.isNotEmpty ? appState.chatThreads.first : null;

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
          // Chat Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => appState.setNavIndex(6), // Back to message list
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(thread.partnerAvatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(thread.partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(thread.vehicleTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Quick Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('Unlock Vehicle', Icons.lock_open, () {
                    final targetId = appState.selectedVehicle?.id ?? 'v1';
                    appState.toggleIoTLock(targetId);
                    appState.sendMessage(thread.id, '🔓 Remote keyless unlock signal transmitted!');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('IoT Unlock Command transmitted to Vehicle!')),
                    );
                  }),
                  _buildQuickAction('Share Location', Icons.my_location, () {
                    appState.sendMessage(thread.id, '📍 Live GPS Location shared: 37.7749° N, 122.4194° W');
                  }),
                  _buildQuickAction('Extend Trip', Icons.more_time, () {
                    appState.sendMessage(thread.id, '⏱ Requested 2-hour rental extension.');
                  }),
                ],
              ),
            ),
          ),

          // Message Thread List (Real-time Streamed)
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: appState.supabaseService.streamChatMessages(thread.id),
              builder: (context, snapshot) {
                final messages = (snapshot.hasData && snapshot.data!.isNotEmpty)
                    ? snapshot.data!
                    : thread.messages;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, isDark);
                  },
                );
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              border: Border(top: BorderSide(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message to owner...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () {
                    if (_msgController.text.trim().isNotEmpty) {
                      appState.sendMessage(thread.id, _msgController.text.trim());
                      _msgController.clear();
                    }
                  },
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
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.primary
              : (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
            bottomLeft: !msg.isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : (isDark ? Colors.white : AppColors.onSurfaceLight),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
