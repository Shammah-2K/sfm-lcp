import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/session.dart';
import '../../theme.dart';

/// First launch only: the participant enters their study code (FR11).
class ParticipantScreen extends StatefulWidget {
  const ParticipantScreen({
    super.key,
    required this.session,
    required this.onStarted,
  });

  final Session session;
  final ValueChanged<Participant> onStarted;

  @override
  State<ParticipantScreen> createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen> {
  final _code = TextEditingController();
  bool _starting = false;

  bool get _valid => participantCodePattern.hasMatch(_code.text);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_valid || _starting) return;
    setState(() => _starting = true);
    final participant = await widget.session.start(_code.text);
    widget.onStarted(participant);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: AppSizes.bigIcon * 2,
                  color: AppColors.income,
                ),
                const SizedBox(height: AppSizes.gutter),
                Text(
                  'Participant code',
                  style: AppText.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.gutter),
                TextField(
                  key: const Key('participant-field'),
                  controller: _code,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: AppText.code,
                  maxLength: 12,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    _UpperCaseCode(),
                    FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _start(),
                ),
                const SizedBox(height: AppSizes.gap),
                FilledButton.icon(
                  key: const Key('start'),
                  onPressed: _valid && !_starting ? _start : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: AppColors.onIncome,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: AppSizes.icon),
                  label: const Text('Start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseCode extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
