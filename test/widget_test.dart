import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskmate/main.dart';

void main() {
  testWidgets('shows login screen when no token is saved', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('TaskMate'), findsOneWidget);
  });
}
