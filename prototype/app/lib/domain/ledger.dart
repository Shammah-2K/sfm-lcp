import 'categories.dart';

enum EntryType {
  sale('sale', CategoryKind.income),
  expense('expense', CategoryKind.expense);

  const EntryType(this.dbValue, this.categoryKind);

  final String dbValue;
  final CategoryKind categoryKind;

  static EntryType parse(String value) =>
      EntryType.values.firstWhere((t) => t.dbValue == value);
}

enum PaymentMethod {
  cash('cash'),
  mobileMoney('mobile_money');

  const PaymentMethod(this.dbValue);

  final String dbValue;

  static PaymentMethod parse(String value) =>
      PaymentMethod.values.firstWhere((m) => m.dbValue == value);
}

/// One saved row of `ledger_entry`, with timestamps as UTC [DateTime]s.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.businessId,
    required this.entryType,
    required this.amountNgwee,
    required this.description,
    required this.paymentMethod,
    required this.predictedCategory,
    required this.categoryConfidence,
    required this.finalCategory,
    required this.modelVersion,
    required this.occurredAt,
  });

  final String id;
  final String businessId;
  final EntryType entryType;
  final int amountNgwee;
  final String description;
  final PaymentMethod paymentMethod;
  final String? predictedCategory;
  final double? categoryConfidence;
  final String finalCategory;
  final String? modelVersion;
  final DateTime occurredAt;
}

/// A ledger entry joined with its confirmed category, for the recent-entries list.
class EntryView {
  const EntryView(this.entry, this.category);

  final LedgerEntry entry;
  final CategoryDef category;

  /// The description when there is one, otherwise the category name.
  String get label =>
      entry.description.trim().isEmpty ? category.name : entry.description;
}
