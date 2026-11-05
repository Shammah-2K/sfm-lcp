import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/ledger_repository.dart';
import '../../domain/categories.dart';
import '../../domain/ledger.dart';
import '../../domain/money.dart';
import '../../ml/categoriser.dart';
import '../../theme.dart';
import '../widgets/amount_keypad.dart';
import '../widgets/category_chip.dart';

/// Record a sale (FR1) or an expense (FR2), with an on-device category suggestion (FR3).
class EntryScreen extends StatefulWidget {
  const EntryScreen({
    super.key,
    required this.type,
    required this.repository,
    required this.categoriser,
  });

  final EntryType type;
  final LedgerRepository repository;
  final Categoriser categoriser;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _description = TextEditingController();
  String _amountText = '';
  PaymentMethod _method = PaymentMethod.cash;
  Suggestion? _suggestion;
  String? _chosenCategory;
  Timer? _debounce;
  bool _saving = false;
  String? _savedMessage;

  bool get _isSale => widget.type == EntryType.sale;
  CategoryKind get _kind => widget.type.categoryKind;
  int? get _amountNgwee => parseAmountNgwee(_amountText);
  bool get _hasDescription => _description.text.trim().isNotEmpty;

  /// The category that will be saved: the user's pick, else a confident suggestion, else
  /// Sales of goods for a sale with no description.
  String? get _category {
    if (_chosenCategory != null) return _chosenCategory;
    if (!_hasDescription) return _isSale ? defaultSaleCategory : null;
    final s = _suggestion;
    return s != null && s.preselect ? s.categoryCode : null;
  }

