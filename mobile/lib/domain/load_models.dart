import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app/ports.dart';
import 'isolation_forest_detector.dart';
import 'models.dart';
import 'tfidf_categoriser.dart';

/// The bundled categoriser, or no suggestions if it cannot be loaded: the user
/// then picks every category (FR3 falls back to manual), and nothing else breaks.
Future<CategoryPort> loadCategoriser(AssetBundle bundle) async {
  try {
    return await TfidfCategoriser.load(bundle);
  } catch (e) {
    debugPrint('Categoriser not loaded: $e');
    return const NoCategoriser();
  }
}

/// The bundled detector, or none: then nothing is flagged (FR4 off).
Future<AnomalyDetector> loadDetector(AssetBundle bundle) async {
  try {
    return await IsolationForestDetector.load(bundle);
  } catch (e) {
    debugPrint('Detector not loaded: $e');
    return const NoAnomalyDetector();
  }
}
