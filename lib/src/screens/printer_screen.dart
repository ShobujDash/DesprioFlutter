import 'package:flutter/material.dart';

import '../services/printer_service.dart';
import '../services/settings_service.dart';
import '../widgets/common.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final _printer = PrinterService();
  late Future<List<PrinterDevice>> _devices = _printer.pairedDevices();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          setState(() => _devices = _printer.pairedDevices()),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const PageTitle(
              title: 'প্রিন্টার', subtitle: 'Rongta RPP02C Bluetooth printer'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DashboardCard(
              padding: EdgeInsets.zero,
              child: FutureBuilder<List<PrinterDevice>>(
                future: _devices,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                        padding: EdgeInsets.all(18),
                        child: LinearProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                            'Bluetooth device পড়া যায়নি: ${snapshot.error}'));
                  }
                  final devices = snapshot.data ?? const [];
                  if (devices.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                          'Android Bluetooth settings থেকে আগে Rongta printer pair করুন, তারপর refresh করুন।'),
                    );
                  }
                  return Column(
                    children: [
                      if (widget.settings.printerAddress != null)
                        ListTile(
                          leading: const Icon(Icons.check_circle,
                              color: Colors.green),
                          title: Text(widget.settings.printerName ??
                              'Selected printer'),
                          subtitle: Text(widget.settings.printerAddress!),
                        ),
                      const Divider(height: 1),
                      RadioGroup<String>(
                        groupValue: widget.settings.printerAddress,
                        onChanged: (address) async {
                          final device = devices.firstWhere(
                              (device) => device.address == address);
                          await widget.settings.setPrinter(
                              address: device.address, name: device.name);
                        },
                        child: Column(
                          children: devices
                              .map((device) => RadioListTile<String>(
                                    value: device.address,
                                    title: Text(device.name),
                                    subtitle: Text(device.address),
                                  ))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _testPrint,
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('বাংলা টেস্ট প্রিন্ট'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testPrint() async {
    if (widget.settings.printerAddress == null) {
      _snack('আগে printer নির্বাচন করুন');
      return;
    }
    await _printer.printReceipt(
      address: widget.settings.printerAddress!,
      receipt: PrinterReceipt(
        items: [],
        totalAmount: 0,
        paidAmount: 0,
      ),
    );
    _snack('টেস্ট প্রিন্ট পাঠানো হয়েছে');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
