import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _refresh(WidgetRef ref) => ref.invalidate(categoriesProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Categories',
          subtitle: 'Product categories',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('New category'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<CategoryRow>(
            value: async,
            onRetry: () => _refresh(ref),
            emptyText: 'No categories.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Products')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows
                    .map((c) => DataRow(cells: [
                          DataCell(Text('${c.id}')),
                          DataCell(Text(c.name)),
                          DataCell(Text('${c.productCount}')),
                          DataCell(StatusBadge(c.isActive ? 'Active' : 'Inactive')),
                          DataCell(Row(children: [
                            IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _edit(context, ref, c)),
                            IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.danger),
                                onPressed: () => _delete(context, ref, c)),
                          ])),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, CategoryRow? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    bool active = existing?.isActive ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New category' : 'Edit category'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                if (existing != null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setLocal(() => active = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;

    final svc = ref.read(adminServiceProvider);
    final res = existing == null
        ? await svc.createCategory(nameCtrl.text.trim())
        : await svc.updateCategory(existing.id, nameCtrl.text.trim(), active);
    if (!context.mounted) return;
    toast(context, res.ok ? 'Saved' : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, CategoryRow c) async {
    final ok = await confirm(context, 'Delete category?', '"${c.name}" will be removed.');
    if (!ok) return;
    final res = await ref.read(adminServiceProvider).deleteCategory(c.id);
    if (!context.mounted) return;
    toast(context, res.ok ? 'Deleted' : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }
}
