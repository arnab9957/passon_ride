// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class MovableChatbotButton extends StatefulWidget {
  final VoidCallback onTap;

  const MovableChatbotButton({
    super.key,
    required this.onTap,
  });

  @override
  State<MovableChatbotButton> createState() => _MovableChatbotButtonState();
}

class _MovableChatbotButtonState extends State<MovableChatbotButton> {
  double? _left;
  double? _top;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = 64.0;

    // Default position: Bottom Right corner
    _left ??= screenSize.width - buttonSize - 20;
    _top ??= screenSize.height - buttonSize - 100;

    return Positioned(
      left: _left,
      top: _top,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _left = (_left! + details.delta.dx).clamp(10.0, screenSize.width - buttonSize - 10.0);
            _top = (_top! + details.delta.dy).clamp(40.0, screenSize.height - buttonSize - 40.0);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B), // Slate 800
            border: Border.all(
              color: _isDragging ? Colors.orangeAccent : const Color(0xFF38BDF8),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isDragging ? Colors.orangeAccent : const Color(0xFF38BDF8)).withOpacity(0.4),
                blurRadius: _isDragging ? 16 : 10,
                spreadRadius: _isDragging ? 4 : 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'public/chatbot-icon.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Web asset / path fallback
                    return Image.asset(
                      'chatbot-icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, st) {
                        return Image.network(
                          'chatbot-icon.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.rocket_launch,
                            color: Colors.orangeAccent,
                            size: 32,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Small indicator badge
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399), // Emerald status dot
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
