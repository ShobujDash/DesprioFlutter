import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/screens/app_shell.dart';
import 'src/services/settings_service.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('bn_BD');
  final settings = SettingsService();
  await settings.load();
  runApp(DeshprioApp(settings: settings));
}

class DeshprioApp extends StatelessWidget {
  const DeshprioApp({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      notifier: settings,
      child: MaterialApp(
        title: 'দেশপ্রিয়',
        debugShowCheckedModeBanner: false,
        theme: buildDeshprioTheme(),
        home: const AppShell(),
      ),
    );
  }
}
