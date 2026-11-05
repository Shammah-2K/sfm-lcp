import 'package:flutter/material.dart';

import '../app/view_data.dart';
import '../domain/codebook.dart';

export '../domain/codebook.dart'
    show defaultSaleCategory, stockPurchaseCategory;

/// How a codebook category looks on screen.
class CategoryLook {
  const CategoryLook(this.code, this.name, this.type, this.icon);

  final String code;
  final String name;
  final EntryType type;
  final IconData icon;
}

/// Outlined Material icons for the icon names stored in `category.icon`.
const Map<String, IconData> _icons = {
  'shopping_basket': Icons.shopping_basket_outlined,
  'handyman': Icons.handyman_outlined,
  'savings': Icons.savings_outlined,
  'inventory_2': Icons.inventory_2_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'phone_android': Icons.phone_android_outlined,
  'storefront': Icons.storefront_outlined,
  'bolt': Icons.bolt_outlined,
  'groups': Icons.groups_outlined,
  'restaurant': Icons.restaurant_outlined,
  'more_horiz': Icons.more_horiz,
};

final List<CategoryLook> categoryLooks = [
  for (final c in codebook)
    CategoryLook(c.code, c.name, c.type, _icons[c.icon]!),
];

final Map<String, CategoryLook> _byCode = {
  for (final c in categoryLooks) c.code: c,
};

CategoryLook categoryLook(String code) =>
    _byCode[code] ??
    (throw ArgumentError.value(code, 'code', 'not in the category codebook'));

List<CategoryLook> categoriesFor(EntryType type) =>
    categoryLooks.where((c) => c.type == type).toList(growable: false);
