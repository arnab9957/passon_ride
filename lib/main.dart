import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

import 'i18n/strings.g.dart';
import 'providers/app_state.dart';
import 'providers/language_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'services/ad_manager.dart';
import 'firebase_options.dart';
import 'services/web_auth_helper_stub.dart'
    if (dart.library.html) 'services/web_auth_helper_web.dart' as web_auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  if (kIsWeb) {
    web_auth.closePopupIfOpen();
  }

  // 1. Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // 1b. Initialize Supabase PostgreSQL Client
  try {
    await Supabase.initialize(
      url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
      publishableKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
    );
    debugPrint('Supabase initialized successfully.');
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  // 2. Initialize Mobile Ads (AdMob) - Native Android/iOS only
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      debugPrint('AdMob Mobile Ads SDK initialized.');
    } catch (e) {
      debugPrint('AdMob initialization warning: $e');
    }
  }

  // 3. Initialize Remote Config & AdManager
  try {
    await AdManager().initAdConfig();
  } catch (e) {
    debugPrint('AdManager initialization warning: $e');
  }

  // 4. Setup Global Supabase Auth state listener
  try {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        debugPrint(
          'Supabase Auth state updated: User signed in (${user.email ?? user.id})',
        );
      } else {
        debugPrint('Supabase Auth state updated: User signed out');
      }
    });
  } catch (e) {
    debugPrint('Supabase Auth listener warning: $e');
  }

  runApp(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const PassionRideApp(),
      ),
    ),
  );
}

class PassionRideApp extends StatelessWidget {
  const PassionRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final streamClient = appState.streamChatService.client;

    final app = MaterialApp(
      title: 'PassionRide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const MainNavigationScreen(),
    );

    if (streamClient != null) {
      return stream.StreamChat(client: streamClient, child: app);
    }

    return app;
  }
}
