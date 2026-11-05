import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../app/app.dart';
import '../app/app_ports.dart';
import '../data/database.dart';
import '../domain/load_models.dart';
import 'demo_seed.dart';

/// The demo app: the real app with three weeks of sample records, for showing
/// it. Build and install beside the study app:
///
///   flutter build apk --release -t lib/demo/demo_main.dart -P sfmDemo=true
///
/// It never syncs: no sync scheduler is built here, whatever the build
/// defines, so sample data cannot reach the study server. It keeps its own
/// database file, and with `-P sfmDemo=true` its own Android package, so it
/// shares nothing with the study app. To start again from the sample state,
/// clear the demo app's storage in Android settings.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open(name: 'sfm_lcp_demo');
  final clock = DemoClock();
  final ports = buildAppPorts(
    db,
    categoriser: await loadCategoriser(rootBundle),
    detector: await loadDetector(rootBundle),
    clock: clock.now,
  );
  await seedDemo(ports, clock);
  runApp(SfmApp(ports: ports));
}
