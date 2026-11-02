import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_ports.dart';
import 'app/ports.dart';
import 'data/database.dart';
import 'domain/isolation_forest_detector.dart';
import 'domain/models.dart';
import 'domain/tfidf_categoriser.dart';
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
        categoriser: await _loadCategoriser(),
        detector: await _loadDetector(),
        syncScheduler: scheduler,
      ),
    ),
  );
  scheduler?.start();
}

/// The bundled model, or no suggestions if it cannot be loaded: the user then
/// picks every category (FR3 falls back to manual), and nothing else breaks.
Future<CategoryPort> _loadCategoriser() async {
  try {
    return await TfidfCategoriser.load(rootBundle);
  } catch (e) {
    debugPrint('Categoriser not loaded: $e');
    return const NoCategoriser();
  }
}

/// The bundled detector, or none: then nothing is flagged (FR4 off).
Future<AnomalyDetector> _loadDetector() async {
  try {
    return await IsolationForestDetector.load(rootBundle);
  } catch (e) {
    debugPrint('Detector not loaded: $e');
    return const NoAnomalyDetector();
  }
}
