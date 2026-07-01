import 'package:flutter/material.dart';

/// Envuelve el contenido de [Scaffold.bottomNavigationBar] para que no quede
/// debajo de la **navigation bar del sistema** (Android / iOS).
class SafeScaffoldBottomBar extends StatelessWidget {
  const SafeScaffoldBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      maintainBottomViewPadding: true,
      minimum: EdgeInsets.zero,
      child: child,
    );
  }
}
