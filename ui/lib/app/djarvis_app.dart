import 'package:flutter/material.dart';

/// Window and task switcher title of the application.
const String appTitle = 'Djarvis';

/// Root widget of the Djarvis interface.
///
/// Holds application-wide configuration only. Core connection, tray
/// integration and screens are added on top of this widget.
class DjarvisApp extends StatelessWidget {
  /// Creates the root widget.
  const DjarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      home: Scaffold(),
    );
  }
}
