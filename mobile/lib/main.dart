import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_ports.dart';
import 'data/database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SfmApp(ports: buildAppPorts(AppDatabase.open())));
}
