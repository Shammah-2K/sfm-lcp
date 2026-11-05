// Renders S08, the "Is this right?" check, on the demo seed's data: the K250
// taxi where transport is usually about K25. Same size, theme and fonts as
// render_screens_test.dart, but on the real ports and bundled models, seeded
// by lib/demo/demo_seed.dart into an in-memory database.
//
//   flutter test --update-goldens tool/screens/render_unusual_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/data/database.dart';
import 'package:sfm_lcp/demo/demo_seed.dart';
import 'package:sfm_lcp/domain/isolation_forest_detector.dart';
import 'package:sfm_lcp/domain/tfidf_categoriser.dart';

const String _out = '../../../docs/screens';

/// A fixed "now", so the image does not change from day to day.
final DateTime _today = DateTime(2026, 11, 10, 14);

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set');
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> file(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());

  final roboto = FontLoader('Roboto')
    ..addFont(file('roboto-regular.ttf'))
    ..addFont(file('roboto-medium.ttf'))
    ..addFont(file('roboto-bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(file('materialicons-regular.otf'));
  await Future.wait([roboto.load(), icons.load()]);
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late AppPorts ports;

  // Seeded outside the widget test's fake clock, as test/demo does.
  setUpAll(() async {
    await _loadFonts();
    db = AppDatabase(NativeDatabase.memory());
    final clock = DemoClock();
    ports = buildAppPorts(
      db,
      categoriser: TfidfCategoriser.fromJson(_json(categoriserAsset)),
      detector: IsolationForestDetector.fromJson(_json(detectorAsset)),
      clock: () => clock.at ?? _today,
    );
    await seedDemo(ports, clock, today: _today);
  });

  tearDownAll(() => db.close());

  testWidgets('S08 today with the "Is this right?" check (demo seed)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 1500 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(SfmApp(ports: ports));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Durations.short1));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('taxi with stock', skipOffstage: false), findsWidgets);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$_out/s08_unusual.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
