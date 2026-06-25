import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  void _refresh(WidgetRef ref) => ref.invalidate(returnsProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(returnsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Return Requests',
          subtitle: 'Customer return/refund requests',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<ReturnRow>(
            value: async,
            onRetry: () => _refresh(ref),
            emptyText: 'No return requests.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Order')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows.map((r) => _row(context, ref, r)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(BuildContext context, WidgetRef ref, ReturnRow r) {
    return DataRow(cells: [
      DataCell(Text('${r.id}')),
      DataCell(Text('#${r.orderId}')),
      DataCell(SizedBox(width: 280, child: Text(r.reason, overflow: TextOverflow.ellipsis))),
      DataCell(StatusBadge(r.status)),
      DataCell(r.status != 'Pending'
          ? const Text('—', style: TextStyle(color: AppColors.textMuted))
          : Row(children: [
              _btn('Approve', AppColors.success, () => _resolve(context, ref, r, 'Approved')),
              const SizedBox(width: 6),
              _btn('Reject', AppColors.danger, () => _resolve(context, ref, r, 'Rejected')),
            ])),
    ]);
  }

  Widget _btn(String label, Color color, VoidCallback onTap) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(120)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(0, 32),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  Future<void> _resolve(BuildContext context, WidgetRef ref, ReturnRow r, String status) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$status return #${r.id}'),
        content: SizedBox(
          width: 340,
          child: TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Admin note (optional)'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(status)),
        ],
      ),
    );
    if (ok != true) return;
    final note = noteCtrl.text.trim();
    final res = await ref
        .read(adminServiceProvider)
        .resolveReturn(r.id, status, adminNote: note.isEmpty ? null : note);
    if (!context.mounted) return;
    toast(context, res.ok ? status : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }
}
