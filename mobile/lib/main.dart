import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_ports.dart';
import 'data/database.dart';
import 'domain/load_models.dart';
import 'sync/supabase_sync_api.dart';
import 'sync/sync_scheduler.dart';
import 'sync/sync_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  // Built with --dart-define-from-file=supabase.json: sync to the study
  // server. Built without it: everything stays on the phone.
  final config = SyncConfig.fromEnvironment();
  final scheduler = config == null
      ? null
      : SyncScheduler(db, SyncWorker(db, SupabaseSyncApi(config)));
  runApp(
    SfmApp(
      ports: buildAppPorts(
        db,
        categoriser: await loadCategoriser(rootBundle),
        detector: await loadDetector(rootBundle),
        syncScheduler: scheduler,
      ),
    ),
  );
  scheduler?.start();
}
