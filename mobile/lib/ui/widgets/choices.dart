import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../app/view_data.dart';
import '../categories.dart';

/// A large icon-first chip. Selected = ink fill, white text and a check;
/// never colour alone.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onFill : AppColors.ink;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      side: BorderSide(
        color: selected ? AppColors.ink : AppColors.outlineControl,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.ink : AppColors.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: fg, size: AppSizes.icon),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.label.copyWith(color: fg),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AppSpace.sm),
                    Icon(Icons.check, color: fg, size: AppSizes.iconSmall),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.look,
    required this.selected,
    required this.onTap,
  });

  final CategoryLook look;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SelectChip(
    key: Key('category-${look.code}'),
    label: look.name,
    icon: look.icon,
    selected: selected,
    onTap: onTap,
  );
}

class OtherCategoryChip extends StatelessWidget {
  const OtherCategoryChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SelectChip(
    key: const Key('category-other'),
    label: 'Other',
    icon: Icons.apps,
    selected: false,
    onTap: onTap,
  );
}

/// Bottom sheet with every category of [type]. One tap picks and closes;
/// there is no confirm step. Resolves to the chosen code, or null.
Future<String?> showCategorySheet(
  BuildContext context, {
  required EntryType type,
  String? selected,
}) {
  return showModalBottomSheet<String>(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select category', style: AppText.title),
            const SizedBox(height: AppSpace.lg),
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                for (final look in categoriesFor(type))
                  CategoryChip(
                    look: look,
                    selected: look.code == selected,
                    onTap: () => Navigator.of(context).pop(look.code),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class Choice<T> {
  const Choice(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Equal-width toggle buttons: payment method, Day / Week, Amount / Products.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.choices,
    required this.value,
    required this.onChanged,
  });

  final List<Choice<T>> choices;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, c) in choices.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpace.md),
          Expanded(
            child: _ChoiceButton(
              choice: c,
              selected: c.value == value,
              onTap: () => onChanged(c.value),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceButton<T> extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final Choice<T> choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onFill : AppColors.ink;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        key: Key('choice-${choice.value}'),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppColors.ink : AppColors.card,
          foregroundColor: fg,
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.outlineControl,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.md,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (choice.icon != null) ...[
              Icon(choice.icon, size: AppSizes.icon, color: fg),
              const SizedBox(width: AppSpace.sm),
            ],
            Flexible(
              child: Text(
                choice.label,
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<Choice<PaymentMethod>> paymentChoices = [
  Choice(PaymentMethod.cash, 'Cash', icon: Icons.payments_outlined),
  Choice(PaymentMethod.mobileMoney, 'Mobile money', icon: Icons.phone_iphone),
];
