/// The category codebook (Chapter 3, Category Scheme). The single source for
/// the database seed and for the names the UI shows.
library;

import '../app/view_data.dart';

class CodebookCategory {
  const CodebookCategory({
    required this.code,
    required this.name,
    required this.type,
    required this.icon,
    required this.sortOrder,
  });

  /// `category.code`, the primary key.
  final String code;
  final String name;

  /// Sales use income categories, expenses use expense categories; the
  /// `trg_category_kind` trigger enforces this in the database.
  final EntryType type;

  /// Material Symbols name stored in `category.icon`.
  final String icon;
  final int sortOrder;

  /// The `category.kind` value: `income` or `expense`.
  String get kind => type == EntryType.sale ? 'income' : 'expense';
}

const List<CodebookCategory> codebook = [
  CodebookCategory(
    code: 'sales_goods',
    name: 'Sales of goods',
    type: EntryType.sale,
    icon: 'shopping_basket',
    sortOrder: 1,
  ),
  CodebookCategory(
    code: 'sales_service',
    name: 'Service income',
    type: EntryType.sale,
    icon: 'handyman',
    sortOrder: 2,
  ),
  CodebookCategory(
    code: 'other_income',
    name: 'Other income',
    type: EntryType.sale,
    icon: 'savings',
    sortOrder: 3,
  ),
  CodebookCategory(
    code: 'stock',
    name: 'Stock purchase',
    type: EntryType.expense,
    icon: 'inventory_2',
    sortOrder: 4,
  ),
  CodebookCategory(
    code: 'transport',
    name: 'Transport',
    type: EntryType.expense,
    icon: 'directions_bus',
    sortOrder: 5,
  ),
  CodebookCategory(
    code: 'airtime',
    name: 'Airtime & data',
    type: EntryType.expense,
    icon: 'phone_android',
    sortOrder: 6,
  ),
  CodebookCategory(
    code: 'rent_levy',
    name: 'Rent & market fees',
    type: EntryType.expense,
    icon: 'storefront',
    sortOrder: 7,
  ),
  CodebookCategory(
    code: 'utilities',
    name: 'Electricity & water',
    type: EntryType.expense,
    icon: 'bolt',
    sortOrder: 8,
  ),
  CodebookCategory(
    code: 'wages',
    name: 'Wages',
    type: EntryType.expense,
    icon: 'groups',
    sortOrder: 9,
  ),
  CodebookCategory(
    code: 'food',
    name: 'Meals',
    type: EntryType.expense,
    icon: 'restaurant',
    sortOrder: 10,
  ),
  CodebookCategory(
    code: 'other_expense',
    name: 'Other expense',
    type: EntryType.expense,
    icon: 'more_horiz',
    sortOrder: 11,
  ),
];

/// A sale saved without a description goes here.
const String defaultSaleCategory = 'sales_goods';

/// Expenses in this category may list the products bought (FR7).
const String stockPurchaseCategory = 'stock';
