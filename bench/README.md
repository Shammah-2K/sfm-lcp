# On-device benchmark (NFR1, NFR2)

Measures the two bundled models on a real phone in a **release build**: how long each takes to
load, how long one prediction takes (p50, p95, max over 1000 calls), the model file size and the
memory loading it costs. One CSV row per model per run goes into `results.csv`. The CSV is the
record and gets committed. The table and figures are regenerated from it.

Nothing in this folder estimates a number. A value either came from a run on a phone or the
cell is empty.

```
run_bench.py         PC side: build, install, start the bench app, collect its lines, append to results.csv
plot_bench.py        results.csv -> docs/bench/summary.md, latency.png, load.png
make_bench_texts.py  copies the categoriser's 300 held-out parity descriptions into the bench build
tests/               pytest checks for the runner's parsing and CSV rules
mobile/lib/bench/    phone side: benchmark.dart (what is measured) and bench_main.dart (the entrypoint)
```

## Running it

On each test phone (the 2–4 GB ones, not the Galaxy S24+):

1. Enable USB debugging and connect it. `adb devices` should list it once.
2. Keep the screen unlocked and on, close other apps, and note the conditions (charging or not,
   battery saver). Thermal state affects timings.
3. From the repository root:

   ```
   ml/.venv/Scripts/python bench/run_bench.py --note "on battery, saver off"
   ```

   This builds `lib/bench/bench_main.dart` in release mode, installs it, and starts it 3 times
   (`--runs`). Each start is a new process, so every load is a cold load. It prints each run and
   appends the rows. Use `--serial` when two phones are attached, and `--skip-build` to rerun
   without rebuilding.
4. The bench build **replaces the app** on the phone (same package). Afterwards reinstall the real
   app with `flutter install --release` in `mobile/`. Never run this on a participant's phone.

Then, with matplotlib installed (`pip install -r bench/requirements.txt`):

```
ml/.venv/Scripts/python bench/plot_bench.py
```

## What each column means

| Column | Measured how |
|---|---|
| `load_ms` | Wall time of `TfidfCategoriser.load` / `IsolationForestDetector.load`: asset read plus JSON parse, as at app start |
| `p50_us`, `p95_us`, `max_us`, `mean_us` | `n` timed calls after `warmup` untimed ones, through the same public call the app makes (`suggest`, `score`). Nearest-rank percentiles, so every value was observed |
| `first_call_us` | The first prediction straight after loading |
| `inputs` | Categoriser: the 300 held-out descriptions it cycles through. Detector: history entries passed with each call (a fixed synthetic trader over the 60-day window) |
| `model_bytes` | Size of the bundled model file |
| `rss_before_load_mb`, `rss_after_load_mb` | Dart's `ProcessInfo.currentRss` for the whole app just before and after loading. Garbage collection makes the difference noisy, so use it as an indication only |
| `app_pss_mb` | `dumpsys meminfo` TOTAL PSS of the app after the run, both models loaded. This is Android's own accounting and the better memory figure |
| `device_*`, `soc`, `android_api`, `ram_total_mb` | From `getprop` and `/proc/meminfo` over adb |
| `git_sha`, `git_dirty` | The commit measured. `git_dirty=1` means `mobile/` had uncommitted changes |

## What it does not measure

- **The database query** that fetches the detector's history before scoring. The figure is
  model time only.
- **APK size.** Measure that on the real app:
  `flutter build apk --release --analyze-size --target-platform android-arm64` in `mobile/`.
- **Battery.** Not measured.
- **App cold start.** Not measured here. `adb shell am start -W` on the real app gives
  `TotalTime` if Chapter 4 needs it.

Compare the results against Chapter 3's NFR1 and NFR2 thresholds in the write-up. The harness
deliberately does not encode them.

After retraining the categoriser, run `python bench/make_bench_texts.py` so the bench uses the
new held-out descriptions. Results from different model versions stay apart: `plot_bench.py`
reports the newest version of each model unless you pass `--version`.
