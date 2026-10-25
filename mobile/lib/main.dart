import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_ports.dart';
import 'data/database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The SIL Open Font License travels with the font (assets/fonts/OFL.txt).
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Atkinson Hyperlegible',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  runApp(SfmApp(ports: buildAppPorts(AppDatabase.open())));
}
