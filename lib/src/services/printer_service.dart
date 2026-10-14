import 'package:flutter/services.dart';

import '../models/deshprio_models.dart';

class PrinterDevice {
  PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;

  factory PrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return PrinterDevice(
      name: map['name']?.toString() ?? 'Bluetooth Printer',
      address: map['address']?.toString() ?? '',
    );
  }
}

class PrinterReceipt {
  PrinterReceipt({
    this.storeName,
    required this.items,
    required this.totalAmount,
    this.paidAmount = 0,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final String? storeName;
  final List<SaleDraftItem> items;
  final double totalAmount;
  final double paidAmount;
  final DateTime date;

  Map<String, dynamic> toMap() => {
        'storeName': storeName,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'date': date.toIso8601String(),
        'items': items
            .map((item) => {
                  'itemName': item.itemName,
                  'quantity': item.quantity,
                  'pricePerKg': item.pricePerKg,
                  'totalPrice': item.total,
                })
            .toList(),
      };
}

class PrinterService {
  static const _channel = MethodChannel('deshprio/printer');

  Future<List<PrinterDevice>> pairedDevices() async {
    final result = await _channel.invokeMethod<List<dynamic>>('pairedDevices');
    return (result ?? []).map((e) => PrinterDevice.fromMap(e as Map<dynamic, dynamic>)).toList();
  }

  Future<void> printReceipt({required String address, required PrinterReceipt receipt}) {
    return _channel.invokeMethod('printReceipt', {
      'address': address,
      'receipt': receipt.toMap(),
    });
  }
}
