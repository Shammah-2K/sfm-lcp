import 'package:flutter/material.dart';

import '../app/view_data.dart';

/// How each codebook category looks (Chapter 3 codebook; brief section 5).
/// The codes are the `category.code` values seeded in the database.
class CategoryLook {
  const CategoryLook(this.code, this.name, this.type, this.icon);

  final String code;
  final String name;

  /// Sales take income categories; expenses take expense categories.
  final EntryType type;
  final IconData icon;
}

const List<CategoryLook> categoryLooks = [
  CategoryLook(
    'sales_goods',
    'Sales of goods',
    EntryType.sale,
    Icons.shopping_basket_outlined,
  ),
  CategoryLook(
    'sales_service',
    'Service income',
    EntryType.sale,
    Icons.handyman_outlined,
  ),
  CategoryLook(
    'other_income',
    'Other income',
    EntryType.sale,
    Icons.savings_outlined,
  ),
  CategoryLook(
    'stock',
    'Stock purchase',
    EntryType.expense,
    Icons.inventory_2_outlined,
  ),
  CategoryLook(
    'transport',
    'Transport',
    EntryType.expense,
    Icons.directions_bus_outlined,
  ),
  CategoryLook(
    'airtime',
    'Airtime & data',
    EntryType.expense,
    Icons.phone_android_outlined,
  ),
  CategoryLook(
    'rent_levy',
    'Rent & market fees',
    EntryType.expense,
    Icons.storefront_outlined,
  ),
  CategoryLook(
    'utilities',
    'Electricity & water',
    EntryType.expense,
    Icons.bolt_outlined,
  ),
  CategoryLook('wages', 'Wages', EntryType.expense, Icons.groups_outlined),
  CategoryLook('food', 'Meals', EntryType.expense, Icons.restaurant_outlined),
  CategoryLook(
    'other_expense',
    'Other expense',
    EntryType.expense,
    Icons.more_horiz,
  ),
];

/// The category a sale with no description is saved under.
const String defaultSaleCategory = 'sales_goods';

final Map<String, CategoryLook> _byCode = {
  for (final c in categoryLooks) c.code: c,
};

CategoryLook categoryLook(String code) =>
    _byCode[code] ??
    (throw ArgumentError.value(code, 'code', 'not in the category codebook'));

List<CategoryLook> categoriesFor(EntryType type) =>
    categoryLooks.where((c) => c.type == type).toList(growable: false);
