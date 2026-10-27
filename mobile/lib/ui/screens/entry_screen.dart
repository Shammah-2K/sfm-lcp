import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../categories.dart';
import '../widgets/amount_entry.dart';
import '../widgets/building_blocks.dart';
import '../widgets/choices.dart';
import '../widgets/money.dart';
import 'purchase_line_screen.dart';
import 'tab_scaffold.dart';

enum _SaleMode { amount, products }

/// S03/S04 Record sale and S05 Record expense, with the S06 category sheet
/// and the S07 saved banner.
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key, required this.type});

  final EntryType type;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _description = TextEditingController();
  String _amountText = '';
  PaymentMethod _method = PaymentMethod.cash;
  _SaleMode _mode = _SaleMode.amount;
  final Map<String, int> _quantities = {};

  /// Products bought on a stock-purchase expense (FR7), in the order added.
  final List<PurchaseLine> _bought = [];

  /// The trader typed the amount, so it no longer follows the bought lines.
  bool _amountEdited = false;
  List<ProductRow> _products = const [];
  StreamSubscription<List<ProductRow>>? _productSub;

  Suggestion? _suggestion;
  String? _picked;
  Timer? _debounce;
  bool _saving = false;
  String? _savedMessage;

  bool get _isSale => widget.type == EntryType.sale;
  bool get _hasDescription => _description.text.trim().isNotEmpty;

  int? get _typedNgwee => parseTypedNgwee(_amountText);

  /// Sum of the chosen products, shown in the total bar (FR6).
  int get _productsNgwee => _products.fold(
    0,
    (sum, p) => sum + p.priceNgwee * (_quantities[p.id] ?? 0),
  );

  int get _productCount => _quantities.values.fold(0, (a, b) => a + b);

  /// Lines are kept if the category changes, but only a stock purchase
  /// shows or saves them.
  bool get _buyingStock => !_isSale && _category == stockPurchaseCategory;

  List<PurchaseLine> get _boughtLines => _buyingStock ? _bought : const [];

  int get _boughtNgwee => _bought.fold(0, (sum, l) => sum + l.totalNgwee);

  /// The amount defaults to the bought lines' total until the trader types
  /// one (a discount, a delivery fee).
  bool get _amountFollowsLines => _boughtLines.isNotEmpty && !_amountEdited;

  int? get _amountNgwee => _mode == _SaleMode.products
      ? (_productsNgwee > 0 ? _productsNgwee : null)
      : _amountFollowsLines
      ? (_boughtNgwee > 0 ? _boughtNgwee : null)
      : _typedNgwee;

  /// The user's pick, else a confident suggestion, else Sales of goods for a
  /// sale without a description.
  String? get _category {
    if (_mode == _SaleMode.products) return defaultSaleCategory;
    if (_picked != null) return _picked;
    if (!_hasDescription) return _isSale ? defaultSaleCategory : null;
    final s = _suggestion;
    return s != null && s.preselect ? s.top.first.categoryCode : null;
  }

  bool get _canSave =>
      !_saving &&
      _amountNgwee != null &&
      (_isSale || _hasDescription || _boughtLines.isNotEmpty) &&
      _category != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sales pick products; expenses name the products bought.
    _productSub ??= PortsScope.of(
      context,
    ).stock.watchProducts().listen((list) => setState(() => _products = list));
  }

  @override
  void dispose() {
    _productSub?.cancel();
    _debounce?.cancel();
    _description.dispose();
    super.dispose();
  }

  void _onDescriptionChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(AppSizes.suggestionDebounce, _suggest);
    setState(() {});
  }

  Future<void> _suggest() async {
    final s = await PortsScope.of(
      context,
    ).categories.suggest(_description.text, widget.type);
    if (mounted) setState(() => _suggestion = s);
  }

  Future<void> _pickOther() async {
    final code = await showCategorySheet(
      context,
      type: widget.type,
      selected: _category,
    );
    if (code != null) setState(() => _picked = code);
  }

  Future<void> _addBought() async {
    final product = await pickBoughtProduct(
      context,
      products: _products,
      alreadyBought: {for (final l in _bought) l.productId},
    );
    if (product == null || !mounted) return;
    final line = await Navigator.of(context).push<PurchaseLine>(
      MaterialPageRoute(builder: (_) => PurchaseLineScreen(product: product)),
    );
    if (line != null) setState(() => _bought.add(line));
  }

  Future<void> _editBought(int index, ProductRow product) async {
    final line = await Navigator.of(context).push<PurchaseLine>(
      MaterialPageRoute(
        builder: (_) =>
            PurchaseLineScreen(product: product, initial: _bought[index]),
      ),
    );
    if (line != null) setState(() => _bought[index] = line);
  }

  void _useBoughtTotal() => setState(() {
    _amountEdited = false;
    _amountText = '';
  });

  Future<void> _save() async {
    final amount = _amountNgwee!;
    final category = _category!;
    final ledger = PortsScope.of(context).ledger;
    setState(() => _saving = true);
    try {
      if (_isSale) {
        await ledger.recordSale(
          SaleDraft(
            amountNgwee: amount,
            description: _mode == _SaleMode.products
                ? _productsSummary()
                : _description.text.trim(),
            categoryCode: category,
            method: _method,
            lines: [
              if (_mode == _SaleMode.products)
                for (final e in _quantities.entries)
                  if (e.value > 0)
                    SaleLine(productId: e.key, quantity: e.value),
            ],
            suggestion: _mode == _SaleMode.products ? null : _suggestion,
          ),
        );
      } else {
        await ledger.recordExpense(
          ExpenseDraft(
            amountNgwee: amount,
            description: _hasDescription
                ? _description.text.trim()
                : _boughtSummary(),
            categoryCode: category,
            method: _method,
            suggestion: _suggestion,
            lines: _boughtLines,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not saved. Check the details and try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _savedMessage = 'Saved ${formatKwacha(amount)}');
    await Future<void>.delayed(AppSizes.savedBanner);
    if (mounted) Navigator.of(context).pop();
  }

  String _productsSummary() => [
    for (final p in _products)
      if ((_quantities[p.id] ?? 0) > 0) '${_quantities[p.id]} × ${p.name}',
  ].join(', ');

  /// Every expense needs a description; a purchase without one is described
  /// by what was bought, cut to the field's limit.
  String _boughtSummary() {
    final text = [
      for (final l in _bought) '${l.quantity} × ${_productName(l.productId)}',
    ].join(', ');
    return text.length <= AppSizes.descriptionMax
        ? text
        : '${text.substring(0, AppSizes.descriptionMax - 1)}…';
  }

  ProductRow? _productFor(String id) =>
      _products.where((p) => p.id == id).firstOrNull;

  String _productName(String id) => _productFor(id)?.name ?? 'Product';

  @override
  Widget build(BuildContext context) {
    final moneyIn = _isSale;
    final amount = _amountNgwee;
    final saveLabel = amount == null
        ? (_isSale ? 'Save sale' : 'Save expense')
        : (_isSale
              ? 'Save sale (${formatKwacha(amount)})'
              : 'Save expense (−${formatKwacha(amount)})');
    return Scaffold(
      appBar: detailAppBar(
        _isSale ? 'Sale' : 'Expense',
        icon: _isSale ? Icons.add_card : Icons.payments_outlined,
        iconColor: moneyColor(moneyIn: moneyIn),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.sm,
                  AppSpace.gutter,
                  AppSpace.lg,
                ),
                children: [
                  if (_isSale) ...[
                    ChoiceRow<_SaleMode>(
                      choices: const [
                        Choice(_SaleMode.amount, 'Amount', icon: Icons.dialpad),
                        Choice(
                          _SaleMode.products,
                          'Products',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ],
                      value: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                  if (_mode == _SaleMode.amount)
                    ..._amountForm()
                  else
                    _productsForm(),
                  const SizedBox(height: AppSpace.lg),
                  const SectionLabel('Paid with'),
                  ChoiceRow<PaymentMethod>(
                    choices: paymentChoices,
                    value: _method,
                    onChanged: (m) => setState(() => _method = m),
                  ),
                ],
              ),
            ),
            if (_mode == _SaleMode.products)
              _ProductsTotalBar(count: _productCount, ngwee: _productsNgwee),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.sm,
                AppSpace.gutter,
                AppSpace.lg,
              ),
              child: _savedMessage != null
                  ? SavedBanner(message: _savedMessage!)
                  : PrimaryAction(
                      label: saveLabel,
                      color: moneyColor(moneyIn: moneyIn),
                      onPressed: _canSave ? _save : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _amountForm() {
    final moneyIn = _isSale;
    return [
      AmountDisplay(
        text: _amountFollowsLines ? typedFromNgwee(_boughtNgwee) : _amountText,
        moneyIn: moneyIn,
        valid: _amountNgwee != null,
      ),
      const SizedBox(height: AppSpace.md),
      AmountKeypad(
        text: _amountText,
        onChanged: (t) => setState(() {
          _amountText = t;
          _amountEdited = true;
        }),
      ),
      const SizedBox(height: AppSpace.lg),
      TextField(
        key: const Key('description'),
        controller: _description,
        onChanged: _onDescriptionChanged,
        maxLength: AppSizes.descriptionMax,
        style: AppText.body,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: _isSale ? 'What was sold?' : 'What was it for?',
          prefixIcon: const Icon(Icons.edit_note),
        ),
      ),
      const SizedBox(height: AppSpace.xs),
      _CategoryChoice(
        type: widget.type,
        suggestion: _hasDescription ? _suggestion : null,
        selected: _category,
        showDefaultSale: _isSale && !_hasDescription,
        onPick: (code) => setState(() => _picked = code),
        onOther: _pickOther,
      ),
      if (_buyingStock) ...[
        const SizedBox(height: AppSpace.lg),
        ..._boughtSection(),
      ],
    ];
  }

  /// "Products bought" on a stock purchase: each line raises that product's
  /// stock when saved.
  List<Widget> _boughtSection() {
    final typed = _typedNgwee;
    return [
      const SectionLabel('Products bought'),
      for (final (i, line) in _bought.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: _BoughtLineTile(
            name: _productName(line.productId),
            line: line,
            onTap: switch (_productFor(line.productId)) {
              null => null,
              final p => () => _editBought(i, p),
            },
            onRemove: () => setState(() => _bought.removeAt(i)),
          ),
        ),
      OutlinedButton.icon(
        key: const Key('add-bought'),
        onPressed: _addBought,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.touch),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      const SizedBox(height: AppSpace.sm),
      if (_bought.isEmpty)
        const InfoLine(
          icon: Icons.inventory_2_outlined,
          text: 'Add what you bought and your stock goes up.',
        )
      else ...[
        InfoLine(
          key: const Key('bought-total'),
          icon: Icons.calculate_outlined,
          text: 'Products add up to ${formatKwacha(_boughtNgwee)}',
        ),
        if (_amountEdited && typed != _boughtNgwee)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('use-bought-total'),
              onPressed: _useBoughtTotal,
              child: Text('Use ${formatKwacha(_boughtNgwee)} as the amount'),
            ),
          ),
      ],
    ];
  }

  Widget _productsForm() {
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
        child: Text(
          'No products yet. Add them in the Stock tab.',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        for (final p in _products)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: _ProductPickTile(
              product: p,
              quantity: _quantities[p.id] ?? 0,
              onChanged: (q) => setState(() => _quantities[p.id] = q),
            ),
          ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.type,
    required this.suggestion,
    required this.selected,
    required this.showDefaultSale,
    required this.onPick,
    required this.onOther,
  });

  final EntryType type;
  final Suggestion? suggestion;
  final String? selected;
  final bool showDefaultSale;
  final ValueChanged<String> onPick;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final codes = <String>[
      if (showDefaultSale) defaultSaleCategory,
      if (s != null && s.preselect) s.top.first.categoryCode,
      if (s != null && !s.preselect) ...s.top.map((c) => c.categoryCode),
    ];
    final current = selected;
    if (current != null && !codes.contains(current)) codes.add(current);
    final percent = s == null ? null : (s.top.first.confidence * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          children: [
            for (final code in codes)
              CategoryChip(
                look: categoryLook(code),
                selected: code == selected,
                onTap: () => onPick(code),
              ),
            OtherCategoryChip(onTap: onOther),
          ],
        ),
        if (percent != null) ...[
          const SizedBox(height: AppSpace.sm),
          InfoLine(
            key: const Key('suggestion-caption'),
            icon: Icons.auto_awesome_outlined,
            text: s!.preselect
                ? 'Suggested on this phone · $percent% sure'
                : 'Suggested on this phone · $percent% sure — pick one',
          ),
        ],
      ],
    );
  }
}

