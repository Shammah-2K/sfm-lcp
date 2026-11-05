import 'package:flutter/material.dart';

import '../../theme.dart';

/// On-screen keypad for amounts, so the system keyboard is never used for money.
///
/// Keeps the typed text well-formed as it goes: one decimal point, at most two decimals and
/// seven whole-kwacha digits. Whether the value is a valid amount is decided by
/// `parseAmountNgwee`.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static String press(String value, String key) {
    if (key == '⌫') {
      return value.isEmpty ? value : value.substring(0, value.length - 1);
    }
    final dot = value.indexOf('.');
    if (key == '.') {
      return dot >= 0 ? value : (value.isEmpty ? '0.' : '$value.');
    }
    if (dot >= 0) return value.length - dot > 2 ? value : value + key;
    if (value == '0') return key;
    return value.length >= 7 ? value : value + key;
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.smallGap / 2),
                    child: _Key(
                      label: key,
                      onTap: () => onChanged(press(value, key)),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    return SizedBox(
      height: AppSizes.keypadKey,
      child: OutlinedButton(
        key: Key('key-$label'),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.text,
          padding: EdgeInsets.zero,
        ),
        child: isBackspace
            ? const Icon(
                Icons.backspace_outlined,
                size: AppSizes.icon,
                semanticLabel: 'Delete digit',
              )
            : Text(
                label == '.' ? '·' : label,
                style: AppText.keypad,
                semanticsLabel: label == '.' ? 'point' : label,
              ),
      ),
    );
  }
}
