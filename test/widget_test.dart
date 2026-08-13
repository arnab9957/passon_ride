import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:passon_ride/main.dart';
import 'package:passon_ride/providers/app_state.dart';

void main() {
  testWidgets('PassonRide app builds cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const PassonRideApp(),
      ),
    );

    expect(find.textContaining('PassonRide'), findsWidgets);
  });
}
