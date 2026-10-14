import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'dashboard_screen.dart';
import 'expense_purchase_screen.dart';
import 'items_stores_screen.dart';
import 'login_screen.dart';
import 'printer_screen.dart';
import 'sales_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final api = ApiService(settings);
    if (settings.authToken == null) {
      return LoginScreen(api: api, settings: settings);
    }
    final screens = [
      DashboardScreen(api: api),
      SalesScreen(api: api, type: SaleScreenType.retail),
      SalesScreen(api: api, type: SaleScreenType.wholesale),
      ExpensePurchaseScreen(api: api),
      ItemsStoresScreen(api: api),
      PrinterScreen(settings: settings),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('দেশপ্রিয় মিষ্টান্ন ভাণ্ডার'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => settings.setAuthToken(null),
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'API Settings',
            onPressed: () => _showSettings(context, settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'ড্যাশবোর্ড'),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'খুচরা'),
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'পাইকারী'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'স্টক'),
          NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'সেটিংস'),
          NavigationDestination(
              icon: Icon(Icons.print_outlined),
              selectedIcon: Icon(Icons.print),
              label: 'প্রিন্ট'),
        ],
      ),
    );
  }

  Future<void> _showSettings(
      BuildContext context, SettingsService settings) async {
    final controller = TextEditingController(text: settings.baseUrl);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Backend API URL',
            hintText: SettingsService.defaultBaseUrl,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বন্ধ')),
          FilledButton(
            onPressed: () async {
              await settings.setBaseUrl(controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('সেভ'),
          ),
        ],
      ),
    );
  }
}
