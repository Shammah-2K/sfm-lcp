// The benchmark build's entrypoint. Not part of the app: build it with
//   flutter build apk --release -t lib/bench/bench_main.dart
// (bench/run_bench.py does this). It replaces the app on the phone, so use the
// test phones only, never a participant's.
//
// It prints its results on purpose: bench/run_bench.py reads them from logcat.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'benchmark.dart';

const int _iterations = int.fromEnvironment(
  'BENCH_ITERATIONS',
  defaultValue: 1000,
);
const int _warmup = int.fromEnvironment('BENCH_WARMUP', defaultValue: 100);

/// Lets start-up work finish before anything is timed.
const Duration _settle = Duration(seconds: 3);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = ValueNotifier<String>('Benchmark starting…');
  runApp(_BenchApp(status));
  await Future<void>.delayed(_settle);
  try {
    final results = await runBenchmark(
      rootBundle,
      warmup: _warmup,
      iterations: _iterations,
    );
    final lines = [for (final r in results) benchLine(r)];
    // print reaches logcat (tag "flutter") in release builds.
    lines.forEach(print);
    print(benchDone);
    status.value = ['Done.', ...lines].join('\n\n');
  } catch (e, s) {
    print('$benchTag error $e\n$s');
    print(benchDone);
    status.value = 'Benchmark failed: $e';
  }
}

class _BenchApp extends StatelessWidget {
  const _BenchApp(this.status);

  final ValueNotifier<String> status;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<String>(
              valueListenable: status,
              builder: (context, text, _) =>
                  SelectableText(text, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ),
      ),
    );
  }
}
