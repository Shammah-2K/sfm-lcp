import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../ui/screens/app_shell.dart';
import '../ui/screens/onboarding_flow.dart';
import 'ports.dart';
import 'view_data.dart';
import 'ports_scope.dart';

class SfmApp extends StatelessWidget {
  const SfmApp({super.key, required this.ports});

  final AppPorts ports;

  @override
  Widget build(BuildContext context) {
    return PortsScope(
      ports: ports,
      child: MaterialApp(
        title: 'SFM-LCP',
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: const _Start(),
      ),
    );
  }
}

/// First launch runs onboarding; later launches go straight to Today.
class _Start extends StatefulWidget {
  const _Start();

  @override
  State<_Start> createState() => _StartState();
}

class _StartState extends State<_Start> {
  Future<OnboardingState>? _state;
  String? _finished;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state ??= PortsScope.of(context).session.state();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OnboardingState>(
      future: _state,
      builder: (context, snap) {
        final state = snap.data;
        if (state == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final code =
            _finished ?? (state.complete ? state.participantCode : null);
        if (code == null) {
          return OnboardingFlow(
            consented: state.consented,
            existingCode: state.participantCode,
            onDone: (c) => setState(() => _finished = c),
          );
        }
        return AppShell(participantCode: code);
      },
    );
  }
}
