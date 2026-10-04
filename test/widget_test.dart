import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:passon_ride/main.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/providers/language_provider.dart';
import 'package:passon_ride/i18n/strings.g.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
        publishableKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
      );
    } catch (_) {}
  });

  testWidgets('PassionRide app builds cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
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

    expect(find.byType(PassionRideApp), findsOneWidget);
  });
}
