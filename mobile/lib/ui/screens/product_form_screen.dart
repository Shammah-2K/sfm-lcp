import 'package:flutter/material.dart';

import '../../app/ports.dart';
import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../widgets/amount_entry.dart';
import '../widgets/building_blocks.dart';
import 'tab_scaffold.dart';

/// S13 New or edit product (FR6, FR7, UC9). The price is typed on the keypad,
/// not the system keyboard. Editing changes name, price and reorder level;
/// the stock count changes only through S14 Adjust stock, so it stays
/// explained by a reason.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.forPurchase = false, this.product});

  /// Opened while recording a stock purchase: the stock comes from that
  /// purchase, so "Stock now" is hidden and stays 0. Otherwise the trader
  /// would count the same items twice.
  final bool forPurchase;

  /// The product being edited; null for a new one.
  final ProductRow? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final _name = TextEditingController(text: widget.product?.name);
  late String _priceText = switch (widget.product) {
    null => '',
    final p => typedFromNgwee(p.priceNgwee),
  };
  bool _editingPrice = false;
  late int _reorderLevel = widget.product?.reorderLevel ?? 5;
  int _openingStock = 0;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  Future<void> _stopSelling() async {
    final p = widget.product!;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop selling ${p.name}?'),
        content: const Text(
          'It leaves your stock list and the sale screen. Past sales and '
          'purchases are kept. To sell it again, add it with the same name.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            key: const Key('stop-selling-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            child: const Text('Keep it'),
          ),
          FilledButton(
            key: const Key('stop-selling-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            child: const Text('Stop selling'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await PortsScope.of(context).stock.stopSelling(p.id);
    // Adjust stock below this screen shows the product, which is now gone.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  int? get _priceNgwee => parseTypedNgwee(_priceText);

  bool get _canSave =>
      !_saving && _name.text.trim().isNotEmpty && _priceNgwee != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final name = _name.text.trim();
    try {
      await PortsScope.of(context).stock.saveProduct(
        ProductDraft(
          id: widget.product?.id,
          name: name,
          priceNgwee: _priceNgwee!,
          reorderLevel: _reorderLevel,
          openingStock: _openingStock,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is DuplicateProductName
                ? 'You already have $name. Use another name.'
                : 'Not saved. Check the details and try again.',
          ),
        ),
      );
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final price = _priceNgwee;
    return Scaffold(
      appBar: detailAppBar(_isEdit ? 'Edit product' : 'New product'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.gutter),
                children: [
                  const SectionLabel('Name'),
                  TextField(
                    key: const Key('product-name'),
                    controller: _name,
                    style: AppText.body,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'e.g. Bread'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const SectionLabel('Price'),
                  if (_editingPrice) ...[
                    AmountDisplay(
                      text: _priceText,
                      moneyIn: null,
                      valid: price != null,
                    ),
                    const SizedBox(height: AppSpace.md),
                    AmountKeypad(
                      text: _priceText,
                      onChanged: (t) => setState(() => _priceText = t),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _editingPrice = false),
                        child: const Text('Done'),
                      ),
                    ),
                  ] else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                price == null
                                    ? 'No price yet'
                                    : '${formatKwacha(price)} each',
                                style: price == null
                                    ? AppText.body
                                    : AppText.amountSmall,
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key('edit-price'),
                              onPressed: () =>
                                  setState(() => _editingPrice = true),
                              icon: const Icon(Icons.dialpad),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpace.lg),
                  const SectionLabel('Warn me when below'),
                  CountStepper(
                    key: const Key('reorder-level'),
                    value: _reorderLevel,
                    onChanged: (v) => setState(() => _reorderLevel = v),
                    caption: 'left',
                  ),
                  const SizedBox(height: AppSpace.lg),
                  if (_isEdit) ...[
                    InfoLine(
                      icon: Icons.inventory_2_outlined,
                      text:
                          '${widget.product!.inStock} in stock. Change the '
                          'count with Adjust stock.',
                    ),
                    const SizedBox(height: AppSpace.xl),
                    OutlinedButton.icon(
                      key: const Key('stop-selling'),
                      onPressed: _saving ? null : _stopSelling,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size.fromHeight(AppSizes.touch),
                      ),
                      icon: const Icon(Icons.remove_shopping_cart_outlined),
                      label: const Text('Stop selling'),
                    ),
                  ] else if (widget.forPurchase)
                    const InfoLine(
                      icon: Icons.inventory_2_outlined,
                      text: 'The stock is added from this purchase.',
                    )
                  else ...[
                    const SectionLabel('Stock now'),
                    CountStepper(
                      key: const Key('opening-stock'),
                      value: _openingStock,
                      onChanged: (v) => setState(() => _openingStock = v),
                      caption: 'in stock',
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
                label: _isEdit ? 'Save changes' : 'Save product',
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
