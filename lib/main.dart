import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'services/ad_manager.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');
  } catch (e) {
    print('Firebase initialization warning: $e');
  }

  // 2. Initialize Mobile Ads (AdMob) - Native Android/iOS only
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      print('AdMob Mobile Ads SDK initialized.');
    } catch (e) {
      print('AdMob initialization warning: $e');
    }
  }

  // 3. Initialize Remote Config & AdManager
  try {
    await AdManager().initAdConfig();
  } catch (e) {
    print('AdManager initialization warning: $e');
  }

  // 4. Setup Global Firebase Auth state listener for Analytics & Remote Config
  try {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      final analytics = FirebaseAnalytics.instance;
      if (user != null) {
        await analytics.setUserId(id: user.uid);
        await analytics.setUserProperty(name: 'auth_status', value: 'authenticated');
        print('Firebase Auth state updated: User signed in (${user.email ?? user.uid})');
      } else {
        await analytics.setUserId(id: null);
        await analytics.setUserProperty(name: 'auth_status', value: 'guest');
        print('Firebase Auth state updated: User signed out');
      }
    });
  } catch (e) {
    print('Firebase Auth listener warning: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PassonRideApp(),
    ),
  );
}

class PassonRideApp extends StatelessWidget {
  const PassonRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'PassonRide - P2P Rental & Tour Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      home: const MainNavigationScreen(),
    );
  }
}

