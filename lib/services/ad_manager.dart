import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool get isAdLoaded => _isAdLoaded;

  // Standard Test Interstitial Ad Unit ID for Android/iOS
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  /// Initialize Remote Config settings and ad configuration
  Future<void> initAdConfig() async {
    if (kIsWeb) {
      debugPrint('AdManager: Running on Web, skipping Mobile Ads SDK initialization.');
      return;
    }

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Configure fetch interval settings
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set default parameters
      await remoteConfig.setDefaults(const {
        'ad_control_switch': true,
      });

      // Fetch & activate Remote Config values
      await remoteConfig.fetchAndActivate();

      // Check whether to show ads
      bool showAds = remoteConfig.getBool('ad_control_switch');

      if (showAds) {
        _loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('AdManager Init Warning: $e');
      // Default fallback load for test mode
      _loadInterstitialAd();
    }
  }

  /// Load Interstitial Ad from AdMob
  void _loadInterstitialAd() {
    if (kIsWeb) return;

    try {
      InterstitialAd.load(
        adUnitId: _testAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;
            debugPrint('AdMob Interstitial Ad Loaded Successfully.');
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
            _isAdLoaded = false;
            debugPrint('AdMob Interstitial Ad Failed to Load: ${error.message}');
          },
        ),
      );
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  /// Show Interstitial Ad if user is eligible and remote config allows
  void showInterstitialAd({void Function()? onAdDismissed}) {
    if (kIsWeb) {
      debugPrint('AdManager: Running on Web, skipping AdMob display.');
      if (onAdDismissed != null) onAdDismissed();
      return;
    }

    // Check Firebase Auth status if needed (e.g., skip ads for premium subscribers)
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Current User for Ad Display: ${user?.email ?? "Guest"}');

    if (_interstitialAd != null && _isAdLoaded) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
          if (onAdDismissed != null) onAdDismissed();
          _loadInterstitialAd(); // Reload for next time
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isAdLoaded = false;
          if (onAdDismissed != null) onAdDismissed();
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint('Ad not ready or suppressed. Proceeding directly.');
      if (onAdDismissed != null) onAdDismissed();
    }
  }
}
