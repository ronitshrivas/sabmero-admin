import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class PromosScreen extends ConsumerWidget {
  const PromosScreen({super.key});

  void _refresh(WidgetRef ref) => ref.invalidate(promosProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(promosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Promo Codes',
          subtitle: 'Discount codes',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New promo'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<PromoRow>(
            value: async,
            onRetry: () => _refresh(ref),
            emptyText: 'No promo codes.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Discount %')),
                  DataColumn(label: Text('Expires')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows
                    .map((p) => DataRow(cells: [
                          DataCell(Text('${p.id}')),
                          DataCell(Text(p.code)),
                          DataCell(Text(p.discountPercent.toStringAsFixed(0))),
                          DataCell(Text(p.expiresAt.split('T').first)),
                          DataCell(StatusBadge(p.isActive ? 'Active' : 'Inactive')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: AppColors.danger),
                            onPressed: () => _delete(context, ref, p),
                          )),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();
    final discCtrl = TextEditingController();
    DateTime expires = DateTime.now().add(const Duration(days: 30));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New promo code'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Code (e.g. SAVE10)')),
                const SizedBox(height: 12),
                TextField(
                    controller: discCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Discount %')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Expires: ${expires.toString().split(' ').first}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: expires,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) setLocal(() => expires = picked);
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final disc = double.tryParse(discCtrl.text.trim()) ?? 0;
    if (codeCtrl.text.trim().isEmpty || disc <= 0) {
      if (context.mounted) toast(context, 'Enter a code and a discount > 0.', error: true);
      return;
    }
    final res = await ref.read(adminServiceProvider).createPromo(
          codeCtrl.text.trim().toUpperCase(),
          disc,
          expires.toUtc().toIso8601String(),
        );
    if (!context.mounted) return;
    toast(context, res.ok ? 'Created' : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, PromoRow p) async {
    final ok = await confirm(context, 'Delete promo?', '"${p.code}" will be removed.');
    if (!ok) return;
    final res = await ref.read(adminServiceProvider).deletePromo(p.id);
    if (!context.mounted) return;
    toast(context, res.ok ? 'Deleted' : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }
}
