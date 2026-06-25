import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _status;

  void _refresh() => ref.invalidate(ordersProvider(_status));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ordersProvider(_status));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Orders',
          subtitle: 'All customer orders',
          actions: [
            DropdownButton<String?>(
              value: _status,
              hint: const Text('All statuses'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All statuses')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Processing', child: Text('Processing')),
                DropdownMenuItem(value: 'Dispatched', child: Text('Dispatched')),
                DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
                onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
          ],
        ),
        Expanded(
          child: AsyncListView<OrderRow>(
            value: async,
            onRetry: _refresh,
            emptyText: 'No orders.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Items')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Pay status')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Rider')),
                  DataColumn(label: Text('Install')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows.map(_row).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(OrderRow o) {
    return DataRow(cells: [
      DataCell(Text('${o.id}')),
      DataCell(Text(o.customerName)),
      DataCell(Text('${o.items.length}')),
      DataCell(Text('Rs ${o.totalAmount.toStringAsFixed(0)}')),
      DataCell(Text(o.paymentMethod)),
      DataCell(StatusBadge(o.paymentStatus)),
      DataCell(StatusBadge(o.status)),
      DataCell(Text(o.riderName ?? '—')),
      DataCell(o.installationBookingId != null
          ? Tooltip(
              message: 'Booking #${o.installationBookingId}',
              child: const Icon(Icons.build, size: 18, color: AppColors.info))
          : const Text('—')),
      DataCell(o.status == 'Cancelled' || o.status == 'Delivered'
          ? const Text('—', style: TextStyle(color: AppColors.textMuted))
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              onPressed: () => _assignRider(o),
              child: const Text('Assign rider', style: TextStyle(fontSize: 12)),
            )),
    ]);
  }

  Future<void> _assignRider(OrderRow o) async {
    final ridersAsync = ref.read(ridersProvider.future);
    final riders = await ridersAsync;
    if (!mounted) return;
    if (riders.isEmpty) {
      toast(context, 'No riders available. Add a rider first.', error: true);
      return;
    }

    int? selected = riders.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Assign rider to order #${o.id}'),
          content: DropdownButtonFormField<int>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Rider'),
            items: riders
                .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.fullName} (${r.phone})')))
                .toList(),
            onChanged: (v) => setLocal(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign')),
          ],
        ),
      ),
    );
    if (ok != true || selected == null) return;
    final res = await ref.read(adminServiceProvider).assignRider(o.id, selected!);
    if (!mounted) return;
    toast(context, res.ok ? (res.message ?? 'Assigned') : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh();
  }
}
