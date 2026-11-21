// ignore_for_file: deprecated_member_use
import '../models/models.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../services/whatsapp_launcher_service.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MESSAGES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Conversations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              CircleAvatar(
                backgroundColor: AppColors.primaryContainer.withOpacity(0.2),
                child: const Icon(Icons.mark_email_unread_outlined, color: AppColors.primary),
              ),
            ],
          ),

          // Escrow Protection & Platform Safety Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerHighDark : AppColors.secondaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: AppColors.secondary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Direct WhatsApp Support • Escrow Protected',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Chat with hosts directly on WhatsApp (+91 78907 38917) for instantaneous updates and faster replies. Keep reservations inside PassionRide for 100% deposit protection.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search messages
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search chats or owners...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),

          const SizedBox(height: 16),

          if (appState.chatThreads.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No Active Conversations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When you message a vehicle host or rider, your active chat conversations will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => appState.setNavIndex(1), // Discovery / Vehicles
                      icon: const Icon(Icons.directions_car, size: 16),
                      label: const Text('Browse Vehicles to Contact Host'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (appState.unreadChatCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _waGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${appState.unreadChatCount} unread chat${appState.unreadChatCount == 1 ? '' : 's'}',
                        style: const TextStyle(color: _waGreenDark, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.chatThreads.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 76,
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                itemBuilder: (context, index) => _ChatRow(
                  thread: appState.chatThreads[index],
                  isDark: isDark,
                  onTap: () => appState.selectChatThread(appState.chatThreads[index]),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}


const _waGreen = Color(0xFF25D366);
const _waGreenDark = Color(0xFF128C7E);

/// WhatsApp-style chat row: avatar, name, last message, time, and a green
/// unread counter ("1", "2", ...) that turns the time green too.
class _ChatRow extends StatelessWidget {
  final ChatThread thread;
  final bool isDark;
  final VoidCallback onTap;
  const _ChatRow({required this.thread, required this.isDark, required this.onTap});

  static String _timeLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat('h:mm a').format(t);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(t);
    return DateFormat('dd/MM/yy').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadCount;
    final hasUnread = unread > 0;
    final initials = thread.partnerName.trim().isEmpty
        ? '?'
        : thread.partnerName.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
    final lastIsMine = thread.messages.isNotEmpty && thread.messages.last.isUser;
    final lastStatus = lastIsMine ? thread.messages.last.status : '';

    return InkWell(
      onTap: onTap,
      onLongPress: () {
        if (!WhatsAppLauncherService.isUsablePhone(thread.partnerPhone)) return;
        WhatsAppLauncherService.launchWhatsApp(
          phoneNumber: thread.partnerPhone,
          message: 'Hello ${thread.partnerName}! I am contacting you from PassionRide regarding ${thread.vehicleTitle}.',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            foregroundImage: thread.partnerAvatar.startsWith('http') ? NetworkImage(thread.partnerAvatar) : null,
            child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    thread.partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeLabel(thread.lastTime),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: hasUnread ? _waGreenDark : (isDark ? Colors.white54 : Colors.grey.shade600),
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                if (lastIsMine) ...[
                  Icon(
                    lastStatus == 'read' ? Icons.done_all : (lastStatus == 'failed' ? Icons.error_outline : Icons.done_all),
                    size: 16,
                    color: lastStatus == 'read'
                        ? const Color(0xFF34B7F1)
                        : (lastStatus == 'failed' ? Colors.red : Colors.grey),
                  ),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(
                    thread.lastMessage.isNotEmpty ? thread.lastMessage : 'Tap to start chatting',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: hasUnread ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white60 : Colors.grey.shade700),
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _waGreen, borderRadius: BorderRadius.circular(11)),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ]),
              if (thread.vehicleTitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.two_wheeler, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      thread.vehicleTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
