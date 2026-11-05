import 'package:flutter/foundation.dart';

import 'view_data.dart';

/// Researcher mode (decision D8). Traders see a suggestion only as
/// "Suggested on this phone"; with researcher mode on, the line below it also
/// gives the model's confidence, how long the prediction took and the model
/// version, for observation sessions and demonstrations.
///
/// Turned on and off by long-pressing the participant code in the header. It
/// is never saved: every app start begins with it off, so a phone handed back
/// to a trader cannot be left showing percentages.
final ValueNotifier<bool> researcherMode = ValueNotifier<bool>(false);

/// The researcher's line under a suggestion: "87% sure · 0.41 ms · lr-v2".
String researcherCaption(Suggestion s) {
  final percent = (s.top.first.confidence * 100).round();
  final micros = s.elapsedMicros;
  return [
    '$percent% sure',
    if (micros != null) '${(micros / 1000).toStringAsFixed(2)} ms',
    s.modelVersion,
  ].join(' · ');
}
