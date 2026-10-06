import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

final deliverySettingsProvider =
    FutureProvider.autoDispose<DeliverySettings?>(
  (ref) => ref.read(adminServiceProvider).deliverySettings(),
);

// Admin settings — currently the delivery charge customers pay at checkout.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _feeCtrl = TextEditingController();
  final _freeCtrl = TextEditingController();
  bool _busy = false;
  bool _loadedOnce = false;

  @override
  void dispose() {
    _feeCtrl.dispose();
    _freeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0;
    final free = double.tryParse(_freeCtrl.text.trim()) ?? 0;
    if (fee < 0 || free < 0) {
      toast(context, 'Values cannot be negative.', error: true);
      return;
    }
    setState(() => _busy = true);
    final res = await ref.read(adminServiceProvider).setDeliverySettings(fee, free);
    if (!mounted) return;
    setState(() => _busy = false);
    toast(context, res.message ?? (res.ok ? 'Saved.' : 'Failed.'), error: !res.ok);
    if (res.ok) ref.invalidate(deliverySettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(deliverySettingsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Settings',
            subtitle: 'Delivery charge applied to customer orders',
            actions: [
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(deliverySettingsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Failed to load settings: $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (s) {
              if (!_loadedOnce && s != null) {
                _feeCtrl.text = s.deliveryFee.toStringAsFixed(0);
                _freeCtrl.text = s.freeDeliveryAbove.toStringAsFixed(0);
                _loadedOnce = true;
              }
              return _card();
            },
          ),
        ],
      ),
    );
  }

  Widget _card() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Charge',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'This flat charge is added to every order at checkout. Set the '
                'threshold to offer free delivery above a certain order value '
                '(use 0 to always charge the fee).',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _feeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(
                  labelText: 'Delivery fee',
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _freeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(
                  labelText: 'Free delivery above (order subtotal)',
                  prefixText: 'Rs ',
                  helperText: '0 = never free',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
