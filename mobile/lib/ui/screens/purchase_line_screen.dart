import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../widgets/amount_entry.dart';
import '../widgets/building_blocks.dart';
import 'product_form_screen.dart';
import 'tab_scaffold.dart';

/// Which product was bought, for a stock-purchase expense (FR7). Lists the
/// products not already on the purchase, plus "New product". Resolves to the
/// chosen product, or null if dismissed.
Future<ProductRow?> pickBoughtProduct(
  BuildContext context, {
  required List<ProductRow> products,
  required Set<String> alreadyBought,
}) async {
  const newProduct = '';
  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          0,
          AppSpace.gutter,
          AppSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Which product?', style: AppText.title),
            const SizedBox(height: AppSpace.md),
            for (final p in products)
              if (!alreadyBought.contains(p.id))
                ListTile(
                  key: Key('buy-${p.id}'),
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: AppSizes.touch,
                  title: Text(p.name, style: AppText.label),
                  subtitle: Text('${p.inStock} in stock', style: AppText.body),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(p.id),
                ),
            ListTile(
              key: const Key('buy-new-product'),
              contentPadding: EdgeInsets.zero,
              minTileHeight: AppSizes.touch,
              leading: const Icon(Icons.add, color: AppColors.brand),
              title: const Text('New product', style: AppText.label),
              onTap: () => Navigator.of(context).pop(newProduct),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice != newProduct) return products.firstWhere((p) => p.id == choice);

  // The form saves the product itself; find it as the one that is new.
  final stock = PortsScope.of(context).stock;
  final before = {for (final p in await stock.watchProducts().first) p.id};
  if (!context.mounted) return null;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const ProductFormScreen(forPurchase: true),
    ),
  );
  final after = await stock.watchProducts().first;
  return after.where((p) => !before.contains(p.id)).firstOrNull;
}

/// How many of [product] were bought and what one cost. Resolves to the line,
/// or null if the user went back.
class PurchaseLineScreen extends StatefulWidget {
  const PurchaseLineScreen({super.key, required this.product, this.initial});

  final ProductRow product;

  /// The line being changed; null for a new one.
  final PurchaseLine? initial;

  @override
  State<PurchaseLineScreen> createState() => _PurchaseLineScreenState();
}

class _PurchaseLineScreenState extends State<PurchaseLineScreen> {
  late int _quantity = widget.initial?.quantity ?? 1;
  late String _costText = switch (widget.initial) {
    null => '',
    final l => typedFromNgwee(l.unitCostNgwee),
  };

  int? get _costNgwee => parseTypedNgwee(_costText);

  @override
  Widget build(BuildContext context) {
    final cost = _costNgwee;
    return Scaffold(
      appBar: detailAppBar(widget.product.name),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.gutter),
                children: [
                  const SectionLabel('How many did you buy?'),
                  CountStepper(
                    key: const Key('bought-qty'),
                    value: _quantity,
                    min: 1,
                    onChanged: (q) => setState(() => _quantity = q),
                    decreaseLabel: 'One less ${widget.product.name}',
                    increaseLabel: 'One more ${widget.product.name}',
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const SectionLabel('Cost of one'),
                  AmountDisplay(
                    text: _costText,
                    moneyIn: null,
                    valid: cost != null,
                  ),
                  const SizedBox(height: AppSpace.md),
                  AmountKeypad(
                    text: _costText,
                    onChanged: (t) => setState(() => _costText = t),
                  ),
                  if (cost != null) ...[
                    const SizedBox(height: AppSpace.md),
                    InfoLine(
                      key: const Key('bought-line-total'),
                      icon: Icons.calculate_outlined,
                      text:
                          '$_quantity × ${formatKwacha(cost)} = '
                          '${formatKwacha(_quantity * cost)}',
                    ),
                  ],
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
                label: widget.initial == null ? 'Add' : 'Update',
                onPressed: cost == null
                    ? null
                    : () => Navigator.of(context).pop(
                        PurchaseLine(
                          productId: widget.product.id,
                          quantity: _quantity,
                          unitCostNgwee: cost,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
