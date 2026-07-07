import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                    .map((v) => DataRow(cells: [
                          DataCell(Text('${v.id}')),
                          DataCell(Text(v.ownerName)),
                          DataCell(Text(v.phone)),
                          DataCell(Text(v.businessName)),
                          DataCell(SizedBox(
                              width: 200,
                              child: Text(v.businessAddress, overflow: TextOverflow.ellipsis))),
                          DataCell(Text(v.commissionRate.toStringAsFixed(1))),
                          DataCell(Text('${v.productCount}')),
                          DataCell(StatusBadge(v.isApproved ? 'Approved' : 'Pending')),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
