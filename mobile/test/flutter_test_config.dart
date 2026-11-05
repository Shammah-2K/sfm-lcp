import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads Roboto for every test, so the no-overflow checks measure real text
/// rather than the test placeholder font. The font files are committed in
/// test/fonts/ (Apache License 2.0, see test/fonts/NOTICE.md) rather than read
/// from the Flutter SDK's cache, which a fresh CI runner does not have.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Future<ByteData> file(String name) async =>
      ByteData.sublistView(await File('test/fonts/$name').readAsBytes());
  await (FontLoader('Roboto')
        ..addFont(file('roboto-regular.ttf'))
        ..addFont(file('roboto-bold.ttf')))
      .load();
  await testMain();
}
