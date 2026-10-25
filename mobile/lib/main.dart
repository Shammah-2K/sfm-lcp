import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'preview/preview_ports.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SfmApp(ports: previewPorts()));
}
