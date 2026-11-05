import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../categories.dart';
import '../../app/view_data.dart';

Color moneyColor({required bool moneyIn}) =>
    moneyIn ? AppColors.income : AppColors.expense;

Color moneyTint({required bool moneyIn}) =>
    moneyIn ? AppColors.incomeTint : AppColors.expenseTint;

/// A signed, coloured amount: `+K50.00` in income teal, `−K25.00` in expense
/// orange. Colour is never the only signal; the sign always travels with it.
class SignedAmount extends StatelessWidget {
  const SignedAmount(
    this.ngwee, {
    super.key,
    required this.moneyIn,
    this.style = AppText.amount,
    this.struck = false,
  });

  final int ngwee;
  final bool moneyIn;
  final TextStyle style;

  /// Cancelled entries keep their amount visible, struck through and muted.
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final color = struck ? AppColors.inkMuted : moneyColor(moneyIn: moneyIn);
    return Text(
      formatSignedKwacha(ngwee, moneyIn: moneyIn),
      maxLines: 1,
      softWrap: false,
      style: style.copyWith(
        color: color,
        decoration: struck ? TextDecoration.lineThrough : null,
      ),
    );
  }
}

/// Profit or loss: dark text with its own sign, never income or expense colour.
class ProfitAmount extends StatelessWidget {
  const ProfitAmount(this.ngwee, {super.key, this.style = AppText.amount});

  final int ngwee;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final text = ngwee > 0 ? '+${formatKwacha(ngwee)}' : formatKwacha(ngwee);
    return Text(text, maxLines: 1, softWrap: false, style: style);
  }
}

/// The 44 dp tinted disc with a category icon used in lists and totals.
class CategoryDisc extends StatelessWidget {
  const CategoryDisc(this.look, {super.key, this.size = AppSizes.iconDisc});

  final CategoryLook look;
  final double size;

  @override
  Widget build(BuildContext context) {
    final moneyIn = look.type == EntryType.sale;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: moneyTint(moneyIn: moneyIn),
        shape: BoxShape.circle,
      ),
      child: Icon(
        look.icon,
        size: size * 0.56,
        color: moneyColor(moneyIn: moneyIn),
      ),
    );
  }
}
