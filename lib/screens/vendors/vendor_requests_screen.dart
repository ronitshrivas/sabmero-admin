import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class VendorRequestsScreen extends ConsumerStatefulWidget {
  const VendorRequestsScreen({super.key});

  @override
  ConsumerState<VendorRequestsScreen> createState() => _VendorRequestsScreenState();
}

class _VendorRequestsScreenState extends ConsumerState<VendorRequestsScreen> {
  String? _status = 'Pending';

  void _refresh() => ref.invalidate(vendorRequestsProvider(_status));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vendorRequestsProvider(_status));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Vendor Requests',
          subtitle: 'Approve or reject applications. A profile is created only on approval.',
          actions: [
            DropdownButton<String?>(
              value: _status,
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
                onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
          ],
        ),
        Expanded(
          child: AsyncListView<VendorRequest>(
            value: async,
            onRetry: _refresh,
            emptyText: 'No vendor requests.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Applicant')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Business')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Documents')),
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

  DataRow _row(VendorRequest r) {
    return DataRow(cells: [
      DataCell(Text('${r.id}')),
      DataCell(Text(r.ownerName)),
      DataCell(Text(r.phone)),
      DataCell(Text(r.businessName)),
      DataCell(SizedBox(width: 200, child: Text(r.businessAddress, overflow: TextOverflow.ellipsis))),
      DataCell(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(0, 32),
        ),
        icon: const Icon(Icons.folder_open, size: 16),
        label: const Text('View', style: TextStyle(fontSize: 12)),
        onPressed: () => _viewDocuments(r),
      )),
      DataCell(Row(children: [
        StatusBadge(r.status),
        if (r.status == 'Rejected' && (r.rejectionReason ?? '').isNotEmpty)
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            tooltip: r.rejectionReason,
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Rejection reason'),
                content: Text(r.rejectionReason!),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ),
            ),
          ),
      ])),
      DataCell(r.status != 'Pending'
          ? const Text('—', style: TextStyle(color: AppColors.textMuted))
          : Row(children: [
              _btn('Approve', AppColors.success, () => _approve(r)),
              const SizedBox(width: 6),
              _btn('Reject', AppColors.danger, () => _reject(r)),
            ])),
    ]);
  }

  void _viewDocuments(VendorRequest r) {
    final docs = <String, String?>{
      'Citizenship': r.citizenshipDocumentPath,
      'NID card': r.nidDocumentPath,
      'Business document': r.businessDocumentPath,
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Documents — ${r.ownerName}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: docs.entries.map((e) {
                final path = e.value;
                final has = path != null && path.isNotEmpty;
                final url = has
                    ? (path.startsWith('http')
                        ? path
                        : '${AppConfig.baseUrl}$path')
                    : null;
                final isPdf = has && url!.toLowerCase().endsWith('.pdf');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.text)),
                      const SizedBox(height: 6),
                      if (!has)
                        const Text('Not provided',
                            style: TextStyle(color: AppColors.textMuted))
                      else if (isPdf)
                        TextButton.icon(
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: Text(url!, overflow: TextOverflow.ellipsis),
                          onPressed: () {},
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url!,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Could not load image.'),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
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

  Future<void> _approve(VendorRequest r) async {
    final rateCtrl = TextEditingController(text: '10');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve ${r.businessName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This creates the vendor profile and upgrades the user to Vendor.'),
            const SizedBox(height: 16),
            TextField(
              controller: rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Commission rate %'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      ),
    );
    if (ok != true) return;
    final rate = double.tryParse(rateCtrl.text.trim());
    final res = await ref
        .read(adminServiceProvider)
        .reviewVendorRequest(r.id, approved: true, commissionRate: rate);
    if (!mounted) return;
    toast(context, res.ok ? (res.message ?? 'Approved') : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh();
  }

  Future<void> _reject(VendorRequest r) async {
    final reason = await askReason(context, 'Reject ${r.businessName}', 'Reason for rejection');
    if (reason == null) return;
    final res = await ref
        .read(adminServiceProvider)
        .reviewVendorRequest(r.id, approved: false, rejectionReason: reason);
    if (!mounted) return;
    toast(context, res.ok ? (res.message ?? 'Rejected') : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh();
  }
}
