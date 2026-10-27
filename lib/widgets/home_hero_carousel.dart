import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../screens/location_screen.dart';
import 'tr_text.dart';

class _HeroSlide {
  final String tag;
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final String imageUrl;
  final String category;

  const _HeroSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.imageUrl,
    required this.category,
  });
}

const _slides = [
  _HeroSlide(
    tag: '🏍️ Rent Bikes',
    title: 'Ride the hills your way',
    subtitle: 'Keyless access • Fully insured • Local owners',
    cta: 'Explore Bikes',
    icon: Icons.two_wheeler,
    imageUrl: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=1200&q=80',
    category: 'Motorcycles',
  ),
  _HeroSlide(
    tag: '🏡 Homestays',
    title: 'Stay with local hosts',
    subtitle: 'Cozy homestays & budget hotels on your route',
    cta: 'Find Stays',
    icon: Icons.holiday_village_rounded,
    imageUrl: 'https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=1200&q=80',
    category: 'Hotels and Stays',
  ),
  _HeroSlide(
    tag: '🧭 Guided Tours',
    title: 'Join a guided trip',
    subtitle: 'Explore with experienced local guides',
    cta: 'View Tours',
    icon: Icons.tour,
    imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=1200&q=80',
    category: 'Guided Tours',
  ),
];

class HomeHeroCarousel extends StatefulWidget {
  final VoidCallback onPostBlog;

  const HomeHeroCarousel({super.key, required this.onPostBlog});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_current + 1) % _slides.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Listener(
              onPointerDown: (_) => _timer?.cancel(),
              onPointerUp: (_) => _startTimer(),
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (context, i) => _buildSlide(context, appState, _slides[i]),
              ),
            ),
            // Persistent top bar: location + post
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () => showLocationPickerModal(context),
                      borderRadius: BorderRadius.circular(20),
                      child: _glassPill(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              appState.isLiveLocationActive ? Icons.my_location : Icons.location_on,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                appState.selectedLocation.split(',').first,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: widget.onPostBlog,
                    borderRadius: BorderRadius.circular(20),
                    child: _glassPill(
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.post_add_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Post', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Dot indicators
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                children: List.generate(_slides.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 6),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.secondaryContainer : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassPill(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  Widget _buildSlide(BuildContext context, AppState appState, _HeroSlide slide) {
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          slide.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
          errorBuilder: (context, error, stack) => slide.category == 'Motorcycles'
              ? Image.asset('public/nike.jpg', fit: BoxFit.cover)
              : fallback,
        ),
        // Legibility overlay
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xDD000000), Color(0x55000000), Color(0x33000000)],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  slide.tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TrText(
                slide.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 6),
              TrText(
                slide.subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  appState.setCategory(slide.category);
                  appState.setNavIndex(1);
                },
                icon: Icon(slide.icon, size: 18),
                label: Text(slide.cta, style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
