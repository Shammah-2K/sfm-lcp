import 'package:flutter/widgets.dart';

import 'ports.dart';

/// Makes [AppPorts] available to every screen below the app root.
class PortsScope extends InheritedWidget {
  const PortsScope({super.key, required this.ports, required super.child});

  final AppPorts ports;

  static AppPorts of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PortsScope>();
    assert(scope != null, 'No PortsScope above this widget');
    return scope!.ports;
  }

  @override
  bool updateShouldNotify(PortsScope oldWidget) => ports != oldWidget.ports;
}
