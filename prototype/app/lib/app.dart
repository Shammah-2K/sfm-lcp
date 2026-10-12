import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/database.dart';
import 'data/ledger_repository.dart';
import 'data/session.dart';
import 'ml/categoriser.dart';
import 'theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/participant_screen.dart';

class _Services {
  const _Services(this.db, this.categoriser, this.participant);

  final AppDatabase db;
  final Categoriser categoriser;
  final Participant? participant;
}

Future<_Services> _open() async {
  final db = AppDatabase.open();
  final categoriser = Categoriser.load(rootBundle);
  final participant = await Session(db).current();
  return _Services(db, await categoriser, participant);
}

class SfmApp extends StatefulWidget {
  const SfmApp({super.key});

  @override
  State<SfmApp> createState() => _SfmAppState();
}

class _SfmAppState extends State<SfmApp> {
  final Future<_Services> _services = _open();
  Participant? _started;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SFM-LCP',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<_Services>(
        future: _services,
        builder: (context, snapshot) {
          final services = snapshot.data;
          if (services == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final participant = _started ?? services.participant;
          if (participant == null) {
            return ParticipantScreen(
              session: Session(services.db),
              onStarted: (p) => setState(() => _started = p),
            );
          }
          return HomeScreen(
            participantCode: participant.code,
            repository: LedgerRepository(services.db, participant.businessId),
            categoriser: services.categoriser,
          );
        },
      ),
    );
  }
}
