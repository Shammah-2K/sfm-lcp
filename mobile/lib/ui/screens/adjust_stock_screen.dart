import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/theme/tokens.dart';
import '../widgets/building_blocks.dart';
import '../widgets/choices.dart';
import 'product_form_screen.dart';
import 'tab_scaffold.dart';

/// S14 Adjust stock (FR7): a counted, damaged or other change to one product.
/// "Edit" opens S13 for the product's name, price and reorder level, and
/// "Stop selling" (UC9).
class AdjustStockScreen extends StatefulWidget {
  const AdjustStockScreen({super.key, required this.productId});

  final String productId;

  @override
  State<AdjustStockScreen> createState() => _AdjustStockScreenState();
}

class _AdjustStockScreenState extends State<AdjustStockScreen> {
  Stream<ProductRow?>? _product;
  int _delta = 0;
  AdjustReason _reason = AdjustReason.count;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _product ??= PortsScope.of(context).stock.watchProduct(widget.productId);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await PortsScope.of(context).stock.adjust(
      StockAdjustmentDraft(
        productId: widget.productId,
        delta: _delta,
        reason: _reason,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProductRow?>(
      stream: _product,
      builder: (context, snap) {
        final p = snap.data;
        return Scaffold(
          appBar: detailAppBar(
            p?.name ?? '',
            actions: [
              if (p != null)
                TextButton.icon(
                  key: const Key('edit-product'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductFormScreen(product: p),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(AppSizes.touch, AppSizes.touch),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              const SizedBox(width: AppSpace.sm),
            ],
          ),
          body: p == null
              ? const SizedBox.shrink()
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpace.gutter),
                          children: [
                            Text(
                              '${p.inStock} in stock',
                              style: AppText.amount,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpace.xl),
                            const SectionLabel('Change'),
                            CountStepper(
                              key: const Key('stock-delta'),
                              value: _delta,
                              min: -p.inStock,
                              showSign: true,
                              onChanged: (v) => setState(() => _delta = v),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            const SectionLabel('Why?'),
                            Wrap(
                              spacing: AppSpace.md,
                              runSpacing: AppSpace.md,
                              children: [
                                for (final (reason, label, icon) in const [
                                  (
                                    AdjustReason.count,
                                    'Counted',
                                    Icons.fact_check_outlined,
                                  ),
                                  (
                                    AdjustReason.damage,
                                    'Damaged',
                                    Icons.broken_image_outlined,
                                  ),
                                  (
                                    AdjustReason.other,
                                    'Other',
                                    Icons.more_horiz,
                                  ),
                                ])
                                  SelectChip(
                                    key: Key('reason-${reason.name}'),
                                    label: label,
                                    icon: icon,
                                    selected: _reason == reason,
                                    onTap: () =>
                                        setState(() => _reason = reason),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.xl),
                            Text(
                              'New stock: ${p.inStock + _delta}',
                              key: const Key('new-stock'),
                              style: AppText.label,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.gutter,
                          AppSpace.sm,
                          AppSpace.gutter,
                          AppSpace.lg,
                        ),
                        child: PrimaryAction(
                          label: 'Save',
                          onPressed: !_saving && _delta != 0 ? _save : null,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
