# DECISIONS.md

Choices made during the build that `BUILD_PROTOTYPE.md` does not specify, one per line.

- Android application id `zm.ac.zcas.sfm_lcp_prototype`; launcher label "SFM-LCP"; Android is the only platform generated.
- `prototype/app/.gitignore` re-includes `pubspec.lock`, because the repository root ignores `*.lock` and an application must pin its dependency versions.
- Analyzer runs with `strict-casts` and `strict-raw-types` on top of `flutter_lints`.
