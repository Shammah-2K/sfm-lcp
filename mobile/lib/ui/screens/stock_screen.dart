import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../widgets/building_blocks.dart';
import 'adjust_stock_screen.dart';
import 'product_form_screen.dart';
import 'tab_scaffold.dart';

/// S12 Stock list (FR7). Low stock uses the attention card only; stock
/// counts stay in dark text, never in the money colours.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.participantCode});

  final String participantCode;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  Stream<List<ProductRow>>? _products;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _products ??= PortsScope.of(context).stock.watchProducts();
  }

  void _addProduct() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()));
  }

  void _adjust(ProductRow p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdjustStockScreen(productId: p.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabAppBar(
        title: 'Stock',
        icon: Icons.inventory_2,
        participantCode: widget.participantCode,
      ),
      body: StreamBuilder<List<ProductRow>>(
        stream: _products,
        builder: (context, snap) {
          final products = snap.data ?? const <ProductRow>[];
          final low = products.where((p) => p.isLow).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.sm,
              AppSpace.gutter,
              AppSpace.xl,
            ),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('add-product'),
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Add product'),
                ),
              ),
              if (low.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                AttentionCard(
                  key: const Key('low-stock-card'),
                  title:
                      '${low.length} ${low.length == 1 ? 'item' : 'items'} running low',
                  children: [
                    for (final p in low)
                      Text(
                        '${p.name} — ${p.inStock} left',
                        style: AppText.body,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: AppSizes.iconHero,
                        color: AppColors.inkMuted,
                      ),
                      SizedBox(height: AppSpace.sm),
                      Text('No products yet', style: AppText.body),
                    ],
                  ),
                )
              else
                for (final p in products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _ProductTile(product: p, onTap: () => _adjust(p)),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final ProductRow product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('product-${product.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppText.label),
                    Text(
                      '${formatKwacha(product.priceNgwee)} each',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              if (product.isLow)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpace.sm),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.ink,
                    semanticLabel: 'Running low',
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${product.inStock}', style: AppText.amountSmall),
                  const Text('left', style: AppText.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
