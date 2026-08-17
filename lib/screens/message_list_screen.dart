import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

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

          const SizedBox(height: 16),

          // Search messages
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search chats or owners...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),

          const SizedBox(height: 16),

          // Quick Start Direct Chat with Sovan Rajbanshi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => appState.openChatWithHost(
                hostName: 'Sovan Rajbanshi',
                vehicleTitle: 'Rental Reservation & Support',
              ),
              icon: const Icon(Icons.mark_chat_read, color: Colors.white, size: 18),
              label: const Text(
                'Start Chat with Sovan Rajbanshi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Thread list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appState.chatThreads.length,
            itemBuilder: (context, index) {
              final thread = appState.chatThreads[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(thread.partnerAvatar),
                      ),
                      if (thread.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: AppColors.secondary,
                            child: Text(
                              '${thread.unreadCount}',
                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(thread.partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '12m ago',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(thread.vehicleTitle, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => appState.setNavIndex(5), // Open chat thread
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
