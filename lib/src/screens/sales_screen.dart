import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/deshprio_models.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';
import '../services/settings_service.dart';
import '../widgets/common.dart';

enum SaleScreenType { retail, wholesale }

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key, required this.api, required this.type});

  final ApiService api;
  final SaleScreenType type;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController();
  final _printer = PrinterService();

  List<Item> _items = [];
  List<StoreItemPriceList> _storePriceLists = [];
  List<SaleDraftItem> _draft = [];
  Item? _selectedItem;
  StoreItemPriceList? _selectedStore;
  dynamic _sales;
  bool _loading = true;

  bool get _isRetail => widget.type == SaleScreenType.retail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (_isRetail) {
        final results = await Future.wait(
            [widget.api.getItems(), widget.api.getRetailSales(date: date)]);
        _items = results[0] as List<Item>;
        _sales = results[1];
      } else {
        final results = await Future.wait([
          widget.api.getItems(),
          widget.api.getStoreItems(),
          widget.api.getWholesaleSales(date: date),
        ]);
        _items = results[0] as List<Item>;
        _storePriceLists = results[1] as List<StoreItemPriceList>;
        _sales = results[2];
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addDraft() {
    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    if (_selectedItem == null) return _snack('পণ্য নির্বাচন করুন');
    if (!_isRetail && _selectedStore == null) {
      return _snack('দোকান নির্বাচন করুন');
    }
    if (quantity == null || quantity <= 0) return _snack('পরিমাণ লিখুন');
    if (price == null || price <= 0) return _snack('মূল্য লিখুন');

    setState(() {
      _draft = [
        ..._draft,
        SaleDraftItem(
          itemId: _selectedItem!.id,
          itemName: _selectedItem!.name,
          quantity: quantity,
          pricePerKg: price,
        ),
      ];
      _selectedItem = null;
      _quantityController.clear();
      _priceController.clear();
    });
  }

  Future<void> _save() async {
    if (_draft.isEmpty) return _snack('ডাটা নেই');
    try {
      if (_isRetail) {
        await widget.api.createRetailSale(_draft);
      } else {
        await widget.api.createWholesaleSale(
            storeId: _selectedStore!.storeId, items: _draft);
      }
      _snack(_isRetail
          ? 'বিক্রয় সংরক্ষিত হয়েছে'
          : 'পাইকারী বিক্রয় সংরক্ষিত হয়েছে');
      await _print();
      setState(() => _draft = []);
      await _load();
    } on ApiException catch (e) {
      _snack(e.status == 'INSUFFICIENT_STOCK'
          ? 'স্টকে পর্যাপ্ত মজুদ নেই'
          : e.message);
    } catch (e) {
      _snack('সংরক্ষণ করা যায়নি: $e');
    }
  }

  Future<void> _print() async {
    final settings = SettingsScope.of(context);
    if (settings.printerAddress == null) {
      _snack('Printer tab থেকে আগে Rongta printer নির্বাচন করুন');
      return;
    }
    final total = _draft.fold<double>(0, (sum, item) => sum + item.total);
    final paid = double.tryParse(_paidController.text) ?? 0;
    await _printer.printReceipt(
      address: settings.printerAddress!,
      receipt: PrinterReceipt(
        storeName: _isRetail ? null : _selectedStore?.storeName,
        items: _draft,
        totalAmount: total,
        paidAmount: paid,
      ),
    );
    _snack('প্রিন্ট পাঠানো হয়েছে');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRetail ? 'খুচরা বিক্রয়' : 'পাইকারী বিক্রয়';
    final subtitle =
        '${_isRetail ? 'Retail Sales' : 'Wholesale Sales'} - ${DateFormat('dd MMM yyyy').format(DateTime.now())}';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          PageTitle(title: title, subtitle: subtitle),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DashboardCard(child: _form(title)),
                const SizedBox(height: 14),
                if (_draft.isNotEmpty)
                  SaleDraftTable(
                      items: _draft,
                      onRemove: (index) =>
                          setState(() => _draft.removeAt(index))),
                if (_draft.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                            onPressed: _print,
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('শুধু প্রিন্ট')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('সংরক্ষণ')),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                DashboardCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                            _isRetail
                                ? 'আজকের খুচরা বিক্রয় তালিকা'
                                : 'পাইকারী বিক্রয় তালিকা (দোকান অনুযায়ী)',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const Divider(height: 1),
                      JsonListView(data: _sales),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(String title) {
    final wholesaleItems = _selectedStore?.itemPrices ?? const <StorePrice>[];
    final availableItems = _isRetail
        ? _items
        : wholesaleItems
            .map((e) => Item(id: e.itemId, name: e.itemName))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isRetail ? 'নতুন বিক্রয় যোগ করুন' : 'নতুন পাইকারী বিক্রয়',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (!_isRetail) ...[
          DropdownButtonFormField<StoreItemPriceList>(
            initialValue: _selectedStore,
            decoration: const InputDecoration(labelText: 'দোকানের নাম'),
            items: _storePriceLists
                .map((store) => DropdownMenuItem(
                    value: store, child: Text(store.storeName)))
                .toList(),
            onChanged: (store) => setState(() {
              _selectedStore = store;
              _selectedItem = null;
              _priceController.clear();
            }),
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<Item>(
          initialValue: _selectedItem,
          decoration: const InputDecoration(labelText: 'পণ্য'),
          items: availableItems
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item.name)))
              .toList(),
          onChanged: (item) => setState(() {
            _selectedItem = item;
            if (!_isRetail && item != null) {
              StorePrice? price;
              for (final candidate in wholesaleItems) {
                if (candidate.itemId == item.id) {
                  price = candidate;
                  break;
                }
              }
              _priceController.text =
                  price == null ? '' : price.pricePerKg.toStringAsFixed(0);
            }
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _quantityController,
          decoration: const InputDecoration(labelText: 'পরিমাণ (কেজি)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceController,
          readOnly: !_isRetail,
          decoration: const InputDecoration(labelText: 'মূল্য (৳/কেজি)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _paidController,
          decoration: const InputDecoration(labelText: 'জমা টাকা (ঐচ্ছিক)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _addDraft,
                icon: const Icon(Icons.add),
                label: const Text('যোগ করুন'))),
      ],
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
