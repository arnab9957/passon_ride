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
                        'P2P Direct Chat • Escrow Protected',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Chats are linked to your master user account and specific listing IDs. Always communicate and pay inside PassonRide for 100% deposit protection.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stream Chat SDK Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: appState.streamChatService.isConnected
                    ? (isDark ? [Colors.teal.shade900.withOpacity(0.4), AppColors.surfaceContainerDark] : [Colors.teal.shade50, Colors.green.shade50])
                    : (isDark ? [Colors.indigo.shade900.withOpacity(0.4), AppColors.surfaceContainerDark] : [Colors.blue.shade50, Colors.indigo.shade50]),
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: appState.streamChatService.isConnected ? Colors.teal.shade400 : Colors.indigo.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  appState.streamChatService.isConnected ? Icons.cloud_done : Icons.stream,
                  color: appState.streamChatService.isConnected ? Colors.teal : Colors.indigo,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            appState.streamChatService.isConnected ? 'Stream Chat SDK: Connected (Dev Mode)' : 'Stream Chat SDK: Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: appState.streamChatService.isConnected ? Colors.teal.shade800 : Colors.indigo.shade800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: appState.streamChatService.isConnected ? Colors.teal : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DEV MODE',
                              style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appState.streamApiKey != 'YOUR_STREAM_API_KEY'
                            ? 'API Key: ${appState.streamApiKey.substring(0, appState.streamApiKey.length > 8 ? 8 : appState.streamApiKey.length)}...'
                            : 'Using Stream Chat Dev Tokens. Tap to configure API Key.',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showApiKeyDialog(context, appState),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                  child: const Text('Set API Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
                child: Material(
                  color: Colors.transparent,
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
                        Expanded(
                          child: Text(
                            thread.partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    onTap: () => appState.selectChatThread(thread),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.streamApiKey != 'YOUR_STREAM_API_KEY' ? appState.streamApiKey : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.stream, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Stream Chat API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Stream Chat API Key to initialize the SDK in Development Mode:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. 5x8y2... (From Stream Dashboard)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '⚡ Ensure "Disable Authentication Checks" is toggled ON in your Stream Dashboard under Chat -> General Settings.',
              style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await appState.updateStreamApiKey(key);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stream Chat API Key set! Connected in Dev Mode.'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }
}
