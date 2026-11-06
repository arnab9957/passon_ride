// Provider dashboard: verification badge (green tick vs pulsing "Verification Pending")
// and the "Show to your Customers" card sitting at the bottom of the page.
// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/i18n/strings.g.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/providers/language_provider.dart';
import 'package:passon_ride/screens/provider_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TestAppState extends AppState {
  _TestAppState(this._profile);
  final HostProfile _profile;
  @override
  HostProfile? get hostProfile => _profile;
}

HostProfile _profile(String status) =>
    HostProfile.fromMap({'id': 'hp_1', 'user_id': 'u_1', 'display_name': 'Sayantan', 'verification_status': status});

Future<void> _loadFonts() async {
  final root = '${Platform.environment['HOME']}/snap/flutter/common/flutter/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$root/$f');
      if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['com.llfbandit.app_links/events', 'com.llfbandit.app_links/messages']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
    try {
      await Supabase.initialize(
        url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
        publishableKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
      );
    } catch (_) {}
    await _loadFonts();
  });

  Future<void> pumpDashboard(WidgetTester tester, String status) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: _TestAppState(_profile(status))),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const Scaffold(body: ProviderDashboardScreen()),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 450)); // pulse mid-way
  }

  testWidgets('verified provider: only a green tick', (tester) async {
    await pumpDashboard(tester, 'verified');
    expect(find.byTooltip('Verification done'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.textContaining('VERIFIED'), findsNothing);
    expect(find.textContaining('VERIFICATION'), findsNothing);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/dashboard_verified.png'));
  });

  for (final status in ['pending', 'rejected', 'action_required']) {
    testWidgets('unverified ($status): pulsing Verification Pending alarm', (tester) async {
      await pumpDashboard(tester, status);
      expect(find.text('VERIFICATION PENDING'), findsOneWidget);
      expect(find.byIcon(Icons.notification_important_rounded), findsOneWidget);
      expect(find.byTooltip('Verification done'), findsNothing);
      if (status == 'rejected') {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/dashboard_pending.png'));
      }
    });
  }

  testWidgets('"Show to your Customers" card is below the listings, at the bottom', (tester) async {
    await pumpDashboard(tester, 'verified');
    final showCard = tester.getTopLeft(find.text('Show to your Customers')).dy;
    expect(showCard, greaterThan(tester.getTopLeft(find.text('Management Actions')).dy));
    expect(showCard, greaterThan(tester.getTopLeft(find.text('Select Service Category')).dy));
    expect(showCard, greaterThan(tester.getTopLeft(find.textContaining('No vehicles registered yet')).dy));
  });
}
