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

class CategoryDef {
  const CategoryDef({
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

const List<CategoryDef> codebook = [
  CategoryDef(
    code: 'sales_goods',
    name: 'Sales of goods',
    kind: CategoryKind.income,
    icon: 'shopping_basket',
    sortOrder: 1,
  ),
  CategoryDef(
    code: 'sales_service',
    name: 'Service income',
    kind: CategoryKind.income,
    icon: 'handyman',
    sortOrder: 2,
  ),
  CategoryDef(
    code: 'other_income',
    name: 'Other income',
    kind: CategoryKind.income,
    icon: 'savings',
    sortOrder: 3,
  ),
  CategoryDef(
    code: 'stock',
    name: 'Stock purchase',
    kind: CategoryKind.expense,
    icon: 'inventory_2',
    sortOrder: 4,
  ),
  CategoryDef(
    code: 'transport',
    name: 'Transport',
    kind: CategoryKind.expense,
    icon: 'directions_bus',
    sortOrder: 5,
  ),
  CategoryDef(
    code: 'airtime',
    name: 'Airtime & data',
    kind: CategoryKind.expense,
    icon: 'phone_android',
    sortOrder: 6,
  ),
  CategoryDef(
    code: 'rent_levy',
    name: 'Rent & market fees',
    kind: CategoryKind.expense,
    icon: 'storefront',
    sortOrder: 7,
  ),
  CategoryDef(
    code: 'utilities',
    name: 'Electricity & water',
    kind: CategoryKind.expense,
    icon: 'bolt',
    sortOrder: 8,
  ),
  CategoryDef(
    code: 'wages',
    name: 'Wages',
    kind: CategoryKind.expense,
    icon: 'groups',
    sortOrder: 9,
  ),
  CategoryDef(
    code: 'food',
    name: 'Meals',
    kind: CategoryKind.expense,
    icon: 'restaurant',
    sortOrder: 10,
  ),
  CategoryDef(
    code: 'other_expense',
    name: 'Other expense',
    kind: CategoryKind.expense,
    icon: 'more_horiz',
    sortOrder: 11,
  ),
];

final Map<String, CategoryDef> categoryByCode = {
  for (final c in codebook) c.code: c,
};

List<CategoryDef> categoriesOfKind(CategoryKind kind) =>
    codebook.where((c) => c.kind == kind).toList(growable: false);
