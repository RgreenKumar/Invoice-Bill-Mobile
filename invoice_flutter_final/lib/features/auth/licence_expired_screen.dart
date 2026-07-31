import 'package:flutter/material.dart';

/// Port of `src/AuthenticationPages/LicenceExpired.js`.
///
/// IMPORTANT: the entire original source file is commented out - it has
/// **no active default export**. `App.js` still does
/// `import LicenceExpired from "./AuthenticationPages/LicenceExpired.js"`
/// and renders `<Route path="/LicenceExpired" element={<LicenceExpired/>} />`,
/// which in the live React app renders nothing/`undefined` (broken route).
///
/// Rather than inventing new UI for a component the source doesn't
/// actually define, this shows a minimal blank scaffold that matches the
/// original's *actual* (broken/empty) behavior. If the intent is to
/// restore the commented-out "License Expired" UI, uncomment it in the
/// React source first and this file will be updated to match.
class LicenceExpiredScreen extends StatelessWidget {
  const LicenceExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