class _ProductPickTile extends StatelessWidget {
  const _ProductPickTile({
    required this.product,
    required this.quantity,
    required this.onChanged,
  });

  final ProductRow product;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final out = product.isOut;
    final left = out ? 'Out of stock' : '${product.inStock} left';
    return Card(
      color: out ? AppColors.surfaceSunken : AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppText.label),
                      Text(
                        formatKwacha(product.priceNgwee),
                        style: AppText.body,
                      ),
                    ],
                  ),
                ),
                if (product.isLow || out)
                  const Padding(
                    padding: EdgeInsets.only(right: AppSpace.xs),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: AppSizes.iconSmall,
                      color: AppColors.ink,
                    ),
                  ),
                Text(left, style: AppText.captionStrong),
              ],
            ),
            if (!out) ...[
              const SizedBox(height: AppSpace.sm),
              CountStepper(
                key: Key('qty-${product.id}'),
                value: quantity,
                onChanged: (q) => onChanged(q.clamp(0, product.inStock)),
                decreaseLabel: 'One less ${product.name}',
                increaseLabel: 'One more ${product.name}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One product on a stock purchase. Tap to change it; the cross removes it.
class _BoughtLineTile extends StatelessWidget {
  const _BoughtLineTile({
    required this.name,
    required this.line,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final PurchaseLine line;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('bought-${line.productId}'),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${line.quantity} × $name', style: AppText.label),
                      Text(
                        '${formatKwacha(line.unitCostNgwee)} each · '
                        '${formatKwacha(line.totalNgwee)}',
                        style: AppText.body,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: Key('remove-bought-${line.productId}'),
                onPressed: onRemove,
                constraints: const BoxConstraints(
                  minWidth: AppSizes.touch,
                  minHeight: AppSizes.touch,
                ),
                icon: Icon(Icons.close, semanticLabel: 'Remove $name'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinned above the Save button in Products mode; never covers the list.
class _ProductsTotalBar extends StatelessWidget {
  const _ProductsTotalBar({required this.count, required this.ngwee});

  final int count;
  final int ngwee;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.gutter,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'item' : 'items'}',
              style: AppText.label,
            ),
          ),
          const Text('Total ', style: AppText.body),
          Text(
            formatKwacha(ngwee),
            key: const Key('products-total'),
            style: AppText.amountSmall.copyWith(color: AppColors.income),
          ),
        ],
      ),
    );
  }
}
