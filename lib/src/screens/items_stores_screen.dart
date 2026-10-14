import 'package:flutter/material.dart';

import '../models/deshprio_models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class ItemsStoresScreen extends StatefulWidget {
  const ItemsStoresScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<ItemsStoresScreen> createState() => _ItemsStoresScreenState();
}

class _ItemsStoresScreenState extends State<ItemsStoresScreen> {
  final _itemController = TextEditingController();
  final _storeController = TextEditingController();
  final _priceController = TextEditingController();
  List<Item> _items = [];
  List<Store> _stores = [];
  List<StoreItemPriceList> _storePrices = [];
  List<StorePrice> _tempPrices = [];
  Store? _priceStore;
  Item? _priceItem;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.api.getItems(),
        widget.api.getStores(),
        widget.api.getStoreItems()
      ]);
      _items = results[0] as List<Item>;
      _stores = results[1] as List<Store>;
      _storePrices = results[2] as List<StoreItemPriceList>;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const PageTitle(title: 'সেটিংস', subtitle: 'পণ্য ও দোকানের তালিকা'),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AddCard(
                  title: 'পণ্য যোগ করুন',
                  label: 'পণ্যের নাম',
                  controller: _itemController,
                  onAdd: () async {
                    if (_itemController.text.trim().isEmpty) return;
                    await widget.api.addItem(_itemController.text.trim());
                    _itemController.clear();
                    await _load();
                  },
                ),
                const SizedBox(height: 14),
                _ListCard(
                    title: 'পণ্যের তালিকা (${_items.length}টি)',
                    items: _items.map((e) => e.name).toList()),
                const SizedBox(height: 18),
                _AddCard(
                  title: 'দোকান যোগ করুন',
                  label: 'দোকানের নাম',
                  controller: _storeController,
                  onAdd: () async {
                    if (_storeController.text.trim().isEmpty) return;
                    await widget.api.addStore(_storeController.text.trim());
                    _storeController.clear();
                    await _load();
                  },
                ),
                const SizedBox(height: 14),
                _ListCard(
                    title: 'দোকানের তালিকা (${_stores.length}টি)',
                    items: _stores.map((e) => e.name).toList()),
                const SizedBox(height: 18),
                DashboardCard(child: _priceForm()),
                const SizedBox(height: 14),
                DashboardCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('দোকানভিত্তিক মূল্য তালিকা',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const Divider(height: 1),
                      if (_storePrices.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('কোনো মূল্য তালিকা পাওয়া যায়নি'))
                      else
                        ..._storePrices.map(
                          (store) => ExpansionTile(
                            title: Text(store.storeName),
                            subtitle: Text('${store.itemPrices.length}টি পণ্য'),
                            children: store.itemPrices
                                .map((price) => ListTile(
                                      dense: true,
                                      title: Text(price.itemName),
                                      trailing: Text(
                                          '৳${price.pricePerKg.toStringAsFixed(0)}'),
                                    ))
                                .toList(),
                          ),
                        ),
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

  Widget _priceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('দোকানভিত্তিক মূল্য নির্ধারণ',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        DropdownButtonFormField<Store>(
          initialValue: _priceStore,
          decoration: const InputDecoration(labelText: 'দোকানের নাম'),
          items: _stores
              .map((store) =>
                  DropdownMenuItem(value: store, child: Text(store.name)))
              .toList(),
          onChanged: (store) => setState(() => _priceStore = store),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Item>(
          initialValue: _priceItem,
          decoration: const InputDecoration(labelText: 'পণ্য'),
          items: _items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item.name)))
              .toList(),
          onChanged: (item) => setState(() => _priceItem = item),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceController,
          decoration: const InputDecoration(labelText: 'মূল্য (৳/কেজি)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addTempPrice,
                icon: const Icon(Icons.add),
                label: const Text('মূল্য যোগ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _savePrices,
                icon: const Icon(Icons.save_outlined),
                label: const Text('সংরক্ষণ'),
              ),
            ),
          ],
        ),
        if (_tempPrices.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._tempPrices.map((price) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(price.itemName),
                trailing: Text('৳${price.pricePerKg.toStringAsFixed(0)}'),
              )),
        ],
      ],
    );
  }

  void _addTempPrice() {
    final price = double.tryParse(_priceController.text);
    if (_priceItem == null || price == null || price <= 0) return;
    setState(() {
      _tempPrices.removeWhere((item) => item.itemId == _priceItem!.id);
      _tempPrices.add(StorePrice(
          itemId: _priceItem!.id,
          itemName: _priceItem!.name,
          pricePerKg: price));
      _priceItem = null;
      _priceController.clear();
    });
  }

  Future<void> _savePrices() async {
    if (_priceStore == null || _tempPrices.isEmpty) return;
    await widget.api.addStoreItemPrices(
      storeId: _priceStore!.id,
      storeName: _priceStore!.name,
      itemPrices: _tempPrices,
    );
    setState(() {
      _tempPrices = [];
      _priceStore = null;
    });
    await _load();
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard(
      {required this.title,
      required this.label,
      required this.controller,
      required this.onAdd});

  final String title;
  final String label;
  final TextEditingController controller;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label)),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('যোগ করুন'))),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(14),
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          const Divider(height: 1),
          if (items.isEmpty)
            const Padding(
                padding: EdgeInsets.all(18),
                child: Text('কোনো ডাটা পাওয়া যায়নি'))
          else
            ...List.generate(
                items.length,
                (index) => ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(items[index]),
                    dense: true)),
        ],
      ),
    );
  }
}
