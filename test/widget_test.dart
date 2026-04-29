import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_fake_bank/main.dart';

void main() {
  testWidgets('VPBank app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'balance': 1006214});

    await tester.pumpWidget(const VPBankCloneApp());
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
