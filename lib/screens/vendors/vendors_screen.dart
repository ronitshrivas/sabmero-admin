import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Vendors',
          subtitle: 'Approved sellers',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _createVendor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create vendor'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(vendorsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<Vendor>(
            value: async,
            onRetry: () => ref.invalidate(vendorsProvider),
            emptyText: 'No vendors yet.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Owner')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Business')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Commission %')),
                  DataColumn(label: Text('Products')),
                  DataColumn(label: Text('Approved')),
                ],
                rows: rows
                    .map(
                      (v) => DataRow(
                        cells: [
                          DataCell(Text('${v.id}')),
                          DataCell(Text(v.ownerName)),
                          DataCell(Text(v.phone)),
                          DataCell(Text(v.businessName)),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                v.businessAddress,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(v.commissionRate.toStringAsFixed(1))),
                          DataCell(Text('${v.productCount}')),
                          DataCell(
                            StatusBadge(v.isApproved ? 'Approved' : 'Pending'),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createVendor(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final pass = TextEditingController();
    final addr = TextEditingController();
    final bizName = TextEditingController();
    final bizAddr = TextEditingController();
    final commission = TextEditingController(text: '10');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create vendor'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'The vendor is created with KYC pending. They can sign in, but '
                    'cannot sell until you approve their KYC (Users page).',
                    style: TextStyle(fontSize: 12, color: AppColors.text),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Account',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Owner full name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (10 digits)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (min 6)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addr,
                  decoration: const InputDecoration(
                    labelText: 'Personal address',
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Business',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bizName,
                  decoration: const InputDecoration(labelText: 'Business name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bizAddr,
                  decoration: const InputDecoration(
                    labelText: 'Business address',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commission,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Commission rate %',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (name.text.trim().isEmpty ||
        phone.text.trim().length != 10 ||
        pass.text.length < 6 ||
        bizName.text.trim().isEmpty ||
        bizAddr.text.trim().isEmpty) {
      if (context.mounted) {
        toast(
          context,
          'Fill name, 10-digit phone, password (6+), business name and address.',
          error: true,
        );
      }
      return;
    }

    final res = await ref
        .read(adminServiceProvider)
        .createVendor(
          fullName: name.text.trim(),
          phone: phone.text.trim(),
          email: email.text.trim(),
          password: pass.text,
          address: addr.text.trim(),
          businessName: bizName.text.trim(),
          businessAddress: bizAddr.text.trim(),
          commissionRate: double.tryParse(commission.text.trim()),
        );
    if (!context.mounted) return;
    toast(
      context,
      res.ok ? (res.message ?? 'Vendor created') : (res.message ?? 'Failed'),
      error: !res.ok,
    );
    if (res.ok) ref.invalidate(vendorsProvider);
  }
}
