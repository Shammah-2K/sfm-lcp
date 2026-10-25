import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/ports_scope.dart';
import '../../core/theme/tokens.dart';
import '../widgets/building_blocks.dart';

/// S01 — first launch only: the participant enters their study code (FR11).
class ParticipantScreen extends StatefulWidget {
  const ParticipantScreen({super.key, required this.onStarted});

  final ValueChanged<String> onStarted;

  @override
  State<ParticipantScreen> createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen> {
  static final RegExp _valid = RegExp(r'^[A-Z0-9]{4,12}$');
  final _code = TextEditingController();
  bool _starting = false;

  bool get _canStart => !_starting && _valid.hasMatch(_code.text);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_canStart) return;
    setState(() => _starting = true);
    final code = _code.text;
    await PortsScope.of(context).session.start(code);
    widget.onStarted(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    child: const Icon(
                      Icons.badge_outlined,
                      size: 48,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                const Text(
                  'Participant code',
                  style: AppText.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpace.xs),
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
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    _UpperCase(),
                    FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                  ],
                  decoration: const InputDecoration(hintText: 'Code'),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _start(),
                ),
                const SizedBox(height: AppSpace.md),
                PrimaryAction(
                  label: 'Start',
                  icon: Icons.arrow_forward,
                  onPressed: _canStart ? _start : null,
                ),
              ],
            ),
          ),
        ),
      ),
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
