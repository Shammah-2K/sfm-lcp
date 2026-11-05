import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import 'money.dart';

/// The large amount being typed, right-aligned in a bordered box whose border
/// takes the money-direction colour once the amount is valid. With [moneyIn]
/// null (a price, not a transaction) it stays neutral ink.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.text,
    required this.moneyIn,
    required this.valid,
  });

  final String text;
  final bool? moneyIn;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final label = typedAmountLabel(text);
    final sign = moneyIn == false && text.isNotEmpty ? '−' : '';
    final tone = switch (moneyIn) {
      null => AppColors.ink,
      final m => moneyColor(moneyIn: m),
    };
    return Semantics(
      label: 'Amount',
      value: label,
      excludeSemantics: true,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: valid ? tone : AppColors.outlineControl,
            width: valid ? AppSizes.focusBorder : 1,
          ),
        ),
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$sign$label',
            key: const Key('amount-display'),
            style: AppText.amountEntry.copyWith(
              color: text.isEmpty ? AppColors.inkMuted : tone,
            ),
          ),
        ),
      ),
    );
  }
}

/// On-screen number pad, so the system keyboard is never used for money.
/// It keeps the text well-formed as it is typed: one point, at most two
/// decimals, at most seven whole-kwacha digits.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.text, required this.onChanged});

  final String text;
  final ValueChanged<String> onChanged;

  static const String backspace = 'back';
  static const int maxWholeDigits = 7;

  static String press(String text, String key) {
    if (key == backspace) {
      return text.isEmpty ? text : text.substring(0, text.length - 1);
    }
    final dot = text.indexOf('.');
    if (key == '.') {
      if (dot >= 0) return text;
      return text.isEmpty ? '0.' : '$text.';
    }
    if (dot >= 0) return text.length - dot > 2 ? text : text + key;
    if (text == '0') return key;
    return text.length >= maxWholeDigits ? text : text + key;
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', backspace],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (final (j, k) in row.indexed) ...[
                if (j > 0) const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _Key(value: k, onTap: () => onChanged(press(text, k))),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget face = switch (value) {
      AmountKeypad.backspace => const Icon(
        Icons.backspace_outlined,
        size: AppSizes.iconLarge,
        semanticLabel: 'Delete digit',
      ),
      '.' => const Text('·', style: AppText.keypad, semanticsLabel: 'point'),
      _ => Text(value, style: AppText.keypad),
    };
    return OutlinedButton(
      key: Key('key-$value'),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size.fromHeight(AppSizes.keypadKey),
      ),
      child: face,
    );
  }
}
