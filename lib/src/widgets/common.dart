import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/deshprio_models.dart';

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade600)),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.blueGrey.shade600)),
                  const SizedBox(height: 6),
                  Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Icon(icon, color: color),
          ],
        ),
      ),
    );
  }
}

class JsonListView extends StatelessWidget {
  const JsonListView({super.key, required this.data, this.emptyText = 'ডাটা পাওয়া যায়নি'});

  final dynamic data;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final items = data is List ? data as List : data == null ? const [] : [data];
    if (items.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(emptyText)));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          dense: true,
          title: Text(_titleFor(item, index)),
          subtitle: Text(const JsonEncoder.withIndent('  ').convert(item), maxLines: 5, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }
}

class SaleDraftTable extends StatelessWidget {
  const SaleDraftTable({super.key, required this.items, required this.onRemove});

  final List<SaleDraftItem> items;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text('অস্থায়ী তালিকা (${items.length})', style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('মোট: ৳${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return ListTile(
              title: Text('${index + 1}. ${item.itemName}'),
              subtitle: Text('${item.quantity.g} কেজি x ৳${item.pricePerKg.g}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('৳${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(onPressed: () => onRemove(index), icon: const Icon(Icons.delete_outline)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

String _titleFor(dynamic item, int index) {
  if (item is Map) {
    return item['storeName']?.toString() ??
        item['itemName']?.toString() ??
        item['name']?.toString() ??
        item['id']?.toString() ??
        '#${index + 1}';
  }
  return item?.toString() ?? '#${index + 1}';
}

extension NumFormat on num {
  String get g => this % 1 == 0 ? toStringAsFixed(0) : toString();
}
