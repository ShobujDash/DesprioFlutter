import 'package:flutter_test/flutter_test.dart';

import 'package:deshprio_flutter/main.dart';
import 'package:deshprio_flutter/src/services/settings_service.dart';

void main() {
  testWidgets('shows login screen before authentication',
      (WidgetTester tester) async {
    final settings = SettingsService();

    await tester.pumpWidget(DeshprioApp(settings: settings));

    expect(find.text('লগইন'), findsWidgets);
    expect(find.textContaining(SettingsService.defaultBaseUrl), findsOneWidget);
  });
}
