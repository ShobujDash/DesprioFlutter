import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/deshprio_models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class ExpensePurchaseScreen extends StatefulWidget {
  const ExpensePurchaseScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<ExpensePurchaseScreen> createState() => _ExpensePurchaseScreenState();
}

class _ExpensePurchaseScreenState extends State<ExpensePurchaseScreen> {
  final _quantityController = TextEditingController();
  List<Item> _items = [];
  Item? _selectedItem;
  dynamic _buys;
  dynamic _expenses;
  bool _loading = true;
  bool _expenseMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await Future.wait([
        widget.api.getItems(),
        widget.api.getBuys(date: date),
        widget.api.getExpenses(date: date),
      ]);
      _items = results[0] as List<Item>;
      _buys = results[1];
      _expenses = results[2];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final quantity = double.tryParse(_quantityController.text);
    if (_selectedItem == null) return _snack('পণ্য নির্বাচন করুন');
    if (quantity == null || quantity <= 0) return _snack('পরিমাণ লিখুন');
    if (_expenseMode) {
      await widget.api
          .createExpense(itemId: _selectedItem!.id, quantity: quantity);
      _snack('খরচ সংরক্ষিত হয়েছে');
    } else {
      await widget.api.createBuy(itemId: _selectedItem!.id, quantity: quantity);
      _snack('ক্রয় সংরক্ষিত হয়েছে');
    }
    _quantityController.clear();
    setState(() => _selectedItem = null);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const PageTitle(
              title: 'ক্রয় ও খরচ',
              subtitle: 'Purchase, expense, and stock movement'),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DashboardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: false,
                              icon: Icon(Icons.add_shopping_cart),
                              label: Text('ক্রয়')),
                          ButtonSegment(
                              value: true,
                              icon: Icon(Icons.remove_shopping_cart),
                              label: Text('খরচ')),
                        ],
                        selected: {_expenseMode},
                        onSelectionChanged: (value) =>
                            setState(() => _expenseMode = value.first),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Item>(
                        initialValue: _selectedItem,
                        decoration: const InputDecoration(labelText: 'পণ্য'),
                        items: _items
                            .map((item) => DropdownMenuItem(
                                value: item, child: Text(item.name)))
                            .toList(),
                        onChanged: (item) =>
                            setState(() => _selectedItem = item),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quantityController,
                        decoration:
                            const InputDecoration(labelText: 'পরিমাণ (কেজি)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                              _expenseMode ? 'খরচ সংরক্ষণ' : 'ক্রয় সংরক্ষণ'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DashboardCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('আজকের ক্রয় তালিকা',
                              style: TextStyle(fontWeight: FontWeight.w800))),
                      const Divider(height: 1),
                      JsonListView(data: _buys),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DashboardCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('আজকের খরচ তালিকা',
                              style: TextStyle(fontWeight: FontWeight.w800))),
                      const Divider(height: 1),
                      JsonListView(data: _expenses),
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
