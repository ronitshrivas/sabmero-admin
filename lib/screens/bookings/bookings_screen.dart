import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  String? _status;

  void _refresh() => ref.invalidate(bookingsProvider(_status));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingsProvider(_status));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Bookings',
          subtitle: 'Repair & installation jobs',
          actions: [
            DropdownButton<String?>(
              value: _status,
              hint: const Text('All statuses'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All statuses')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                DropdownMenuItem(value: 'Processing', child: Text('Processing')),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
                onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
          ],
        ),
        Expanded(
          child: AsyncListView<BookingRow>(
            value: async,
            onRetry: _refresh,
            emptyText: 'No bookings.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Service')),
                  DataColumn(label: Text('Time slot')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('From order')),
                  DataColumn(label: Text('Status')),
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

  DataRow _row(BookingRow b) {
    return DataRow(cells: [
      DataCell(Text('${b.id}')),
      DataCell(Text(b.serviceType)),
      DataCell(Text(b.timeSlot)),
      DataCell(SizedBox(width: 180, child: Text(b.serviceAddress, overflow: TextOverflow.ellipsis))),
      DataCell(Text(b.paymentMethod)),
      DataCell(b.relatedOrderId != null
          ? Tooltip(
              message: 'Order #${b.relatedOrderId}',
              child: const Icon(Icons.link, size: 18, color: AppColors.info))
          : const Text('—')),
      DataCell(StatusBadge(b.status)),
      DataCell(b.status == 'Completed'
          ? const Text('—', style: TextStyle(color: AppColors.textMuted))
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              onPressed: () => _assignTech(b),
              child: const Text('Assign tech', style: TextStyle(fontSize: 12)),
            )),
    ]);
  }

  Future<void> _assignTech(BookingRow b) async {
    final techs = await ref.read(techniciansProvider.future);
    if (!mounted) return;
    if (techs.isEmpty) {
      toast(context, 'No technicians available. Add one first.', error: true);
      return;
    }

    int? selected = techs.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Assign technician to booking #${b.id}'),
          content: DropdownButtonFormField<int>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Technician'),
            items: techs
                .map((t) => DropdownMenuItem(value: t.id, child: Text('${t.fullName} (${t.phone})')))
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
    final res = await ref.read(adminServiceProvider).assignTechnician(b.id, selected!);
    if (!mounted) return;
    toast(context, res.ok ? (res.message ?? 'Assigned') : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh();
  }
}
