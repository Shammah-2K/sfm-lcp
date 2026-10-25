import 'package:flutter/material.dart';

import '../../app/view_data.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../categories.dart';
import 'money.dart';

IconData paymentIcon(PaymentMethod m) => switch (m) {
  PaymentMethod.cash => Icons.payments_outlined,
  PaymentMethod.mobileMoney => Icons.phone_iphone,
};

String paymentName(PaymentMethod m) => switch (m) {
  PaymentMethod.cash => 'Cash',
  PaymentMethod.mobileMoney => 'Mobile money',
};

/// One ledger row: icon disc · title over time and payment · signed amount.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.onTap});

  final EntryRow entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(entry.categoryCode);
    final title = entry.description.trim().isEmpty
        ? look.name
        : entry.description;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('entry-${entry.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              CategoryDisc(look),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatTime(entry.occurredAt),
                          style: AppText.caption,
                        ),
                        Icon(
                          paymentIcon(entry.method),
                          size: AppSizes.iconSmall,
                          color: AppColors.inkMuted,
                          semanticLabel: paymentName(entry.method),
                        ),
                        if (entry.needsCheck) const _CheckTag(),
                        if (entry.cancelled)
                          const Text('Cancelled', style: AppText.captionStrong),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: SignedAmount(
                    entry.amountNgwee,
                    moneyIn: entry.isIncome,
                    style: AppText.amountSmall,
                    struck: entry.cancelled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckTag extends StatelessWidget {
  const _CheckTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.attentionSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.ink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.ink,
          ),
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              'Check',
              softWrap: false,
              overflow: TextOverflow.fade,
              style: AppText.captionStrong.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Money in / Money out / Profit for today, on the Today screen (answers T4).
class TodayStrip extends StatelessWidget {
  const TodayStrip({super.key, required this.totals});

  final PeriodTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StripCell(
                label: 'Money in',
                icon: Icons.south_west,
                child: SignedAmount(
                  totals.inNgwee,
                  moneyIn: true,
                  style: AppText.label,
                ),
              ),
            ),
            Expanded(
              child: _StripCell(
                label: 'Money out',
                icon: Icons.north_east,
                child: SignedAmount(
                  totals.outNgwee,
                  moneyIn: false,
                  style: AppText.label,
                ),
              ),
            ),
            Expanded(
              child: _StripCell(
                label: 'Profit',
                icon: Icons.equalizer,
                child: ProfitAmount(totals.profitNgwee, style: AppText.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripCell extends StatelessWidget {
  const _StripCell({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppSizes.iconSmall, color: AppColors.inkMuted),
            const SizedBox(width: AppSpace.xs),
            Flexible(child: Text(label, style: AppText.captionStrong)),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ],
    );
  }
}

/// Header pill: cloud-off icon and the number of records waiting to sync.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.sync, required this.onTap});

  final SyncView sync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = sync.waiting;
    final allSent = n == 0 && sync.lastSyncedAt != null;
    final showCount = !allSent && !sync.withdrawn;
    final String label;
    if (sync.withdrawn) {
      label = 'Not taking part. Nothing is sent';
    } else if (allSent) {
      label = 'All records sent';
    } else {
      label = '$n ${n == 1 ? 'record' : 'records'} waiting to sync';
    }
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: const Key('sync-badge'),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.touch,
            minWidth: AppSizes.touch,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allSent && !sync.withdrawn
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    size: AppSizes.iconSmall,
                    color: AppColors.inkMuted,
                  ),
                  if (showCount) ...[
                    const SizedBox(width: AppSpace.sm),
                    Text('$n', style: AppText.label),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// S15: what the sync badge means, who this phone belongs to, and how to stop
/// taking part. [onWithdraw] runs after the participant confirms.
Future<void> showSyncSheet(
  BuildContext context, {
  required String participantCode,
  required SyncView sync,
  required Future<void> Function() onWithdraw,
}) {
  final n = sync.waiting;
  final last = sync.lastSyncedAt;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          0,
          AppSpace.gutter,
          AppSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: AppSizes.iconLarge),
                const SizedBox(width: AppSpace.md),
                Text(participantCode, style: AppText.title),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (sync.withdrawn)
              const Text(
                'You have stopped taking part. Nothing more is sent to the '
                'study. Your records stay on this phone and you can keep using '
                'the app.',
                key: Key('withdrawn-note'),
                style: AppText.body,
              )
            else ...[
              Row(
                children: [
                  Icon(
                    n == 0
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      n == 0
                          ? 'All records sent'
                          : '$n ${n == 1 ? 'record' : 'records'} waiting to sync',
                      style: AppText.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                last == null
                    ? 'Last synced: never'
                    : 'Last synced: ${formatDayTime(last)}',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpace.lg),
              const Text(
                'Your records are safe on this phone. They are sent by '
                'themselves when you have network.',
                style: AppText.body,
              ),
            ],
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                if (!sync.withdrawn)
                  TextButton(
                    key: const Key('stop-taking-part'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                    onPressed: () async {
                      final sure = await showDialog<bool>(
                        context: sheet,
                        builder: (_) => const _WithdrawDialog(),
                      );
                      if (sure != true) return;
                      await onWithdraw();
                      if (sheet.mounted) Navigator.of(sheet).pop();
                    },
                    child: const Text('Stop taking part'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(sheet).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _WithdrawDialog extends StatelessWidget {
  const _WithdrawDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stop taking part?'),
      content: const Text(
        'Nothing more will be sent to the study, and the study will delete what '
        'it has from you. Your records stay on this phone and you can keep using '
        'the app.',
        style: AppText.body,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          key: const Key('withdraw-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: const Text('Keep going'),
        ),
        FilledButton(
          key: const Key('withdraw-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
          child: const Text('Stop'),
        ),
      ],
    );
  }
}

/// A totals row: icon disc · name over count · signed amount.
class CategoryTotalTile extends StatelessWidget {
  const CategoryTotalTile({super.key, required this.total});

  final CategoryTotal total;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(total.categoryCode);
    final moneyIn = look.type == EntryType.sale;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            CategoryDisc(look),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(look.name, style: AppText.label),
                  Text(
                    '${total.count} ${total.count == 1 ? 'entry' : 'entries'}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            SignedAmount(
              total.amountNgwee,
              moneyIn: moneyIn,
              style: AppText.label,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Usually about K20.00" with the amount formatted.
String usuallyAbout(int ngwee) => 'Usually about ${formatKwacha(ngwee)}';
