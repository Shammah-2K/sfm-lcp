import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/dates.dart';
import '../../core/theme/tokens.dart';
import '../categories.dart';
import '../widgets/building_blocks.dart';
import '../widgets/ledger_widgets.dart';
import '../widgets/money.dart';
import 'entry_detail_screen.dart';
import 'entry_screen.dart';
import 'tab_scaffold.dart';

/// S02 Today, with the S08 "Is this right?" check when an entry is flagged.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.participantCode});

  final String participantCode;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // Held in state rather than in StreamBuilders inside the lazy ListView,
  // which would re-subscribe each time a section scrolls back into view.
  List<EntryRow> _entries = const [];
  UnusualEntry? _check;
  PeriodTotals? _totals;
  final List<StreamSubscription<Object?>> _subs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subs.isNotEmpty) return;
    final ports = PortsScope.of(context);
    _subs.addAll([
      ports.ledger.watchToday().listen((v) => setState(() => _entries = v)),
      ports.ledger.watchNeedsCheck().listen((v) => setState(() => _check = v)),
      ports.totals
          .watchDay(DateTime.now())
          .listen((v) => setState(() => _totals = v)),
    ]);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _record(EntryType type) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => EntryScreen(type: type)));
  }

  void _open(EntryRow entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryDetailScreen(entryId: entry.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabAppBar(
        title: 'Today',
        icon: Icons.today,
        participantCode: widget.participantCode,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xl,
        ),
        children: [
          if (_totals != null)
            TodayStrip(key: const Key('today-strip'), totals: _totals!),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: HeroButton(
                  key: const Key('new-sale'),
                  label: 'Sale',
                  icon: Icons.add_card,
                  moneyIn: true,
                  onTap: () => _record(EntryType.sale),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: HeroButton(
                  key: const Key('new-expense'),
                  label: 'Expense',
                  icon: Icons.payments_outlined,
                  moneyIn: false,
                  onTap: () => _record(EntryType.expense),
                ),
              ),
            ],
          ),
          if (_check case final unusual?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.lg),
              child: _UnusualCard(
                unusual: unusual,
                onFix: () => _open(unusual.entry),
                onKeep: () => PortsScope.of(
                  context,
                ).ledger.confirmUnusual(unusual.entry.id),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          const SectionLabel('Recent entries'),
          if (_entries.isEmpty)
            const _EmptyDay()
          else
            for (final e in _entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: EntryTile(entry: e, onTap: () => _open(e)),
              ),
        ],
      ),
    );
  }
}

class _UnusualCard extends StatelessWidget {
  const _UnusualCard({
    required this.unusual,
    required this.onFix,
    required this.onKeep,
  });

  final UnusualEntry unusual;
  final VoidCallback onFix;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final e = unusual.entry;
    final look = categoryLook(e.categoryCode);
    return AttentionCard(
      key: const Key('unusual-card'),
      title: 'Is this right?',
      // Stacked, primary first: side by side, the labels wrap on ordinary
      // phones with Atkinson Hyperlegible.
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const Key('unusual-keep'),
            onPressed: onKeep,
            style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
            icon: const Icon(Icons.check),
            label: const Text('Yes, keep it'),
          ),
          const SizedBox(height: AppSpace.md),
          OutlinedButton.icon(
            key: const Key('unusual-fix'),
            onPressed: onFix,
            icon: const Icon(Icons.undo),
            label: const Text('Fix it'),
          ),
        ],
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(look.name, style: AppText.label)),
                  Text(formatTime(e.occurredAt), style: AppText.caption),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              SignedAmount(e.amountNgwee, moneyIn: e.isIncome),
              if (unusual.usualNgwee case final usual?) ...[
                const SizedBox(height: AppSpace.xs),
                Text(usuallyAbout(usual), style: AppText.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: AppSizes.iconHero,
            color: AppColors.inkMuted,
          ),
          SizedBox(height: AppSpace.sm),
          Text('No entries yet today', style: AppText.body),
        ],
      ),
    );
  }
}
