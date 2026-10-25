import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's real font for every test, so the no-overflow checks measure
/// Atkinson Hyperlegible, which is wider than the test framework's default.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Future<ByteData> file(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  await (FontLoader('AtkinsonHyperlegible')
        ..addFont(file('assets/fonts/AtkinsonHyperlegible-Regular.ttf'))
        ..addFont(file('assets/fonts/AtkinsonHyperlegible-Bold.ttf')))
      .load();
  await testMain();
}
