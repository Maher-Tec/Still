import 'package:flutter_test/flutter_test.dart';
import 'package:still/app/still_app.dart';

void main() {
  testWidgets('STILL app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const StillApp(
        isFirstLaunch: false,
        soundEnabled: false,
        motionEnabled: false,
        hapticsEnabled: false,
        initialMoodIndex: 0,
      ),
    );

    expect(find.text('STILL'), findsOneWidget);
  });
}
