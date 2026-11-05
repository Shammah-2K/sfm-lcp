import 'package:drift/drift.dart';

import '../app/ports.dart';
import '../app/view_data.dart';
import 'database.dart';
import 'lusaka_time.dart';
import 'session_repository.dart';

/// Day and week totals (FR5).
///
/// Amounts are net: a reversal row carries the negative amount of its
/// original, so summing every row in the window cancels a cancelled entry
/// exactly — the same arithmetic as the schema's `v_daily_summary` view (a
/// test checks the two agree). Counts include only originals that have not
/// been cancelled, so "3 entries" means three entries the user still sees.
class TotalsRepository implements TotalsPort {
  TotalsRepository(this._db, this._business);

  final AppDatabase _db;
  final BusinessRef _business;

  @override
  Stream<PeriodTotals> watchDay(DateTime day) => _watch(lusakaDay(day));

  @override
  Stream<PeriodTotals> watchWeek(DateTime anyDayInWeek) =>
      _watch(lusakaWeek(anyDayInWeek));

  Stream<PeriodTotals> _watch(TimeWindow w) async* {
    final business = await _business.idOrNull();
    if (business == null) {
      yield _empty(w);
      return;
    }
    final vars = [
      Variable<String>(business),
      Variable<int>(w.startMs),
      Variable<int>(w.endMs),
    ];
    const inWindow =
        'e.business_id = ? AND e.occurred_at >= ? AND e.occurred_at < ?';
    const live =
        'e.reverses_id IS NULL AND NOT EXISTS '
        '(SELECT 1 FROM ledger_entry r WHERE r.reverses_id = e.id)';

    final totals = _db.customSelect(
      'SELECT '
      "COALESCE(SUM(CASE WHEN e.entry_type = 'sale' THEN e.amount_ngwee END), 0) AS in_ngwee, "
      "COALESCE(SUM(CASE WHEN e.entry_type = 'expense' THEN e.amount_ngwee END), 0) AS out_ngwee, "
      "COALESCE(SUM(CASE WHEN e.entry_type = 'sale' AND $live THEN 1 END), 0) AS in_count, "
      "COALESCE(SUM(CASE WHEN e.entry_type = 'expense' AND $live THEN 1 END), 0) AS out_count "
      'FROM ledger_entry e WHERE $inWindow',
      variables: vars,
      readsFrom: {_db.ledgerEntry},
    );
    final byCategory = _db.customSelect(
      'SELECT e.final_category AS code, SUM(e.amount_ngwee) AS amount, '
      'COALESCE(SUM(CASE WHEN $live THEN 1 END), 0) AS n '
      'FROM ledger_entry e WHERE $inWindow '
      'GROUP BY e.final_category HAVING SUM(e.amount_ngwee) <> 0 '
      'ORDER BY ABS(SUM(e.amount_ngwee)) DESC',
      variables: vars,
      readsFrom: {_db.ledgerEntry},
    );

    // Both queries watch ledger_entry; re-read both whenever it changes.
    yield* totals.watchSingle().asyncMap((t) async {
      final cats = await byCategory.get();
      final inNgwee = t.read<int>('in_ngwee');
      final outNgwee = t.read<int>('out_ngwee');
      return PeriodTotals(
        start: w.start,
        end: w.last,
        inNgwee: inNgwee,
        outNgwee: outNgwee,
        profitNgwee: inNgwee - outNgwee,
        inCount: t.read<int>('in_count'),
        outCount: t.read<int>('out_count'),
        byCategory: [
          for (final c in cats)
            CategoryTotal(
              categoryCode: c.read<String>('code'),
              amountNgwee: c.read<int>('amount'),
              count: c.read<int>('n'),
            ),
        ],
      );
    });
  }

  static PeriodTotals _empty(TimeWindow w) => PeriodTotals(
    start: w.start,
    end: w.last,
    inNgwee: 0,
    outNgwee: 0,
    profitNgwee: 0,
    inCount: 0,
    outCount: 0,
    byCategory: const [],
  );
}
