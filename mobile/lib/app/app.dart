import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../ui/screens/app_shell.dart';
import '../ui/screens/participant_screen.dart';
import 'ports.dart';
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

/// First launch shows the participant code screen; later launches go straight
/// to Today.
class _Start extends StatefulWidget {
  const _Start();

  @override
  State<_Start> createState() => _StartState();
}

class _StartState extends State<_Start> {
  Future<String?>? _current;
  String? _started;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _current ??= PortsScope.of(context).session.currentParticipant();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _current,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final code = _started ?? snap.data;
        if (code == null) {
          return ParticipantScreen(
            onStarted: (c) => setState(() => _started = c),
          );
        }
        return AppShell(participantCode: code);
      },
    );
  }
}
