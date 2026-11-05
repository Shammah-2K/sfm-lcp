# Test fonts

`roboto-regular.ttf` and `roboto-bold.ttf` are Roboto by Google, licensed under the Apache
License, Version 2.0 (https://www.apache.org/licenses/LICENSE-2.0). They are copied unchanged
from the Flutter SDK's `bin/cache/artifacts/material_fonts/` and are used only by the tests
(`test/flutter_test_config.dart`), so that text in widget tests has real glyph widths. They are
not bundled in the app, which uses the phone's system Roboto.
