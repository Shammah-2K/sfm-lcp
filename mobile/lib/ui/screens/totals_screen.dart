import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/dates.dart';
import '../../core/theme/tokens.dart';
import '../widgets/building_blocks.dart';
import '../widgets/choices.dart';
import '../widgets/ledger_widgets.dart';
import '../widgets/money.dart';
import 'tab_scaffold.dart';

enum _Period { day, week }

/// S11 Totals by day or week (FR5).
class TotalsScreen extends StatefulWidget {
  const TotalsScreen({super.key, required this.participantCode});

  final String participantCode;

  @override
  State<TotalsScreen> createState() => _TotalsScreenState();
}

class _TotalsScreenState extends State<TotalsScreen> {
  _Period _period = _Period.day;
  DateTime _anchor = _today();
  Stream<PeriodTotals>? _totals;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _atLatest => _period == _Period.day
      ? _anchor == _today()
      : _today().difference(_anchor).inDays < 7;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _totals ??= _watch();
  }

  Stream<PeriodTotals> _watch() {
    final totals = PortsScope.of(context).totals;
    return _period == _Period.day
        ? totals.watchDay(_anchor)
        : totals.watchWeek(_anchor);
  }

  void _set({_Period? period, DateTime? anchor}) {
    setState(() {
      _period = period ?? _period;
      _anchor = anchor ?? _anchor;
      _totals = _watch();
    });
  }

  void _step(int direction) {
    final days = _period == _Period.day ? 1 : 7;
    _set(anchor: _anchor.add(Duration(days: days * direction)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabAppBar(
        title: 'Totals',
        icon: Icons.bar_chart,
        participantCode: widget.participantCode,
      ),
      body: StreamBuilder<PeriodTotals>(
        stream: _totals,
        builder: (context, snap) {
          final t = snap.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.sm,
              AppSpace.gutter,
              AppSpace.xl,
            ),
            children: [
              ChoiceRow<_Period>(
                choices: const [
                  Choice(_Period.day, 'Day'),
                  Choice(_Period.week, 'Week'),
                ],
                value: _period,
                onChanged: (p) => _set(period: p, anchor: _today()),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  _StepButton(
                    key: const Key('period-back'),
                    icon: Icons.chevron_left,
                    label: _period == _Period.day
                        ? 'Previous day'
                        : 'Previous week',
                    onTap: () => _step(-1),
                  ),
                  Expanded(
                    child: Text(
                      t == null
                          ? ''
                          : (_period == _Period.day
                                ? formatDay(t.start)
                                : formatWeek(t.start, t.end)),
                      key: const Key('period-label'),
                      style: AppText.label,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _StepButton(
                    key: const Key('period-next'),
                    icon: Icons.chevron_right,
                    label: _period == _Period.day ? 'Next day' : 'Next week',
                    onTap: _atLatest ? null : () => _step(1),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              if (t != null) ..._body(t),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _body(PeriodTotals t) {
    String entries(int n) => '$n ${n == 1 ? 'entry' : 'entries'}';
    return [
      _TotalTile(
        key: const Key('total-in'),
        label: 'Money in',
        sub: entries(t.inCount),
        icon: Icons.south_west,
        moneyIn: true,
        amount: SignedAmount(t.inNgwee, moneyIn: true),
      ),
      const SizedBox(height: AppSpace.md),
      _TotalTile(
        key: const Key('total-out'),
        label: 'Money out',
        sub: entries(t.outCount),
        icon: Icons.north_east,
        moneyIn: false,
        amount: SignedAmount(t.outNgwee, moneyIn: false),
      ),
      const SizedBox(height: AppSpace.md),
      Container(
        key: const Key('total-profit'),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.equalizer,
              color: AppColors.onFill,
              size: AppSizes.iconLarge,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profit',
                    style: AppText.label.copyWith(color: AppColors.onFill),
                  ),
                  Text(
                    t.profitNgwee < 0
                        ? 'Loss'
                        : (t.profitNgwee > 0 ? 'Gain' : 'Even'),
                    style: AppText.caption.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ProfitAmount(
                  t.profitNgwee,
                  style: AppText.amount.copyWith(color: AppColors.onFill),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.xl),
      const SectionLabel('By category'),
      if (t.byCategory.isEmpty)
        const Text('No entries in this period', style: AppText.body)
      else
        for (final c in t.byCategory)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: CategoryTotalTile(total: c),
          ),
    ];
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    super.key,
    required this.label,
    required this.sub,
    required this.icon,
    required this.moneyIn,
    required this.amount,
  });

  final String label;
  final String sub;
  final IconData icon;
  final bool moneyIn;
  final Widget amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: AppSizes.iconDisc,
              height: AppSizes.iconDisc,
              decoration: BoxDecoration(
                color: moneyTint(moneyIn: moneyIn),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: moneyColor(moneyIn: moneyIn)),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.label),
                  Text(sub, style: AppText.caption),
                ],
              ),
            ),
            Flexible(
              child: FittedBox(fit: BoxFit.scaleDown, child: amount),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.touch,
      height: AppSizes.touch,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon, size: AppSizes.iconLarge, semanticLabel: label),
      ),
    );
  }
}
