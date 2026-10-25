import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/ports_scope.dart';
import '../../app/view_data.dart';
import '../../core/theme/tokens.dart';
import '../widgets/building_blocks.dart';
import '../widgets/choices.dart';

enum _Step { consent, notNow, code, businessType }

/// First launch: consent → participant code → type of business (FR11 and the
/// ethics procedure). Nothing but the consent time is saved until the last
/// step, so going back to correct the code is always possible.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.consented,
    required this.onDone,
    this.existingCode,
  });

  /// Consent was given on an earlier launch; start at the code.
  final bool consented;
  final ValueChanged<String> onDone;

  /// A participant saved by a build that had no consent screen: ask for
  /// consent only, then finish.
  final String? existingCode;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late _Step _step = widget.consented ? _Step.code : _Step.consent;
  String _code = '';
  BusinessType? _type;
  bool _saving = false;

  Future<void> _agree() async {
    await PortsScope.of(context).session.recordConsent();
    final existing = widget.existingCode;
    if (existing != null) {
      widget.onDone(existing);
      return;
    }
    setState(() => _step = _Step.code);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await PortsScope.of(context).session.start(_code, _type!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save. Check the code and try again.'),
        ),
      );
      return;
    }
    widget.onDone(_code);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.consent => _ConsentStep(
        onAgree: _agree,
        onNotNow: () => setState(() => _step = _Step.notNow),
      ),
      _Step.notNow => _NotNowStep(
        onReady: () => setState(() => _step = _Step.consent),
      ),
      _Step.code => _CodeStep(
        initial: _code,
        onNext: (code) => setState(() {
          _code = code;
          _step = _Step.businessType;
        }),
      ),
      _Step.businessType => _BusinessTypeStep(
        selected: _type,
        saving: _saving,
        onSelect: (t) => setState(() => _type = t),
        onBack: () => setState(() => _step = _Step.code),
        onStart: _finish,
      ),
    };
  }
}

/// Shared layout: centred icon, title, body, then the actions at the bottom.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.content,
    required this.actions,
    this.onBack,
  });

  final IconData icon;
  final String title;
  final List<Widget> content;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Scaffold(
        appBar: onBack == null
            ? null
            : AppBar(
                leading: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
                ),
              ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpace.gutter),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: AppColors.brandTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 48, color: AppColors.brand),
                          ),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          title,
                          style: AppText.title,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpace.md),
                        ...content,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  0,
                  AppSpace.gutter,
                  AppSpace.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One short line with an icon, for the consent points.
class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ink, size: AppSizes.iconLarge),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}

/// The in-app consent screen. The full plain-language sheet is read to the
/// participant first; this screen confirms the main points and records the time.
class _ConsentStep extends StatelessWidget {
  const _ConsentStep({required this.onAgree, required this.onNotNow});

  final VoidCallback onAgree;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.waving_hand_outlined,
      title: 'Welcome',
      content: const [
        _Point(
          Icons.phone_android_outlined,
          'This app keeps your sales, spending and stock on this phone.',
        ),
        _Point(
          Icons.school_outlined,
          'You are helping a study at ZCAS University.',
        ),
        _Point(
          Icons.cloud_upload_outlined,
          'Your records are sent to the study without your name when you have network.',
        ),
        _Point(Icons.exit_to_app, 'You can stop at any time.'),
      ],
      actions: [
        PrimaryAction(
          key: const Key('consent-agree'),
          label: 'I agree',
          onPressed: onAgree,
        ),
        const SizedBox(height: AppSpace.sm),
        TextButton(
          key: const Key('consent-not-now'),
          onPressed: onNotNow,
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: const Text('Not now'),
        ),
      ],
    );
  }
}

class _NotNowStep extends StatelessWidget {
  const _NotNowStep({required this.onReady});

  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.schedule_outlined,
      title: 'Come back when you are ready',
      content: const [
        Text(
          'Nothing has been saved. You can close the app.',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
      ],
      actions: [
        PrimaryAction(
          key: const Key('consent-ready'),
          label: 'I am ready',
          onPressed: onReady,
        ),
      ],
    );
  }
}

class _CodeStep extends StatefulWidget {
  const _CodeStep({required this.initial, required this.onNext});

  final String initial;
  final ValueChanged<String> onNext;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState extends State<_CodeStep> {
  static final RegExp _valid = RegExp(r'^[A-Z0-9]{4,12}$');
  late final _code = TextEditingController(text: widget.initial);

  bool get _canGo => _valid.hasMatch(_code.text);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _next() {
    if (_canGo) widget.onNext(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.badge_outlined,
      title: 'Participant code',
      content: [
        const Text(
          'Enter the code you were given',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          key: const Key('participant-field'),
          controller: _code,
          autofocus: true,
          textAlign: TextAlign.center,
          style: AppText.code,
          maxLength: 12,
          // A code is not a word: no suggestions, no autocorrect. The
          // visible-password keyboard is what stops Samsung's suggestion bar.
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            _UpperCase(),
            FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
          ],
          decoration: const InputDecoration(hintText: 'Code'),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _next(),
        ),
      ],
      actions: [
        PrimaryAction(
          key: const Key('code-next'),
          label: 'Next',
          icon: Icons.arrow_forward,
          onPressed: _canGo ? _next : null,
        ),
      ],
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

const List<(BusinessType, String, IconData)> _businessTypes = [
  (BusinessType.marketStall, 'Market stall', Icons.storefront_outlined),
  (BusinessType.shop, 'Shop', Icons.store_outlined),
  (BusinessType.service, 'Service', Icons.handyman_outlined),
  (BusinessType.other, 'Other', Icons.more_horiz),
];

class _BusinessTypeStep extends StatelessWidget {
  const _BusinessTypeStep({
    required this.selected,
    required this.saving,
    required this.onSelect,
    required this.onBack,
    required this.onStart,
  });

  final BusinessType? selected;
  final bool saving;
  final ValueChanged<BusinessType> onSelect;
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.storefront_outlined,
      title: 'What kind of business?',
      onBack: onBack,
      content: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          children: [
            for (final (type, label, icon) in _businessTypes)
              SelectChip(
                key: Key('business-${type.dbValue}'),
                label: label,
                icon: icon,
                selected: selected == type,
                onTap: () => onSelect(type),
              ),
          ],
        ),
      ],
      actions: [
        PrimaryAction(
          key: const Key('onboarding-start'),
          label: 'Start',
          icon: Icons.arrow_forward,
          onPressed: selected != null && !saving ? onStart : null,
        ),
      ],
    );
  }
}
