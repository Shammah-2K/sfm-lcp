import 'package:flutter/material.dart';

import '../domain/categories.dart';

const Map<String, IconData> _iconsByName = {
  'shopping_basket': Icons.shopping_basket,
  'handyman': Icons.handyman,
  'savings': Icons.savings,
  'inventory_2': Icons.inventory_2,
  'directions_bus': Icons.directions_bus,
  'phone_android': Icons.phone_android,
  'storefront': Icons.storefront,
  'bolt': Icons.bolt,
  'groups': Icons.groups,
  'restaurant': Icons.restaurant,
  'more_horiz': Icons.more_horiz,
};

/// The Material icon for a category's stored icon name (`category.icon`).
IconData iconFor(CategoryDef category) => _iconsByName[category.icon]!;
