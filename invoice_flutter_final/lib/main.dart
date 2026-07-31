import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/error_boundary.dart';
import 'core/routing/app_router.dart';
import 'core/state/global_state_provider.dart';
import 'theme/app_theme.dart';

/// Mirrors `src/index.js`:
///
///   root.render(
///     <GlobalStateProvider>
///       <App />
///     </GlobalStateProvider>
///   );
///
/// The React app's global `window.onerror` / `unhandledrejection` handlers
/// (which popped a SweetAlert2 "Some Error Occurred" dialog with a
/// "Send Mail" button hitting `GET /log/time/10`) are not ported 1:1 here -
/// Flutter's error surfaces (FlutterError.onError / PlatformDispatcher
/// .instance.onError) are the natural place to reattach that same
/// behavior if/when it's needed; left as a TODO to avoid guessing at exact
/// dialog copy/behavior beyond what's in this file.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorBoundary();

  // Route guards read a synchronous snapshot of auth state (see
  // core/routing/app_router.dart) - load it before first frame, mirroring
  // how PrivateRoute.js read sessionStorage synchronously on each render.
  await AuthSnapshot.refresh();

  runApp(const InvoiceBillApp());
}

class InvoiceBillApp extends StatelessWidget {
  const InvoiceBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GlobalStateProvider()..init(),
      child: MaterialApp.router(
        title: 'InvoiceBill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
        // NOTE: Footer.js (a desktop trailing bar shown under every page
        // in the source app) is intentionally NOT reproduced here - it
        // was explicitly removed as an unused/desktop-only component.
        // `features/common/footer.dart` was deleted along with this.
      ),
    );
  }
}

/// Call this after a successful login/logout anywhere in the app so route
/// guards see fresh auth state on the very next navigation, e.g.:
///
///   await SessionManager.instance.setAuth(...);
///   await refreshAuthAndNavigate(context, '/dashboard/viewitem');
Future<void> refreshAuthAndNavigate(BuildContext context, String location) async {
  await AuthSnapshot.refresh();
  if (context.mounted) {
    // ignore: use_build_context_synchronously
    GoRouterHelper(context).go(location);
  }
}
