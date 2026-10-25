import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/theme/tokens.dart';
import '../categories.dart';
import '../widgets/building_blocks.dart';
import '../widgets/choices.dart';
import '../widgets/ledger_widgets.dart';
import '../widgets/money.dart';
import 'tab_scaffold.dart';

/// S09 Entry detail. Only the category can change; a mistake is cancelled
/// with a reversing entry after the S10 confirmation (FR12).
class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  Stream<EntryRow?>? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entry ??= PortsScope.of(context).ledger.watchEntry(widget.entryId);
  }

  Future<void> _changeCategory(EntryRow e) async {
    final ledger = PortsScope.of(context).ledger;
    final code = await showCategorySheet(
      context,
      type: e.type,
      selected: e.categoryCode,
    );
    if (code != null && code != e.categoryCode) {
      await ledger.changeCategory(e.id, code);
    }
  }

  Future<void> _cancel(EntryRow e) async {
    final ledger = PortsScope.of(context).ledger;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmCancelDialog(entry: e),
    );
    if (confirmed != true) return;
    await ledger.cancelEntry(e.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: detailAppBar('Entry'),
      body: StreamBuilder<EntryRow?>(
        stream: _entry,
        builder: (context, snap) {
          final e = snap.data;
          if (e == null) return const SizedBox.shrink();
          final look = categoryLook(e.categoryCode);
          return ListView(
            padding: const EdgeInsets.all(AppSpace.gutter),
            children: [
              Center(child: CategoryDisc(look, size: 72)),
              const SizedBox(height: AppSpace.md),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SignedAmount(
                    e.amountNgwee,
                    moneyIn: e.isIncome,
                    style: AppText.amountEntry,
                    struck: e.cancelled,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '${e.isIncome ? 'Sale' : 'Expense'} · ${formatDayTime(e.occurredAt)}',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.sm),
              Center(
                child: e.cancelled
                    ? const InfoLine(icon: Icons.block, text: 'Cancelled')
                    : const InfoLine(
                        icon: Icons.cloud_off_outlined,
                        text: 'Saved on this phone',
                      ),
              ),
              const SizedBox(height: AppSpace.lg),
              _DetailRow(
                label: 'Category',
                icon: look.icon,
                value: look.name,
                action: e.cancelled
                    ? null
                    : TextButton(
                        key: const Key('change-category'),
                        onPressed: () => _changeCategory(e),
                        child: const Text('Change'),
                      ),
              ),
              const SizedBox(height: AppSpace.md),
              _DetailRow(
                label: 'Paid with',
                icon: paymentIcon(e.method),
                value: paymentName(e.method),
              ),
              if (e.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                _DetailRow(
                  label: 'Note',
                  icon: Icons.notes,
                  value: e.description,
                ),
              ],
              if (!e.cancelled) ...[
                const SizedBox(height: AppSpace.xl),
                const Text('Made a mistake?', style: AppText.body),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  key: const Key('cancel-entry'),
                  onPressed: () => _cancel(e),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.ink, width: 1.5),
                    minimumSize: const Size.fromHeight(60),
                  ),
                  icon: const Icon(Icons.undo),
                  label: const Text('Cancel this entry'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.icon,
    required this.value,
    this.action,
  });

  final String label;
  final IconData icon;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.inkMuted),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.caption),
                  Text(value, style: AppText.label),
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// S10. Neutral ink, not expense orange: cancelling is a system action.
class _ConfirmCancelDialog extends StatelessWidget {
  const _ConfirmCancelDialog({required this.entry});

  final EntryRow entry;

  @override
  Widget build(BuildContext context) {
    final kind = entry.isIncome ? 'sale' : 'expense';
    return AlertDialog(
      icon: const Icon(Icons.undo, size: AppSizes.iconHero),
      title: Text('Cancel this ${formatKwacha(entry.amountNgwee)} $kind?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'The entry stays in your records and a cancelling entry is added. '
            'Your totals will update.',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const InfoLine(
              icon: Icons.info_outline,
              text: 'No entries are ever deleted.',
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          key: const Key('keep-entry'),
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: const Text('Keep it'),
        ),
        FilledButton(
          key: const Key('confirm-cancel'),
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
          child: const Text('Cancel entry'),
        ),
      ],
    );
  }
}
