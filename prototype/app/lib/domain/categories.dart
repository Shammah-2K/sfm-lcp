/// The fixed category codebook (BUILD_PROTOTYPE.md section 3).
///
/// Seeded into the `category` table on first run and used by the categoriser to restrict a
/// suggestion to the categories of the entry's kind.
library;

enum CategoryKind {
  income,
  expense;

  static CategoryKind parse(String value) =>
      CategoryKind.values.firstWhere((k) => k.name == value);
}

class Category {
  const Category({
    required this.code,
    required this.name,
    required this.kind,
    required this.icon,
    required this.sortOrder,
  });

  final String code;
  final String name;
  final CategoryKind kind;

  /// Material icon name, as stored in `category.icon`.
  final String icon;
  final int sortOrder;
}

const String defaultSaleCategory = 'sales_goods';

const List<Category> codebook = [
  Category(
    code: 'sales_goods',
    name: 'Sales of goods',
    kind: CategoryKind.income,
    icon: 'shopping_basket',
    sortOrder: 1,
  ),
  Category(
    code: 'sales_service',
    name: 'Service income',
    kind: CategoryKind.income,
    icon: 'handyman',
    sortOrder: 2,
  ),
  Category(
    code: 'other_income',
    name: 'Other income',
    kind: CategoryKind.income,
    icon: 'savings',
    sortOrder: 3,
  ),
  Category(
    code: 'stock',
    name: 'Stock purchase',
    kind: CategoryKind.expense,
    icon: 'inventory_2',
    sortOrder: 4,
  ),
  Category(
    code: 'transport',
    name: 'Transport',
    kind: CategoryKind.expense,
    icon: 'directions_bus',
    sortOrder: 5,
  ),
  Category(
    code: 'airtime',
    name: 'Airtime & data',
    kind: CategoryKind.expense,
    icon: 'phone_android',
    sortOrder: 6,
  ),
  Category(
    code: 'rent_levy',
    name: 'Rent & market fees',
    kind: CategoryKind.expense,
    icon: 'storefront',
    sortOrder: 7,
  ),
  Category(
    code: 'utilities',
    name: 'Electricity & water',
    kind: CategoryKind.expense,
    icon: 'bolt',
    sortOrder: 8,
  ),
  Category(
    code: 'wages',
    name: 'Wages',
    kind: CategoryKind.expense,
    icon: 'groups',
    sortOrder: 9,
  ),
  Category(
    code: 'food',
    name: 'Meals',
    kind: CategoryKind.expense,
    icon: 'restaurant',
    sortOrder: 10,
  ),
  Category(
    code: 'other_expense',
    name: 'Other expense',
    kind: CategoryKind.expense,
    icon: 'more_horiz',
    sortOrder: 11,
  ),
];

final Map<String, Category> categoryByCode = {
  for (final c in codebook) c.code: c,
};

List<Category> categoriesOfKind(CategoryKind kind) =>
    codebook.where((c) => c.kind == kind).toList(growable: false);
