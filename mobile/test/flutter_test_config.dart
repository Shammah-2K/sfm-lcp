import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads Roboto (shipped with the Flutter SDK) for every test, so the
/// no-overflow checks measure real text rather than the test placeholder font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final dir = '$root/bin/cache/artifacts/material_fonts';
    Future<ByteData> file(String name) async =>
        ByteData.sublistView(await File('$dir/$name').readAsBytes());
    await (FontLoader('Roboto')
          ..addFont(file('roboto-regular.ttf'))
          ..addFont(file('roboto-bold.ttf')))
        .load();
  }
  await testMain();
}