  bool get _canSave =>
      !_saving &&
      _amountNgwee != null &&
      (_isSale || _hasDescription) &&
      _category != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _description.dispose();
    super.dispose();
  }

  void _onDescriptionChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(AppSizes.debounce, _refreshSuggestion);
    setState(() {});
  }

  void _refreshSuggestion() {
    if (!mounted) return;
    setState(
      () => _suggestion = widget.categoriser.suggest(_description.text, _kind),
    );
  }

  Future<void> _chooseOther() async {
    final code = await pickCategory(context, _kind, _category);
    if (code != null) setState(() => _chosenCategory = code);
  }

  Future<void> _save() async {
    _debounce?.cancel();
    final amount = _amountNgwee!;
    final description = _description.text.trim();
    // Score the exact text being saved, so the stored prediction matches the stored description.
    final suggestion = widget.categoriser.suggest(description, _kind);
    final finalCategory =
        _chosenCategory ??
        (description.isEmpty
            ? (_isSale ? defaultSaleCategory : null)
            : (suggestion != null && suggestion.preselect
                  ? suggestion.categoryCode
                  : null));
    if (finalCategory == null) {
      // The text changed inside the debounce window and is no longer confidently categorised.
      setState(() => _suggestion = suggestion);
      return;
    }
    setState(() {
      _saving = true;
      _suggestion = suggestion;
    });
    try {
      if (_isSale) {
        await widget.repository.recordSale(
          amountNgwee: amount,
          description: description,
          method: _method,
          finalCategory: finalCategory,
          suggestion: suggestion,
        );
      } else {
        await widget.repository.recordExpense(
          amountNgwee: amount,
          description: description,
          method: _method,
          finalCategory: finalCategory,
          suggestion: suggestion,
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
    setState(() => _savedMessage = 'Saved ${formatNgwee(amount)}');
    await Future<void>.delayed(AppSizes.savedBanner);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = colorForIncome(_isSale);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              _isSale ? Icons.add_card : Icons.payments,
              color: accent,
              size: AppSizes.icon,
            ),
            const SizedBox(width: AppSizes.smallGap),
            Flexible(child: Text(_isSale ? 'Sale' : 'Expense')),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.gutter),
                children: [
                  _AmountDisplay(
                    text: _amountText,
                    valid: _amountNgwee != null,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSizes.gap),
                  AmountKeypad(
                    value: _amountText,
                    onChanged: (v) => setState(() => _amountText = v),
                  ),
                  const SizedBox(height: AppSizes.gutter),
                  TextField(
                    key: const Key('description'),
                    controller: _description,
                    onChanged: _onDescriptionChanged,
                    maxLength: AppSizes.descriptionMax,
                    style: AppText.body,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _isSale ? 'What was sold?' : 'What was it for?',
                      prefixIcon: const Icon(
                        Icons.edit_note,
                        size: AppSizes.icon,
                      ),
                    ),
                  ),
                  _CategorySection(
                    kind: _kind,
                    suggestion: _hasDescription ? _suggestion : null,
                    selected: _category,
                    showDefaultSale: _isSale && !_hasDescription,
                    onSelect: (code) => setState(() => _chosenCategory = code),
                    onOther: _chooseOther,
                  ),
                  const SizedBox(height: AppSizes.gutter),
                  _PaymentToggle(
                    value: _method,
                    onChanged: (m) => setState(() => _method = m),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.gutter),
              child: _savedMessage != null
                  ? _SavedBanner(message: _savedMessage!)
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('save'),
                        onPressed: _canSave ? _save : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: onColorForIncome(_isSale),
                        ),
                        icon: const Icon(Icons.check, size: AppSizes.icon),
                        label: const Text('Save'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.text,
    required this.valid,
    required this.accent,
  });

  final String text;
  final bool valid;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shown = text.isEmpty ? '0' : text;
    return Semantics(
      label: 'Amount',
      value: 'K$shown',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.gutter,
          vertical: AppSizes.gap,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(
            color: valid ? accent : AppColors.outline,
            width: 2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            'K$shown',
            key: const Key('amount'),
            style: AppText.amountEntry.copyWith(
              color: text.isEmpty ? AppColors.muted : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.kind,
    required this.suggestion,
    required this.selected,
    required this.showDefaultSale,
    required this.onSelect,
    required this.onOther,
  });

  final CategoryKind kind;
  final Suggestion? suggestion;
  final String? selected;
  final bool showDefaultSale;
  final ValueChanged<String> onSelect;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final codes = <String>[
      if (showDefaultSale) defaultSaleCategory,
      if (s != null && s.preselect) s.categoryCode,
      if (s != null && !s.preselect) ...s.top3.map((c) => c.code),
    ];
    final current = selected;
    if (current != null && !codes.contains(current)) codes.add(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.gap,
          runSpacing: AppSizes.gap,
          children: [
            for (final code in codes)
              CategoryChip(
                category: categoryByCode[code]!,
                selected: code == selected,
                onTap: () => onSelect(code),
              ),
            OtherCategoryChip(onTap: onOther),
          ],
        ),
        if (s != null) ...[
          const SizedBox(height: AppSizes.smallGap),
          Text(
            'Suggested in ${(s.elapsedMicros / 1000).toStringAsFixed(1)} ms · '
            '${(s.confidence * 100).round()}%',
            key: const Key('suggestion-caption'),
            style: AppText.caption,
          ),
        ],
      ],
    );
  }
}

class _PaymentToggle extends StatelessWidget {
  const _PaymentToggle({required this.value, required this.onChanged});

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(PaymentMethod method, IconData icon, String label) {
      final selected = method == value;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: OutlinedButton.icon(
            key: Key('pay-${method.dbValue}'),
            onPressed: () => onChanged(method),
            icon: Icon(icon, size: AppSizes.icon),
            label: Text(label, textAlign: TextAlign.center),
            style: OutlinedButton.styleFrom(
              backgroundColor: selected ? AppColors.selected : AppColors.card,
              foregroundColor: selected ? AppColors.onSelected : AppColors.text,
              side: BorderSide(
                color: selected ? AppColors.selected : AppColors.outline,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.smallGap,
                vertical: AppSizes.gap,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(PaymentMethod.cash, Icons.payments_outlined, 'Cash'),
        const SizedBox(width: AppSizes.gap),
        option(PaymentMethod.mobileMoney, Icons.phone_iphone, 'Mobile money'),
      ],
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('saved-banner'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: AppSizes.touch),
        padding: const EdgeInsets.all(AppSizes.gutter),
        decoration: BoxDecoration(
          color: AppColors.income,
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.onIncome,
              size: AppSizes.icon,
            ),
            const SizedBox(width: AppSizes.gap),
            Flexible(
              child: Text(
                message,
                style: AppText.button.copyWith(color: AppColors.onIncome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
