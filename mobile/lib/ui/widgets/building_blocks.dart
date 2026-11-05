import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'money.dart';

/// A short sentence-case heading above a group of controls.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.label)),
          ?trailing,
        ],
      ),
    );
  }
}

/// The 112 dp Sale / Expense buttons on Today.
class HeroButton extends StatelessWidget {
  const HeroButton({
    super.key,
    required this.label,
    required this.icon,
    required this.moneyIn,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool moneyIn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: moneyColor(moneyIn: moneyIn),
        foregroundColor: AppColors.onFill,
        minimumSize: const Size.fromHeight(AppSizes.heroButton),
        padding: const EdgeInsets.all(AppSpace.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconHero),
          const SizedBox(height: AppSpace.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.title.copyWith(color: AppColors.onFill),
          ),
        ],
      ),
    );
  }
}

/// The one filled, full-width action at the bottom of a screen.
class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.check,
    this.color = AppColors.brand,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('primary-action'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(60),
        ),
        icon: Icon(icon, size: AppSizes.icon),
        label: Text(label),
      ),
    );
  }
}

/// Replaces the primary action for a moment after a save. Neutral ink:
/// the money colours only ever mean money in or out.
class SavedBanner extends StatelessWidget {
  const SavedBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('saved-banner'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.onFill),
            const SizedBox(width: AppSpace.md),
            Flexible(
              child: Text(
                message,
                style: AppText.label.copyWith(color: AppColors.onFill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Needs your attention": pale yellow, 2 dp ink border and a warning icon.
/// Used only for an unusual entry or low stock.
class AttentionCard extends StatelessWidget {
  const AttentionCard({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.attentionSurface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: AppColors.ink,
          width: AppSizes.attentionBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.ink,
                size: AppSizes.iconLarge,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(title, style: AppText.label)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ...children,
          if (actions != null) ...[
            const SizedBox(height: AppSpace.md),
            actions!,
          ],
        ],
      ),
    );
  }
}

/// − value + with 56 dp buttons, for quantities and stock levels.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.caption,
    this.showSign = false,
    this.decreaseLabel = 'Less',
    this.increaseLabel = 'More',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final String? caption;

  /// Shows `+6` / `−2` for a change rather than a count.
  final bool showSign;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  Widget build(BuildContext context) {
    final text = showSign && value > 0
        ? '+$value'
        : (value < 0 ? '−${value.abs()}' : '$value');
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove,
          label: decreaseLabel,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        Expanded(
          child: Column(
            children: [
              Text(text, style: AppText.amount, textAlign: TextAlign.center),
              if (caption != null)
                Text(
                  caption!,
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        _StepButton(
          icon: Icons.add,
          label: increaseLabel,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
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
      width: 64,
      height: AppSizes.touch,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon, size: AppSizes.iconLarge, semanticLabel: label),
      ),
    );
  }
}

/// Neutral information line: grey text with an icon, no coloured surface.
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: AppColors.inkMuted),
        const SizedBox(width: AppSpace.sm),
        Flexible(child: Text(text, style: AppText.caption)),
      ],
    );
  }
}
