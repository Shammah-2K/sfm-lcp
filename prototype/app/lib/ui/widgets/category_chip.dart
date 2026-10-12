import 'package:flutter/material.dart';

import '../../domain/categories.dart';
import '../../theme.dart';
import '../category_icons.dart';

/// Large icon-first category button used for suggestions and the full category grid.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryDef category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onSelected : AppColors.text;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.selected : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
          side: BorderSide(
            color: selected ? AppColors.selected : AppColors.outline,
          ),
        ),
        child: InkWell(
          key: Key('category-${category.code}'),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.chipRadius),
          ),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touch),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.gutter,
                vertical: AppSizes.smallGap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconFor(category), color: fg, size: AppSizes.icon),
                  const SizedBox(width: AppSizes.smallGap),
                  Flexible(
                    child: Text(
                      category.name,
                      style: AppText.label.copyWith(color: fg),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AppSizes.smallGap),
                    Icon(
                      Icons.check_circle,
                      color: fg,
                      size: AppSizes.smallIcon,
                    ),
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

/// The "Other" chip that opens the grid of every category of one kind.
class OtherCategoryChip extends StatelessWidget {
  const OtherCategoryChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('category-other'),
      onPressed: onTap,
      icon: const Icon(Icons.apps, size: AppSizes.icon),
      label: Text('Other', style: AppText.label),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
      ),
    );
  }
}

/// Bottom sheet listing every category of [kind]; resolves to the chosen code.
Future<String?> pickCategory(
  BuildContext context,
  CategoryKind kind,
  String? selected,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.gutter,
          0,
          AppSizes.gutter,
          AppSizes.gutter,
        ),
        child: Wrap(
          spacing: AppSizes.gap,
          runSpacing: AppSizes.gap,
          children: [
            for (final category in categoriesOfKind(kind))
              CategoryChip(
                category: category,
                selected: category.code == selected,
                onTap: () => Navigator.of(context).pop(category.code),
              ),
          ],
        ),
      ),
    ),
  );
}
