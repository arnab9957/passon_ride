import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'services/ad_manager.dart';
import 'firebase_options.dart';
import 'irsargo/irsargo_api.dart';
import 'irsargo/chatbot.dart';

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

  // 1b. Initialize Supabase PostgreSQL Client
  try {
    await Supabase.initialize(
      url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
      anonKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
    );
    print('Supabase initialized successfully.');
  } catch (e) {
    print('Supabase initialization warning: $e');
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

  // 4. Setup Global Supabase Auth state listener
  try {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        print('Supabase Auth state updated: User signed in (${user.email ?? user.id})');
      } else {
        print('Supabase Auth state updated: User signed out');
      }
    });
  } catch (e) {
    print('Supabase Auth listener warning: $e');
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
    final streamClient = appState.streamChatService.client;

    final app = MaterialApp(
      title: 'PassonRide - P2P Rental & Tour Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      home: const MainNavigationScreen(),
    );

    if (streamClient != null) {
      return stream.StreamChat(
        client: streamClient,
        child: app,
      );
    }

    return app;
  }
}

