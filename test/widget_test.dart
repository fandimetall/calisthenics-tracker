import 'package:flutter_test/flutter_test.dart';
import 'package:calisthenics_tracker/main.dart';

void main() {
  testWidgets('App smoke test builds cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const CaliTrackerApp());
    expect(find.byType(CaliTrackerApp), findsOneWidget);
  });
}
