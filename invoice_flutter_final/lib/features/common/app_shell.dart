import 'package:flutter/material.dart';
import 'header.dart';
import 'sidebar.dart';

/// Port of `src/Common Components/Layout.js`.
///
/// MOBILE-FIRST REWRITE: the original React app used a permanent desktop
/// sidebar. This Flutter version deliberately does NOT recreate that -
/// navigation always lives behind the hamburger/drawer (see `AppHeader`'s
/// leading icon), regardless of screen width, so the app reads as a native
/// mobile app rather than a compressed desktop website.
///
/// The floating "Ask AI" button + Chatpanel from the original are commented
/// out in the source (dead code, `aiAvailable` gated) and are intentionally
/// left out here to match current behavior - see Phase 12 in
/// CONVERSION_STATUS.md for Chatpanel.js itself.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      drawer: const Drawer(width: 280, child: AppSidebar()),
      body: SafeArea(child: child),
    );
  }
}
