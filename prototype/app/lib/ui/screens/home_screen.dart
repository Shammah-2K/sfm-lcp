import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/ledger_repository.dart';
import '../../domain/ledger.dart';
import '../../domain/money.dart';
import '../../ml/categoriser.dart';
import '../../theme.dart';
import '../category_icons.dart';
import 'entry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.participantCode,
    required this.repository,
    required this.categoriser,
  });

  final String participantCode;
  final LedgerRepository repository;
  final Categoriser categoriser;

  void _open(BuildContext context, EntryType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntryScreen(
          type: type,
          repository: repository,
          categoriser: categoriser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.person, size: AppSizes.icon),
            const SizedBox(width: AppSizes.smallGap),
            Flexible(
              child: Text(participantCode, key: const Key('participant-code')),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.gutter),
            child: _OutboxBadge(count: repository.watchPendingSyncCount()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.gutter),
              child: Row(
                children: [
                  Expanded(
                    child: _BigButton(
                      key: const Key('new-sale'),
                      label: 'Sale',
                      icon: Icons.add_card,
                      income: true,
                      onTap: () => _open(context, EntryType.sale),
                    ),
                  ),
                  const SizedBox(width: AppSizes.gap),
                  Expanded(
                    child: _BigButton(
                      key: const Key('new-expense'),
                      label: 'Expense',
                      icon: Icons.payments,
                      income: false,
                      onTap: () => _open(context, EntryType.expense),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<EntryView>>(
                stream: repository.watchRecent(),
                builder: (context, snapshot) {
                  final entries = snapshot.data ?? const <EntryView>[];
                  if (entries.isEmpty) return const _EmptyLedger();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.gutter,
                      0,
                      AppSizes.gutter,
                      AppSizes.gutter,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSizes.smallGap),
                    itemBuilder: (_, i) => _EntryTile(view: entries[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.income,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool income;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = onColorForIncome(income);
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: colorForIncome(income),
        foregroundColor: fg,
        minimumSize: const Size.fromHeight(AppSizes.bigButton),
        padding: const EdgeInsets.all(AppSizes.gap),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.bigIcon, color: fg),
          const SizedBox(height: AppSizes.smallGap),
          Text(
            label,
            style: AppText.button.copyWith(color: fg),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OutboxBadge extends StatelessWidget {
  const _OutboxBadge({required this.count});

  final Stream<int> count;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: count,
      builder: (context, snapshot) {
        final n = snapshot.data ?? 0;
        final records = n == 1 ? 'record' : 'records';
        return Semantics(
          label: 'Offline ready. $n saved $records waiting to sync',
          excludeSemantics: true,
          child: Container(
            key: const Key('outbox-badge'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.gap,
              vertical: AppSizes.smallGap,
            ),
            decoration: BoxDecoration(
              color: AppColors.badge,
              borderRadius: BorderRadius.circular(AppSizes.chipRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: AppSizes.smallIcon,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSizes.smallGap),
                Text('$n', style: AppText.label),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.view});

  final EntryView view;
  static final DateFormat _time = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final entry = view.entry;
    final income = entry.entryType == EntryType.sale;
    final color = colorForIncome(income);
    final mobile = entry.paymentMethod == PaymentMethod.mobileMoney;
    final sign = income ? '+' : '−';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.gap),
        child: Row(
          children: [
            Container(
              width: AppSizes.listIcon,
              height: AppSizes.listIcon,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconFor(view.category),
                color: color,
                size: AppSizes.icon,
              ),
            ),
            const SizedBox(width: AppSizes.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.label,
                    style: AppText.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.smallGap / 2),
                  Row(
                    children: [
                      Text(
                        _time.format(entry.occurredAt.toLocal()),
                        style: AppText.caption,
                      ),
                      const SizedBox(width: AppSizes.smallGap),
                      Icon(
                        mobile ? Icons.phone_iphone : Icons.payments_outlined,
                        size: AppSizes.smallIcon,
                        color: AppColors.muted,
                        semanticLabel: mobile ? 'mobile money' : 'cash',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.gap),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$sign${formatNgwee(entry.amountNgwee)}',
                  style: AppText.amount.copyWith(color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long,
              size: AppSizes.bigIcon,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSizes.smallGap),
            Text(
              'No entries yet',
              style: AppText.body.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
