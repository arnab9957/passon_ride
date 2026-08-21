import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'irsargo_api.dart';

class IrsargoChatbotWidget extends StatefulWidget {
  final IrsargoApi api;
  final String uiContext;

  const IrsargoChatbotWidget({
    super.key,
    required this.api,
    this.uiContext = 'PassionRide Active Screen',
  });

  @override
  State<IrsargoChatbotWidget> createState() => _IrsargoChatbotWidgetState();
}

class _IrsargoChatbotWidgetState extends State<IrsargoChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<IrsargoChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isExpanded = false; // Toggle compact (48%) vs expanded (75%)

  @override
  void initState() {
    super.initState();
    final firstLine = widget.uiContext.split('\n').first;
    _messages.add(IrsargoChatMessage(
      sender: 'bot',
      text: '''📌 **IRSARGO CO-PILOT INITIALIZED**
Connected to active screen: **$firstLine**.

📊 **CAPABILITIES**
• **Vehicle Rentals**: Instant pricing & keyless PIN specs
• **Tour Itineraries**: Day-by-day route & altitude advice
• **IoT Telematics**: Battery health & DTC error code audits

🔒 *Data processed strictly from public screen interface context.*''',
      uiContextSnapshot: widget.uiContext,
      timestamp: DateTime.now(),
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(IrsargoChatMessage(
        sender: 'user',
        text: text,
        uiContextSnapshot: widget.uiContext,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final responseMsg = await widget.api.queryRAG(
        userQuery: text,
        frontEndUiContext: widget.uiContext,
      );
      setState(() {
        _messages.add(responseMsg);
      });
    } catch (e) {
      setState(() {
        _messages.add(IrsargoChatMessage(
          sender: 'bot',
          text: '⚠️ Unable to complete RAG query. Please verify connection.',
          isError: true,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Compact height: 48% (or max 480px) so it doesn't cover the whole page!
    final containerHeight = _isExpanded
        ? screenSize.height * 0.75
        : math.min(screenSize.height * 0.48, 480.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: containerHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate-900 background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            spreadRadius: 4,
          )
        ],
      ),
      child: Column(
        children: [
          // Drag handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'public/chatbot-icon.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'chatbot-icon.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Icon(
                          Icons.rocket_launch,
                          color: Colors.orangeAccent,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IRSARGO AI Co-Pilot',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF34D399), size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Screen: ${widget.uiContext.split("\n").first}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Height Expand/Shrink Toggle
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                    color: Colors.lightBlueAccent,
                    size: 20,
                  ),
                  tooltip: _isExpanded ? 'Shrink Window' : 'Expand Window',
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),

                // Close Button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Privacy Guarantee & Live Scraped Context Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            color: const Color(0xFF0284C7).withOpacity(0.15),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 6),
                title: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.lightBlueAccent, size: 12),
                    SizedBox(width: 6),
                    Text(
                      '📱 Live Scraped App Interface Context Active',
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 100),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.uiContext,
                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace', height: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == 'user';
                return _buildChatBubble(msg, isUser);
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Structuring grounded RAG response for "${widget.uiContext.split("\n").first}"...',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E293B),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ask IRSARGO about vehicle, route, or telemetry...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(IrsargoChatMessage msg, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormattedMessageContent(msg.text, msg.isError),
            if (!isUser && msg.confidence != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF34D399), size: 11),
                        const SizedBox(width: 4),
                        Text(
                          '${(msg.confidence! * 100).toStringAsFixed(1)}% Faithfulness (Z3 SAT)',
                          style: const TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (!isUser && msg.sources != null && msg.sources!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    '📚 Grounded Sources (${msg.sources!.length})',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  children: msg.sources!.map((src) {
                    final label = src is Map ? src['label'] : 'Source Chunk';
                    final content = src is Map ? src['content'] : src.toString();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label ?? 'Source Chunk',
                            style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            content ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 9),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// Parses and renders well-structured bold headers, bullet points, and sections nicely
  Widget _buildFormattedMessageContent(String content, bool isError) {
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 4));
        continue;
      }

      // Check header line (starts with emoji or bold like 📌 SUMMARY)
      if (trimmed.startsWith('📌') || trimmed.startsWith('📊') || trimmed.startsWith('🛡️') || trimmed.startsWith('💡')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              trimmed.replaceAll('**', ''),
              style: TextStyle(
                color: trimmed.startsWith('📌')
                    ? Colors.orangeAccent
                    : (trimmed.startsWith('📊')
                        ? Colors.lightBlueAccent
                        : (trimmed.startsWith('🛡️') ? const Color(0xFF34D399) : Colors.amberAccent)),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('•')) {
        // Bullet point line
        final parts = trimmed.substring(1).trim().split('**');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseBoldTextSpans(trimmed.substring(1).trim(), isError),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Standard text paragraph
        widgets.add(
          RichText(
            text: TextSpan(
              children: _parseBoldTextSpans(trimmed, isError),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<TextSpan> _parseBoldTextSpans(String text, bool isError) {
    final List<TextSpan> spans = [];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            color: isError ? Colors.redAccent : (isBold ? Colors.white : Colors.white70),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      );
    }
    return spans;
  }
}
