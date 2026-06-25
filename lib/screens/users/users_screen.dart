import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String? _role;
  String _search = '';
  final _searchCtrl = TextEditingController();

  ({String? role, String? search}) get _args => (role: _role, search: _search.isEmpty ? null : _search);

  void _refresh() => ref.invalidate(usersProvider(_args));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(usersProvider(_args));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Users',
          subtitle: 'Everyone on the platform',
          actions: [
            ElevatedButton.icon(
              onPressed: _createStaff,
              icon: const Icon(Icons.add),
              label: const Text('Add staff'),
            ),
          ],
        ),
        _filters(),
        const SizedBox(height: 12),
        Expanded(
          child: AsyncListView<AdminUser>(
            value: async,
            onRetry: _refresh,
            emptyText: 'No users match your filter.',
            builder: (users) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('KYC')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map(_row).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filters() {
    return Row(
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search name or phone',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
            onSubmitted: (v) => setState(() => _search = v.trim()),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String?>(
          value: _role,
          hint: const Text('All roles'),
          items: const [
            DropdownMenuItem(value: null, child: Text('All roles')),
            DropdownMenuItem(value: 'Customer', child: Text('Customer')),
            DropdownMenuItem(value: 'Vendor', child: Text('Vendor')),
            DropdownMenuItem(value: 'Technician', child: Text('Technician')),
            DropdownMenuItem(value: 'Rider', child: Text('Rider')),
            DropdownMenuItem(value: 'Admin', child: Text('Admin')),
          ],
          onChanged: (v) => setState(() => _role = v),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  DataRow _row(AdminUser u) {
    return DataRow(cells: [
      DataCell(Text('${u.id}')),
      DataCell(Text(u.fullName)),
      DataCell(Text(u.phone)),
      DataCell(Text(u.role)),
      DataCell(Row(
        children: [
          StatusBadge(u.kycStatus),
          if (u.kycStatus == 'Rejected' && (u.kycRejectionReason ?? '').isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              tooltip: u.kycRejectionReason,
              onPressed: () => _showReason(u.kycRejectionReason!),
            ),
        ],
      )),
      DataCell(StatusBadge(u.isActive ? 'Active' : 'Inactive')),
      DataCell(Row(
        children: [
          if (u.kycStatus == 'Pending') ...[
            _miniBtn('Approve KYC', AppColors.success, () => _reviewKyc(u, true)),
            const SizedBox(width: 6),
            _miniBtn('Reject KYC', AppColors.danger, () => _reviewKyc(u, false)),
            const SizedBox(width: 6),
          ],
          if (u.role != 'Admin')
            _miniBtn(
              u.isActive ? 'Deactivate' : 'Activate',
              u.isActive ? AppColors.danger : AppColors.success,
              () => _toggleActive(u),
            ),
        ],
      )),
    ]);
  }

  Widget _miniBtn(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(120)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 32),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showReason(String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection reason'),
        content: Text(reason),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _reviewKyc(AdminUser u, bool approve) async {
    String? reason;
    if (!approve) {
      reason = await askReason(context, 'Reject KYC for ${u.fullName}', 'Why is it rejected?');
      if (reason == null) return;
    }
    final res = await ref.read(adminServiceProvider).reviewKyc(u.id, approve, rejectionReason: reason);
    if (!mounted) return;
    toast(context, res.ok ? (res.message ?? 'Done') : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh();
  }

  Future<void> _toggleActive(AdminUser u) async {
    final ok = await confirm(context, u.isActive ? 'Deactivate user?' : 'Activate user?',
        '${u.fullName} (${u.phone})');
    if (!ok) return;
    final res = await ref.read(adminServiceProvider).setUserActive(u.id, !u.isActive);
    if (!mounted) return;
    toast(context, res.ok ? (res.message ?? 'Done') : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh();
  }

  Future<void> _createStaff() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final pass = TextEditingController();
    final addr = TextEditingController();
    String role = 'Technician';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add staff'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Phone (10 digits)')),
                const SizedBox(height: 12),
                TextField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password (min 6)')),
                const SizedBox(height: 12),
                TextField(controller: addr, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'Technician', child: Text('Technician')),
                    DropdownMenuItem(value: 'Rider', child: Text('Rider')),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? 'Technician'),
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
    final res = await ref.read(adminServiceProvider).createStaff(
          fullName: name.text.trim(),
          phone: phone.text.trim(),
          password: pass.text,
          role: role,
          address: addr.text.trim(),
        );
    if (!mounted) return;
    toast(context, res.ok ? (res.message ?? 'Created') : (res.message ?? 'Failed'), error: !res.ok);
    if (res.ok) _refresh();
  }
}
