import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../widgets/amount_entry.dart';
import '../widgets/building_blocks.dart';
import 'tab_scaffold.dart';

/// S13 New product (FR6, FR7). The price is typed on the keypad, not the
/// system keyboard.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.forPurchase = false});

  /// Opened while recording a stock purchase: the stock comes from that
  /// purchase, so "Stock now" is hidden and stays 0. Otherwise the trader
  /// would count the same items twice.
  final bool forPurchase;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _name = TextEditingController();
  String _priceText = '';
  bool _editingPrice = false;
  int _reorderLevel = 5;
  int _openingStock = 0;
  bool _saving = false;

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
    await PortsScope.of(context).stock.saveProduct(
      ProductDraft(
        name: _name.text.trim(),
        priceNgwee: _priceNgwee!,
        reorderLevel: _reorderLevel,
        openingStock: _openingStock,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final price = _priceNgwee;
    return Scaffold(
      appBar: detailAppBar('New product'),
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
                  if (widget.forPurchase)
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
                label: 'Save product',
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
