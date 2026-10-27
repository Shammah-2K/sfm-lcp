import 'package:flutter/material.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/theme/tokens.dart';
import '../widgets/ledger_widgets.dart';

/// The header shared by the three tab screens: icon + title on the left,
/// sync badge and participant code on the right (brief section 6.2).
class TabAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TabAppBar({
    super.key,
    required this.title,
    required this.icon,
    required this.participantCode,
  });

  final String title;
  final IconData icon;
  final String participantCode;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<TabAppBar> createState() => _TabAppBarState();
}

class _TabAppBarState extends State<TabAppBar> {
  Stream<SyncView>? _sync;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync ??= PortsScope.of(context).sync.watch();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: AppSpace.gutter,
      title: Row(
        children: [
          Icon(widget.icon, size: AppSizes.iconLarge),
          const SizedBox(width: AppSpace.sm),
          Flexible(child: Text(widget.title)),
        ],
      ),
      actions: [
        StreamBuilder<SyncView>(
          stream: _sync,
          builder: (context, snap) {
            final sync = snap.data ?? const SyncView(waiting: 0);
            void open() => showSyncSheet(
              context,
              participantCode: widget.participantCode,
              sync: sync,
              onWithdraw: PortsScope.of(context).session.withdraw,
            );
            // Shrinks rather than overflows with a long code on a small
            // phone at large text sizes.
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.55,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SyncBadge(sync: sync, onTap: open),
                    _CodePill(code: widget.participantCode, onTap: open),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpace.sm),
      ],
    );
  }
}

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Participant $code',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
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
                  const Icon(
                    Icons.person_outline,
                    size: AppSizes.iconSmall,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(code, style: AppText.label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header of a screen below a tab: back arrow, optional icon, title,
/// optional actions on the right.
AppBar detailAppBar(
  String title, {
  IconData? icon,
  Color? iconColor,
  List<Widget>? actions,
}) {
  return AppBar(
    toolbarHeight: 64,
    actions: actions,
    title: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor, size: AppSizes.iconLarge),
          const SizedBox(width: AppSpace.sm),
        ],
        Flexible(child: Text(title)),
      ],
    ),
  );
}
