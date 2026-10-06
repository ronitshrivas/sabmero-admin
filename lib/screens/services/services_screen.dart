import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabmero_admin/core/api_client.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

final servicesCatalogProvider =
    FutureProvider.autoDispose<List<ServiceCatalogItem>>(
  (ref) => ref.read(adminServiceProvider).servicesCatalog(),
);

// Admin management of the repair/installation services shown in the app.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  void _refresh(WidgetRef ref) => ref.invalidate(servicesCatalogProvider);

  static String _fullUrl(String path) =>
      path.startsWith('http') ? path : '${AppConfig.baseUrl}$path';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(servicesCatalogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Services',
          subtitle: 'Repair & installation services shown in the app',
          actions: [
            FilledButton.icon(
              onPressed: () => _openForm(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<ServiceCatalogItem>(
            value: async,
            onRetry: () => _refresh(ref),
            emptyText: 'No services yet. Add one.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('Image')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Charge')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows.map((s) => _row(context, ref, s)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(BuildContext context, WidgetRef ref, ServiceCatalogItem s) {
    final hasImg = s.imagePath != null && s.imagePath!.isNotEmpty;
    return DataRow(cells: [
      DataCell(hasImg
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(_fullUrl(s.imagePath!),
                  width: 44, height: 44, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 24)),
            )
          : const Icon(Icons.handyman_outlined, color: AppColors.textMuted)),
      DataCell(SizedBox(width: 200, child: Text(s.name, overflow: TextOverflow.ellipsis))),
      DataCell(Text('Rs ${s.charge.toStringAsFixed(0)}')),
      DataCell(StatusBadge(s.isActive ? 'Active' : 'Inactive')),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn('Edit', AppColors.info, () => _openForm(context, ref, s)),
          const SizedBox(width: 6),
          _btn('Delete', AppColors.danger, () => _delete(context, ref, s)),
        ],
      )),
    ]);
  }

  Widget _btn(String label, Color color, VoidCallback onTap) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(120)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(0, 32),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  Future<void> _delete(BuildContext context, WidgetRef ref, ServiceCatalogItem s) async {
    final ok = await confirm(context, 'Delete service?', 'Remove "${s.name}" from the app?');
    if (!ok) return;
    final res = await ref.read(adminServiceProvider).deleteService(s.id);
    if (!context.mounted) return;
    toast(context, res.ok ? 'Deleted' : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh(ref);
  }

  Future<void> _openForm(
      BuildContext context, WidgetRef ref, ServiceCatalogItem? existing) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ServiceFormDialog(existing: existing),
    );
    if (saved == true) _refresh(ref);
  }
}

class _ServiceFormDialog extends ConsumerStatefulWidget {
  final ServiceCatalogItem? existing;
  const _ServiceFormDialog({this.existing});

  @override
  ConsumerState<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<_ServiceFormDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _desc =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _charge =
      TextEditingController(text: widget.existing?.charge.toStringAsFixed(0) ?? '');
  late bool _active = widget.existing?.isActive ?? true;
  late String? _imagePath = widget.existing?.imagePath;
  List<int>? _pickedBytes;
  String? _pickedName;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _charge.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await FilePicker.pickFiles(type: FileType.image, withData: true);
    final f = picked?.files.firstOrNull;
    if (f == null || f.bytes == null) return;
    setState(() {
      _pickedBytes = f.bytes;
      _pickedName = f.name;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Name is required.', ok: false);
      return;
    }
    final charge = double.tryParse(_charge.text.trim()) ?? 0;
    setState(() => _busy = true);
    final svc = ref.read(adminServiceProvider);

    var imagePath = _imagePath;
    if (_pickedBytes != null && _pickedName != null) {
      final up = await svc.uploadServiceImage(_pickedBytes!, _pickedName!);
      if (!up.ok || up.path == null) {
        if (!mounted) return;
        setState(() => _busy = false);
        _snack(up.message, ok: false);
        return;
      }
      imagePath = up.path;
    }

    final ApiResult res;
    if (widget.existing == null) {
      res = await svc.createService(
        name: name,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        charge: charge,
        imagePath: imagePath,
      );
    } else {
      res = await svc.updateService(
        widget.existing!.id,
        name: name,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        charge: charge,
        imagePath: imagePath,
        isActive: _active,
      );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(res.message ?? (res.ok ? 'Saved.' : 'Failed.'), ok: res.ok);
    if (res.ok) Navigator.pop(context, true);
  }

  void _snack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasPicked = _pickedBytes != null;
    final hasExistingImg = _imagePath != null && _imagePath!.isNotEmpty;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Service' : 'Edit Service'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Service name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _charge,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(
                    labelText: 'Charge', prefixText: 'Rs ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: hasPicked
                        ? const Icon(Icons.check_circle, color: AppColors.success)
                        : hasExistingImg
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ServicesScreen._fullUrl(_imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              )
                            : const Icon(Icons.image_outlined, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: Text(hasPicked
                        ? (_pickedName ?? 'Image selected')
                        : (hasExistingImg ? 'Replace image' : 'Upload image')),
                  ),
                ],
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active (visible in app)'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
