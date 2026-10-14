import 'package:flutter/material.dart';

import '../models/deshprio_models.dart';
import '../services/api_service.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardStats> _future = widget.api.getDashboardStats();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = widget.api.getDashboardStats()),
      child: FutureBuilder<DashboardStats>(
        future: _future,
        builder: (context, snapshot) {
          final stats = snapshot.data;
          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const PageTitle(title: 'ড্যাশবোর্ড', subtitle: 'আপনার ব্যবসার সারসংক্ষেপ'),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('ড্যাশবোর্ড লোড করা যায়নি: ${snapshot.error}'),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    StatCard(
                      label: 'মোট ক্রয়',
                      value: '${(stats?.totalBuy ?? 0).toStringAsFixed(0)} কেজি',
                      icon: Icons.trending_down,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'মোট বিক্রয়',
                      value: '${(stats?.totalSale ?? 0).toStringAsFixed(0)} কেজি',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'মোট স্টক',
                      value: '${(stats?.totalStock ?? 0).toStringAsFixed(0)} কেজি',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('মাসিক রেভিনিউ চার্ট', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: _MiniBars(data: stats?.monthlyData ?? const []),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.data});

  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('চার্ট ডাটা পাওয়া যায়নি'));
    final maxValue = data
        .expand((row) => [row['income'] ?? 0, row['purchases'] ?? 0])
        .map((e) => e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
        .fold<double>(1, (max, value) => value > max ? value : max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.take(8).map((row) {
        final income = row['income'] is num ? (row['income'] as num).toDouble() : 0.0;
        final buy = row['purchases'] is num ? (row['purchases'] as num).toDouble() : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: FractionallySizedBox(heightFactor: income / maxValue, child: Container(color: Colors.blue))),
                      const SizedBox(width: 3),
                      Flexible(child: FractionallySizedBox(heightFactor: buy / maxValue, child: Container(color: Colors.amber))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(row['month']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
