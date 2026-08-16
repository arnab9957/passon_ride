import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AutoSlidingImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final IconData fallbackIcon;

  const AutoSlidingImageCarousel({
    super.key,
    required this.images,
    this.height = 180,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(20)),
    this.onTap,
    this.fallbackIcon = Icons.directions_car,
  });

  @override
  State<AutoSlidingImageCarousel> createState() => _AutoSlidingImageCarouselState();
}

class _AutoSlidingImageCarouselState extends State<AutoSlidingImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    if (widget.images.length > 1) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted || !_pageController.hasClients) return;
        final nextPage = (_currentPage + 1) % widget.images.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validImages = widget.images.where((img) => img.trim().isNotEmpty).toList();

    if (validImages.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: Icon(widget.fallbackIcon, size: 50, color: Colors.grey.shade600),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: PageView.builder(
                controller: _pageController,
                itemCount: validImages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    validImages[index],
                    height: widget.height,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: widget.height,
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Icon(widget.fallbackIcon, size: 50, color: Colors.grey.shade600),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Multi-Image Indicator Badge & Dots
          if (validImages.length > 1) ...[
            // Photo count pill at top-right or bottom-left
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.collections, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentPage + 1}/${validImages.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Animated Dots Indicator at bottom center
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(validImages.length, (idx) {
                  final isSelected = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isSelected ? 18.0 : 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
